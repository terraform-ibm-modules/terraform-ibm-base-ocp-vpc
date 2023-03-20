// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

func TestRunMultiClusterExample(t *testing.T) {
	t.Parallel()
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  "examples/multiple_mzr_clusters",
		Prefix:        "multi-clusters",
		ResourceGroup: resourceGroup,
		IgnoreDestroys: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{
				"module.ocp_base_cluster_1.null_resource.confirm_network_healthy",
				"module.ocp_base_cluster_1.null_resource.reset_api_key",
				"module.ocp_base_cluster_2.null_resource.confirm_network_healthy",
				"module.ocp_base_cluster_2.null_resource.reset_api_key",
			},
		},
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{
				"module.observability_agents_1.helm_release.logdna_agent",
				"module.observability_agents_1.helm_release.sysdig_agent",
				"module.observability_agents_2.helm_release.logdna_agent",
				"module.observability_agents_2.helm_release.sysdig_agent",
			},
		},
		ImplicitDestroy: []string{ // Ignore full destroy to speed up tests
			"module.observability_agents_1.helm_release.logdna_agent",
			"module.observability_agents_1.helm_release.sysdig_agent",
			"module.observability_agents_2.helm_release.logdna_agent",
			"module.observability_agents_2.helm_release.sysdig_agent",
		},
		// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
		ImplicitRequired: false,
		TerraformVars: map[string]interface{}{
			"ocp_version": ocpVersion2,
		},
	})
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunSzClusterExample(t *testing.T) {
	t.Parallel()
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  "examples/single_zone_cluster",
		Prefix:        "sz-cluster",
		ResourceGroup: resourceGroup,
		ImplicitDestroy: []string{
			"module.ocp_base.null_resource.confirm_network_healthy",
			"module.ocp_base.null_resource.reset_api_key",
		},
		// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
		ImplicitRequired: false,
		TerraformVars: map[string]interface{}{
			"ocp_version": ocpVersion3,
		},
	})
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunApplyTaintsExample(t *testing.T) {
	t.Parallel()
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  "examples/apply_taints",
		Prefix:        "std-taint",
		ResourceGroup: resourceGroup,
		ImplicitDestroy: []string{
			"module.ocp_base.null_resource.confirm_network_healthy",
			"module.ocp_base.null_resource.reset_api_key",
		},
		// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
		ImplicitRequired: false,
		TerraformVars: map[string]interface{}{
			"ocp_version": ocpVersion4,
		},
	})
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAddRulesToSGExample(t *testing.T) {
	t.Parallel()
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  "examples/add_rules_to_sg",
		Prefix:        "std-taint",
		ResourceGroup: resourceGroup,
		ImplicitDestroy: []string{
			"module.ocp_base.null_resource.confirm_network_healthy",
			"module.ocp_base.null_resource.reset_api_key",
		},
		// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
		ImplicitRequired: false,
		TerraformVars: map[string]interface{}{
			"ocp_version": ocpVersion1,
		},
	})
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
