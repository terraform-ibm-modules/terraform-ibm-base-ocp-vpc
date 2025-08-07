# Cluster Size Configuration

This document describes the cluster size options and their configuration details. This table determines the number of availability zones, worker nodes per zone, and the machine type used for the OpenShift cluster.

## Cluster Table

| T-Shirt Size | Number of Worker Nodes per zone | Total Number of Worker Nodes | Zones | vCPU per Node | Memory per Node (GB) | Disk per Node (GB) | Worker Node Flavor Name | HA Level            | Notes                                                  |
|--------------|------------------------|------------------------------|--------|----------------|------------------------|----------------------|--------------------------|---------------------|--------------------------------------------------------|
| Mini         | 1                      | 2                            | 2      | 4              | 16                     | 100                  | bx2.4x16                 | Moderate (Basic)    | Smallest possible; basic HA across 2 zones             |
| Small        | 1                      | 3                            | 3      | 8              | 32                     | 200                  | bx2.8x32                 | High                | Entry-level production HA                              |
| Medium       | 2                      | 6                            | 3      | 8              | 32                     | 200                  | bx2.8x32                 | High                | Moderate workloads, better HA                          |
| Large        | 3                      | 9                            | 3      | 16             | 64                     | 400                  | bx2.16x64                | High                | Large-scale, robust HA                                 |
