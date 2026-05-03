"""Integration tests that verify required HTTP headers."""

import os

import requests


def run_header_check():
    app_host = os.getenv("APP_HOST", "app")
    app_port = os.getenv("APP_PORT", "8080")
    response = requests.get(f"http://{app_host}:{app_port}/health", timeout=5)

    assert response.status_code == 200
    assert response.headers["X-DevOps-Project"] == "course-ci-container"
    assert response.headers["X-Content-Type-Options"] == "nosniff"


if __name__ == "__main__":
    run_header_check()
