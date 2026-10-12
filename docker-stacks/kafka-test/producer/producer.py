"""Kafka smoke test, part 1: create the topic (if missing) and send test messages.

All settings come from environment variables (see ../README.md). Exit code 0
means every message was confirmed by the broker.
"""
import json
import os
import signal
import socket
import sys
import time
from datetime import datetime, timezone

import certifi
from confluent_kafka import KafkaError, KafkaException, Producer
from confluent_kafka.admin import AdminClient, NewTopic


def env(name, default=None):
    value = os.environ.get(name, "").strip()
    if value:
        return value
    if default is None:
        sys.exit(f"ERROR: {name} is not set (see README.md)")
    return default


def kafka_config():
    protocol = env("KAFKA_SECURITY_PROTOCOL", "SASL_SSL").upper()
    conf = {
        "bootstrap.servers": env("KAFKA_BOOTSTRAP"),
        "security.protocol": protocol,
        "client.id": f"kafka-test-producer-{socket.gethostname()}",
        "error_cb": lambda err: print(f"Kafka error: {err}", file=sys.stderr),
    }
    if "SSL" in protocol:
        # Trust the public CAs (Let's Encrypt); the broker hostname is verified too.
        conf["ssl.ca.location"] = certifi.where()
    if protocol.startswith("SASL"):
        conf["sasl.mechanism"] = env("KAFKA_SASL_MECHANISM", "SCRAM-SHA-512")
        conf["sasl.username"] = env("KAFKA_USERNAME")
        conf["sasl.password"] = env("KAFKA_PASSWORD")
    return conf


def ensure_topic(admin, topic):
    try:
        metadata = admin.list_topics(timeout=15)
    except KafkaException as e:
        sys.exit(f"ERROR: cannot reach Kafka ({e}). Check KAFKA_BOOTSTRAP, the port and the login.")
    print(f"Connected: {len(metadata.brokers)} broker(s), cluster {metadata.cluster_id}")

    if topic in metadata.topics:
        print(f"Topic '{topic}' already exists")
        return
    new_topic = NewTopic(
        topic,
        num_partitions=int(env("TOPIC_PARTITIONS", "3")),
        replication_factor=int(env("TOPIC_REPLICATION", "1")),
    )
    try:
        admin.create_topics([new_topic])[topic].result(timeout=30)
        print(f"Created topic '{topic}'")
    except KafkaException as e:
        if e.args[0].code() != KafkaError.TOPIC_ALREADY_EXISTS:
            sys.exit(f"ERROR: cannot create topic '{topic}': {e}")
        print(f"Topic '{topic}' already exists")


def main():
    conf = kafka_config()
    topic = env("KAFKA_TOPIC", "test-topic")
    count = int(env("MESSAGE_COUNT", "10"))          # 0 = send until stopped
    interval = float(env("MESSAGE_INTERVAL_SEC", "1"))

    ensure_topic(AdminClient(conf), topic)
    producer = Producer({**conf, "acks": "all"})

    stats = {"ok": 0, "failed": 0}

    def on_delivery(err, msg):
        if err:
            stats["failed"] += 1
            print(f"FAILED  key={msg.key().decode()}: {err}", file=sys.stderr)
        else:
            stats["ok"] += 1
            print(f"delivered key={msg.key().decode()} to {msg.topic()} "
                  f"[partition {msg.partition()}] @ offset {msg.offset()}")

    stopping = False

    def stop(*_):
        nonlocal stopping
        stopping = True

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    sent = 0
    while not stopping and (count == 0 or sent < count):
        sent += 1
        value = {
            "id": sent,
            "sent_at": datetime.now(timezone.utc).isoformat(),
            "host": socket.gethostname(),
            "text": f"hello from kafka-test #{sent}",
        }
        producer.produce(topic, key=str(sent), value=json.dumps(value), on_delivery=on_delivery)
        producer.poll(0)
        if count == 0 or sent < count:
            time.sleep(interval)

    unsent = producer.flush(30)
    print(f"Done: {stats['ok']} delivered, {stats['failed']} failed, {unsent} not confirmed")
    sys.exit(0 if stats["failed"] == 0 and unsent == 0 and stats["ok"] > 0 else 1)


if __name__ == "__main__":
    main()
