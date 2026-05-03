import os

from flask import Flask, jsonify

app = Flask(__name__)


@app.after_request
def add_headers(response):
    response.headers["X-DevOps-Project"] = "course-ci-container"
    response.headers["X-Content-Type-Options"] = "nosniff"
    return response


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    host = os.getenv("APP_HOST", "0.0.0.0")
    port = int(os.getenv("APP_PORT", "8080"))
    app.run(host=host, port=port)
