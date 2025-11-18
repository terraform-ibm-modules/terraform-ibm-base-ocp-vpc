import http.client
import json

# Target host (no https:// prefix)
host = "httpbin.org"

# POST path
path = "/post"

# JSON payload
payload = {
    "message": "Hello from http.client!"
}

# Convert payload to JSON string
body = json.dumps(payload)

# Set headers
headers = {
    "Content-Type": "application/json",
    "Content-Length": str(len(body))
}

# Create HTTPS connection
conn = http.client.HTTPSConnection(host)

# Send POST request
conn.request("POST", path, body, headers)

# Get response
response = conn.getresponse()
raw_data = response.read().decode()

print("Status:", response.status)
print("Raw Response:", raw_data)

# Try to parse JSON
try:
    parsed = json.loads(raw_data)
    print("\nPretty JSON:")
    print(json.dumps(parsed, indent=4))
except json.JSONDecodeError:
    print("Response was not valid JSON.")
