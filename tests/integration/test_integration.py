import requests
import pytest
import os

BASE_URL = os.getenv("APP_URL", "http://localhost:8080")

def test_app_is_running():
    response = requests.get(BASE_URL, timeout=10)
    assert response.status_code == 200

def test_hello_response():
    response = requests.get(f"{BASE_URL}/", timeout=10)
    assert response.status_code == 200
    assert "hello" in response.text.lower()

def test_response_time():
    import time
    start = time.time()
    requests.get(BASE_URL, timeout=10)
    elapsed = time.time() - start
    assert elapsed < 5  # Response under 5 seconds