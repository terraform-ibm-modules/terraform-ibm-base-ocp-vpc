#!/usr/bin/env python3
import json
import sys
import urllib.error
import urllib.request


################################
# Read input from stdin
################################
def parse_input():
    try:
        data = json.loads(sys.stdin.read())
    except json.JSONDecodeError:
        error("Invalid JSON input")
    return data


################################
# Validate input values
################################
def validate_inputs(data):
    token = data.get("IAM_TOKEN")
    if not token:
        error("IAM_TOKEN is required")

    region = data.get("region")
    if not region:
        error("region is required")
    return token, region


################################
# API Call for add-on versions
################################
def fetch_addon_versions(iam_token, region):
    url = "https://containers.cloud.ibm.com/global/v1/addons"
    headers = {
        "Authorization": f"Bearer {iam_token}",
        "Accept": "application/json",
        "X-Region": region,
    }

    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as resp:
            return json.load(resp)
    except urllib.error.URLError as e:
        error(f"Failed to fetch add-on versions: {e}")


################################
# Data transformation
################################
def transform_addons(addons_data):
    result = {}

    for addon in addons_data:
        name = addon.get("name")
        version = addon.get("version")

        supported_ocp = addon.get("supportedOCPRange", "unsupported")
        supported_kube = addon.get("supportedKubeRange", "unsupported")

        if name not in result:
            result[name] = {}

        result[name][version] = {
            "supported_openshift_range": supported_ocp,
            "supported_kubernetes_range": supported_kube,
        }

    if not result:
        error("No add-on data found.")

    return result


def format_for_terraform(result):
    return {name: json.dumps(versions) for name, versions in result.items()}


################################
# Failure handling
################################
def error(msg):
    print(f"Error: {msg}", file=sys.stderr)
    sys.exit(1)


################################
# Main function
################################
def main():
    data = parse_input()
    iam_token, region = validate_inputs(data)

    addons_data = fetch_addon_versions(iam_token, region)
    transformed = transform_addons(addons_data)
    output = format_for_terraform(transformed)

    print(json.dumps(output))


if __name__ == "__main__":
    main()
