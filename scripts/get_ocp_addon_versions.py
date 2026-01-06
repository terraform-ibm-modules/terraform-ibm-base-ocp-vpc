#!/usr/bin/env python3
import http.client
import json
import os
import sys
from urllib.parse import urlparse


def parse_input():
    """
    Reads JSON input from stdin and parses it into a dictionary.
    Returns:
        dict: Parsed input data.
    """
    try:
        data = json.loads(sys.stdin.read())
    except json.JSONDecodeError as e:
        raise ValueError("Invalid JSON input") from e
    return data


def validate_inputs(data):
    """
    Validates required inputs 'IAM_TOKEN' and 'REGION' from the parsed input.
    Args:
        data (dict): Input data parsed from JSON.
    Returns:
        tuple: A tuple containing (IAM_TOKEN, REGION).
    """
    token = data.get("IAM_TOKEN")
    if not token:
        raise ValueError("IAM_TOKEN is required")

    region = data.get("REGION")
    if not region:
        raise ValueError("REGION is required")

    return token, region


def get_env_variable():
    """
    Retrieves the value of an environment variable.
    Returns:
        str: The value of the environment variable.
    """
    api_endpoint = os.getenv("IBMCLOUD_CS_API_ENDPOINT")
    if not api_endpoint:
        api_endpoint = "https://containers.test.cloud.ibm.com/global"
    return api_endpoint


def fetch_addon_versions(iam_token, region, api_endpoint):
    """
    Fetches openshift add-on versions using HTTP connection.
    Args:
        iam_token (str): IBM Cloud IAM token for authentication.
        region (str): Region to query for add-ons.
        api_endpoint (str): Base API endpoint URL.
    Returns:
        list: Parsed JSON response containing add-on information.
    """
    # Add https if user passed just a hostname
    if not api_endpoint.startswith("https://"):
        api_endpoint = f"https://{api_endpoint}"

    parsed = urlparse(api_endpoint)

    # Default path to /global if none supplied
    base_path = parsed.path.rstrip("/") if parsed.path else "/global"

    host = parsed.hostname
    headers = {
        "Authorization": f"Bearer {iam_token}",
        "Accept": "application/json",
        "X-Region": region,
    }

    conn = http.client.HTTPSConnection(host)
    try:
        # Final API path
        url = f"{base_path}/v1/addons"
        conn.request("GET", url, headers=headers)
        response = conn.getresponse()
        data = response.read().decode()

        if response.status != 200:
            raise RuntimeError(
                f"API request failed: {response.status} {response.reason} - {data}"
            )

        return json.loads(data)
    except http.client.HTTPException as e:
        raise RuntimeError("HTTP request failed") from e
    finally:
        conn.close()


def transform_cluster_addons_data(addons_data):
    """
    Transforms cluster add-on raw data into a nested dictionary structured by add-on name and version.
    Args:
        addons_data: Raw data returned by the add-on API.
    Returns:
        dict: Transformed add-on data suitable for Terraform consumption.
    """
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
        raise RuntimeError("No add-on data found.")

    return result


def format_for_terraform(result):
    """
    Converts the transformed add-on data into JSON strings for Terraform external data source consumption.
    Args:
        result (dict): Transformed add-on data.
    Returns:
        dict: A dictionary mapping add-on names to JSON strings of their version info.
    """
    return {name: json.dumps(versions) for name, versions in result.items()}


def main():
    """
    Main execution function: reads input, validates, fetches API data, transforms it,
    formats it for Terraform and prints the JSON output.
    """
    data = parse_input()
    iam_token, region = validate_inputs(data)
    api_endpoint = get_env_variable()
    addons_data = fetch_addon_versions(iam_token, region, api_endpoint)
    transformed = transform_cluster_addons_data(addons_data)
    output = format_for_terraform(transformed)

    print(json.dumps(output))


if __name__ == "__main__":
    main()
