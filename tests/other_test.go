// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const advancedExampleDir = "examples/advanced"
const basicExampleDir = "examples/basic"
const fscloudExampleDir = "examples/fscloud"
const crossKmsSupportExampleDir = "examples/cross_kms_support"

func setupOptions(t *testing.T, prefix string, terraformDir string, ocpVersion string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:          t,
		TerraformDir:     terraformDir,
		Prefix:           prefix,
		ResourceGroup:    resourceGroup,
		CloudInfoService: sharedInfoSvc,
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{
				"module.observability_agents.module.logs_agent[0].helm_release.logs_agent",
			},
		},
		TerraformVars: map[string]interface{}{
			"ocp_version":     ocpVersion,
			"access_tags":     permanentResources["accessTags"],
			"ocp_entitlement": "cloud_pak",
		},
	})

	return options
}

func getClusterIngress(options *testhelper.TestOptions) error {

	// Get output of the last apply
	outputs, outputErr := terraform.OutputAllE(options.Testing, options.TerraformOptions)
	if !assert.NoError(options.Testing, outputErr, "error getting last terraform apply outputs: %s", outputErr) {
		return nil
	}

	// Validate that the "cluster_name" key is present in the outputs
	expectedOutputs := []string{"cluster_name"}
	_, ValidationErr := testhelper.ValidateTerraformOutputs(outputs, expectedOutputs...)

	// Proceed with the cluster ingress health check if "cluster_name" is valid
	if assert.NoErrorf(options.Testing, ValidationErr, "Some outputs not found or nil: %s", ValidationErr) {
		options.CheckClusterIngressHealthyDefaultTimeout(outputs["cluster_name"].(string))
	}
	return nil
}

func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "base-ocp", basicExampleDir, ocpVersion4)

	output, err := options.RunTestConsistency()

	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

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
				"module.observability_agents_1.helm_release.sysdig_agent",
				"module.observability_agents_2.helm_release.sysdig_agent",
				"module.observability_agents_1.helm_release.cloud_monitoring_agent",
				"module.observability_agents_2.helm_release.cloud_monitoring_agent",
			},
		},
		ImplicitDestroy: []string{ // Ignore full destroy to speed up tests
			"module.observability_agents_1.helm_release.sysdig_agent",
			"module.observability_agents_2.helm_release.sysdig_agent",
			"module.observability_agents_1.helm_release.cloud_monitoring_agent",
			"module.observability_agents_2.helm_release.cloud_monitoring_agent",
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

func TestRunAddRulesToSGExample(t *testing.T) {
	t.Parallel()
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  "examples/add_rules_to_sg",
		Prefix:        "sg-rules",
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

func TestCrossKmsSupportExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: crossKmsSupportExampleDir,
		Prefix:       "cross-kp",
		TerraformVars: map[string]interface{}{
			"kms_instance_guid":    permanentResources["kp_us_south_guid"],
			"kms_key_id":           permanentResources["kp_us_south_root_key_id"],
			"kms_cross_account_id": permanentResources["ge_ops_account_id"],
			"ocp_version":          ocpVersion3,
		},
	})

	output, err := options.RunTestConsistency()

	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")

}

func TestRunAdvancedExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "base-ocp-adv", advancedExampleDir, ocpVersion3)
	options.PostApplyHook = getClusterIngress

	output, err := options.RunTestConsistency()

	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestFSCloudInSchematic(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  "base-ocp-fscloud",
		TarIncludePatterns: []string{
			"*.tf",
			"scripts/*.sh",
			"examples/fscloud/*.tf",
			"modules/*/*.tf",
			"kubeconfig/README.md",
		},
		ResourceGroup:          resourceGroup,
		TemplateFolder:         fscloudExampleDir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 240,
	})

	// If "jp-osa" was the best region selected, default to us-south instead.
	// "jp-osa" is currently not allowing hs-crypto be used for encrypting in that region.
	if options.Region == "jp-osa" {
		options.Region = "us-south"
	}

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "region", Value: options.Region, DataType: "string"},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "resource_group", Value: options.ResourceGroup, DataType: "string"},
		{Name: "hpcs_instance_guid", Value: permanentResources["hpcs_south"], DataType: "string"},
		{Name: "hpcs_key_crn_cluster", Value: permanentResources["hpcs_south_root_key_crn"], DataType: "string"},
		{Name: "hpcs_key_crn_worker_pool", Value: permanentResources["hpcs_south_root_key_crn"], DataType: "string"},
		{Name: "ocp_version", Value: ocpVersion1, DataType: "string"},
		{Name: "ocp_entitlement", Value: "cloud_pak", DataType: "string"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}
