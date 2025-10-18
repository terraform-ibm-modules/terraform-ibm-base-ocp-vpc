moved {
  from = ibm_container_vpc_worker_pool.pool
  to   = module.worker_pools.ibm_container_vpc_worker_pool.pool
}

moved {
  from = ibm_container_vpc_worker_pool.autoscaling_pool
  to   = module.worker_pools.ibm_container_vpc_worker_pool.autoscaling_pool
}
