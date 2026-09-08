import os
import time

import redis
from flask import Flask

app = Flask(__name__)

# The Redis hostname comes from an environment variable so the same code works
# locally (localhost) and inside Compose (service name "redis"). Default: "redis".
cache = redis.Redis(host=os.environ.get("REDIS_HOST", "redis"), port=6379)


def get_hit_count():
    """Increment and return the page-view counter, retrying if Redis is still starting."""
    retries = 5
    while True:
        try:
            return cache.incr("hits")
        except redis.exceptions.ConnectionError as exc:
            if retries == 0:
                raise exc
            retries -= 1
            time.sleep(0.5)


@app.route("/")
def home():
    count = get_hit_count()
    return f"Hello from Docker! 🐳 This page has been viewed {count} time(s).\n"


if __name__ == "__main__":
    # 0.0.0.0 makes the app reachable from outside the container, not just inside it.
    app.run(host="0.0.0.0", port=5000)
