import requests


def fetch_json(url, headers):
    response = requests.get(url, headers=headers, timeout=5)
    response.raise_for_status()
    return response.json()


def build_auth_header(token):
    return {"Authorization": f"Bearer {token}"}
