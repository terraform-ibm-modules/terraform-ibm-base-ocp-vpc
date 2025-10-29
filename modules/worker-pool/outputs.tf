output "workerpools" {
  description = "Worker pools created"
  value       = data.ibm_container_vpc_worker_pool.all_pools
}
