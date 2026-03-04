# How to re-create the default worker pool

If you need to make changes to the default worker pool that require its re-creation, for example changing the worker node `operating_system`, you need to follow 3 steps:

1. You must set the `allow_default_worker_pool_replacement` variable to `true` and perform a terraform apply.
2. Once the first apply is successful, then make the required change to the default worker pool object and perform an apply.
3. After successful apply of the default worker pool change `allow_default_worker_pool_replacement` back to `false` and perform an apply.

This is **only** necessary for changes that require the recreation the entire default pool and is **not needed for scenarios that does not require recreating the worker pool such as changing the number of workers in the default worker pool**.

This approach is due to a limitation in the Terraform provider that may be lifted in the future.
