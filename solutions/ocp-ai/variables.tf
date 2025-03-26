variable "machine_type" {
  type        = string
  description = "The machine type for worker nodes."
}

variable "workers_per_zone" {
  type        = number
  description = "Number of worker nodes in each zone of the cluster."
}

variable "operating_system" {
  type        = string
  description = "The operating system installed on the worker nodes."
}
