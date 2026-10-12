"""Kafka smoke test, part 2: read the test messages and print them.

All settings come from environment variables (see ../README.md). Waits for the
topic if it doesn't exist yet. Stops on Ctrl+C / docker stop, or after
IDLE_TIMEOUT_SEC seconds without a message (0 = run until stopped).
"""
import os
import signal
import socket
import sys
import time

import certifi
from confluent_kafka import Consumer, KafkaError, KafkaException


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
        "client.id": f"kafka-test-consumer-{socket.gethostname()}",
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


def wait_for_topic(consumer, topic, is_stopping):
    first = True
    while not is_stopping():
        try:
            metadata = consumer.list_topics(topic, timeout=15)
        except KafkaException as e:
            sys.exit(f"ERROR: cannot reach Kafka ({e}). Check KAFKA_BOOTSTRAP, the port and the login.")
        if first:
            print(f"Connected: {len(metadata.brokers)} broker(s), cluster {metadata.cluster_id}")
            first = False
        info = metadata.topics.get(topic)
        if info is not None and info.error is None:
            print(f"Topic '{topic}' has {len(info.partitions)} partition(s)")
            return
        print(f"Waiting for topic '{topic}' (run the producer first)...")
        time.sleep(5)


def main():
    topic = env("KAFKA_TOPIC", "test-topic")
    idle_timeout = float(env("IDLE_TIMEOUT_SEC", "0"))
    consumer = Consumer({
        **kafka_config(),
        "group.id": env("GROUP_ID", "kafka-test"),
        "auto.offset.reset": "earliest",   # a new group starts from the first message
    })

    stopping = False

    def stop(*_):
        nonlocal stopping
        stopping = True

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    wait_for_topic(consumer, topic, lambda: stopping)
    consumer.subscribe([topic])
    print(f"Consuming '{topic}' as group '{env('GROUP_ID', 'kafka-test')}' (Ctrl+C to stop)")

    received = 0
    last_message = time.monotonic()
    try:
        while not stopping:
            msg = consumer.poll(1.0)
            if msg is None:
                if idle_timeout and time.monotonic() - last_message > idle_timeout:
                    print(f"No message for {idle_timeout:g}s, stopping")
                    break
                continue
            if msg.error():
                if msg.error().code() != KafkaError._PARTITION_EOF:
                    print(f"Kafka error: {msg.error()}", file=sys.stderr)
                continue
            received += 1
            last_message = time.monotonic()
            key = msg.key().decode() if msg.key() else None
            print(f"received key={key} from [partition {msg.partition()}] "
                  f"@ offset {msg.offset()}: {msg.value().decode()}")
    finally:
        consumer.close()   # commits offsets and leaves the group
    print(f"Done: {received} message(s) received")


if __name__ == "__main__":
    main()
