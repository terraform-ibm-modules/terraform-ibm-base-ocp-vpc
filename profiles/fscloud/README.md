# Financial Services Cloud Profile
## Note: OCP is not Financial Services Cloud Compliant
:exclamation: **Important:** Currently, OCP provisions a COS bucket, but you cannot use your own encryption keys. This will fail the requirement for Cloud Object Storage to be enabled with customer-managed encryption and Keep Your Own Key (KYOK).
Once the service supports this the profile will be updated. Until that time it is for educational purposes only.

This is a profile for IBM Cloud Red Hat OpenShift cluster on VPC Gen2 that meets FS Cloud requirements. This profile assumes you are deploying into an already compliant account.
It has been scanned by [IBM Code Risk Analyzer (CRA)](https://cloud.ibm.com/docs/code-risk-analyzer-cli-plugin?topic=code-risk-analyzer-cli-plugin-cra-cli-plugin#terraform-command) and meets all applicable goals with the following exceptions:

- rule-8cbd597c-7471-42bd-9c88-36b2696456e9 - Check whether Cloud Object Storage network access is restricted to a specific IP range
    - This is ignored because the CBR locks this down and CRA does not check this

## Note: If no Context Based Restriction(CBR) rules are passed, you must configure Context Based Restrictions externally to be compliant.
