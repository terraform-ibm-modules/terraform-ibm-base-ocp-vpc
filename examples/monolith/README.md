# IBM Cloud OpenShift DA - Monolith Add-ons Module Example

A simple example that shows how to provision a multi zone OCP VPC cluster as well as all foundational infrastructure and supporting services required for a secure and compliant OpenShift (OCP) cluster deployment on IBM Cloud VPC.

The following resources are provisioned by this example:
- A new resource group, if an existing one is not passed in.
- A Key Protect instance with 2 root keys, one for cluster encryption, and one for worker boot volume encryption.
- A VPC with subnets across 3 zones.
- A public gateway for all the three zones.
- A multi-zone (3 zone) KMS encrypted OCP VPC cluster, with worker pools in each zone.
- An additional worker pool named workerpool is created and attached to the cluster using the worker-pool submodule.
- Auto scaling enabled for the default worker pool.
- Taints against the workers in zone-2 and zone-3.
- Enable Kubernetes API server audit logs.
- A Cloud logs instance.
- A Cloud monitoring instance.
- An activity tracker event routing instance.
- A secrets manager instance.
- A COS instance along with 3 buckets for VPC flow logs, metrics/data bucket and activity tracker bucket.
- A SCC-WP instance.
- A VPC instance.
- An event notifications instance.
- An app configuration service with aggregator enabled.
- Monitoring agent.
- A Trusted Profile with Sender role to logs service.
- Logs agent.
