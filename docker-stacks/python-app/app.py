import os
import socket
from pathlib import Path

from flask import Flask, jsonify

DATA_FILE = Path(os.environ.get("DATA_DIR", "/data")) / "visits.txt"

app = Flask(__name__)


@app.get("/")
def index():
    # The counter is stored on the volume, so it survives container re-creation.
    visits = int(DATA_FILE.read_text()) + 1 if DATA_FILE.exists() else 1
    DATA_FILE.write_text(str(visits))
    return jsonify(message="Hello from Python", visits=visits, host=socket.gethostname())


@app.get("/health")
def health():
    return "ok"
