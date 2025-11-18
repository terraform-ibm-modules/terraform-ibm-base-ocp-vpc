import requests
import json

url = "https://httpbin.org/post"   # Example test endpoint
payload = {
    "message": "Hello from Python!"
}

response = requests.post(url, json=payload)

# Print HTTP status code
print("Status:", response.status_code)

# Print JSON response (pretty formatted)
try:
    data = response.json()
    print(json.dumps(data, indent=4))
except ValueError:
    print("Response was not JSON.")
