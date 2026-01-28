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
    Validates required input 'IAM_TOKEN' and optional input 'PLATFORM'
    from the parsed input.

    Args:
        data (dict): Input data parsed from JSON.

    Returns:
        tuple: A tuple containing (IAM_TOKEN, PLATFORM).
    """
    token = data.get("IAM_TOKEN")
    if not token:
        raise ValueError("IAM_TOKEN is required")

    platform = data.get("PLATFORM", "openshift")

    return token, platform


def get_env_variable():
    """
    Retrieves the value of an environment variable.
    Returns:
        str: The value of the environment variable.
    """
    api_endpoint = os.getenv("IBMCLOUD_CS_API_ENDPOINT")
    if not api_endpoint:
        api_endpoint = "https://containers.cloud.ibm.com/global"
    return api_endpoint


def fetch_oc_versions(iam_token, api_endpoint):
    """
    Lists all container platform versions available for IBM Cloud Kubernetes Service clusters via an HTTP connection.
    Args:
        iam_token (str): IBM Cloud IAM token for authentication.
        api_endpoint (str): Base API endpoint URL.
    Returns:
        dict: Parsed JSON response containing information about container platform versions.
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
    }

    conn = http.client.HTTPSConnection(host)
    try:
        # Final API path
        url = f"{base_path}/v1/versions"
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


def format_for_terraform(api_response, platform):
    """
    Converts the API response into JSON strings for Terraform external data source consumption.
    Extracts valid versions and default version for the specified platform only.

    Args:
        api_response (dict): The API response containing components like 'openshift', 'kubernetes'.
        platform (str): The platform to filter on (e.g., 'openshift', 'kubernetes').

    Returns:
        dict: A dictionary containing version information for the specified platform.
    """
    result = {}
    versions = api_response.get(platform)
    if not versions:
        raise ValueError(f"No versions found for platform '{platform}'")

    valid_versions_list = []
    default_version = None

    for v in versions:
        full_version = f"{v['major']}.{v['minor']}.{v['patch']}"
        valid_versions_list.append(full_version)
        if v.get("default", False):
            default_version = full_version

    # Store as JSON string for Terraform
    result[platform] = json.dumps(
        {"valid_versions": valid_versions_list, "default": default_version}
    )

    return result


def main():
    """
    Main execution function: reads input, validates, fetches API data,
    formats it for Terraform and prints the JSON output.
    """
    data = parse_input()
    iam_token, platform = validate_inputs(data)
    api_endpoint = get_env_variable()
    api_response = fetch_oc_versions(iam_token, api_endpoint)
    oc_versions = format_for_terraform(api_response, platform)

    print(json.dumps(oc_versions))


if __name__ == "__main__":
    main()
