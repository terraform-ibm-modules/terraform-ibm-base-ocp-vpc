# IBM Cloud OpenShift Landing Zone with Integrated Services Example

A simple example that shows how to provision a multi zone OCP VPC cluster as well as all foundational infrastructure and supporting services required for a secure and compliant OpenShift (OCP) cluster deployment on IBM Cloud VPC.

The following resources are provisioned by this example:
* A new resource group if an existing resource group is not passed.
* Monitoring agent.
* A Trusted Profile with Sender role to logs service.
* Logs agent.
* All the resources that are provisioned by calling the `containerized_app_landing_zone` module can be referred [here](../../modules/containerized_app_landing_zone/README.md).
