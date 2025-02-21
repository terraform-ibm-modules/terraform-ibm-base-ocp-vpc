# Configuring complex inputs for OCP in IBM Cloud projects
Several optional input variables in the Red Hat OpenShift cluster [deployable architecture](https://cloud.ibm.com/catalog#deployable_architecture) use complex object types. You specify these inputs when you configure your deployable architecture.

- [KMS config](#options-with-kms-config) (`kms_config`)
- [Context Based Restrictions](#options-with-cbr) (`cbr_rules`)


## Options with KMS config <a name="options-with-kms-config"></a>

This variable is used to attach a KMS instance to the cluster. If account_id is not provided, the default account in use will be applied..

### Example for KMS Config

```hcl
  kms_config = {
    instance_id = module.kp_all_inclusive.kms_guid
    crk_id      = module.kp_all_inclusive.keys["${local.key_ring}.${local.cluster_key}"].key_id
    private_endpoint = false                                   # Optional
    account_id       = "defc0df06b644a9cabc6e44f55b3880s"      # Optional, to attach KMS instance from another account
    wait_for_apply   = true                                    # Optional
  }

```


## Options with context-based restriction (cbr) rules <a name="options-with-cbr"></a>

The `cbr_rules` input variable allows you to provide a rule for the target service to enforce access restrictions for the service based on the context of access requests. Contexts are criteria that include the network location of access requests, the endpoint type from where the request is sent, etc.

- Variable name: `cbr_rules`.
- Type: A list of objects. Allows only one object representing a rule for the target service
  - `description` (required): The description of the rule to create.
  - `account_id` (required): The IBM Cloud Account ID
  - `rule_contexts` (required): (List) The contexts the rule applies to
      - `attributes` (optional): (List) Individual context attributes
        - `name` (required): The attribute name.
        - `value`(required): The attribute value.

  - `enforcement_mode` (required): The rule enforcement mode can have the following values:
      - `enabled` - The restrictions are enforced and reported. This is the default.
      - `disabled` - The restrictions are disabled. Nothing is enforced or reported.
      - `report` - The restrictions are evaluated and reported, but not enforced.
  - `operations` (optional): The operations this rule applies to
    - `api_types`(required): (List) The API types this rule applies to.
        - `api_type_id`(required):The API type ID
- Default value: An empty list (`[]`).


### Example Rule For Context-Based Restrictions Configuration

```hcl
cbr_rules = [
  {
  description = "Event Notifications can be accessed from xyz"
  account_id = "defc0df06b644a9cabc6e44f55b3880s."
  rule_contexts= [{
      attributes = [
                {
                              "name" : "endpointType",
                              "value" : "private"
                },
                {
                  name  = "networkZoneId"
                  value = "93a51a1debe2674193217209601dde6f" # pragma: allowlist secret
                }
        ]
     }
   ]
  enforcement_mode = "enabled"
  operations = [{
    api_types = [{
     api_type_id = "crn:v1:bluemix:public:context-based-restrictions::::api-type:"
      }]
    }]
  }
]
```
