// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/stretchr/testify/require"
	"github.com/IBM/go-sdk-core/v5/core"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const advancedExampleDir = "examples/advanced"
const basicExampleDir = "examples/basic"
const fscloudExampleDir = "examples/fscloud"
const crossKmsSupportExampleDir = "examples/cross_kms_support"
const monolithExampleDir = "examples/monolith"

func setupOptions(t *testing.T, prefix string, terraformDir string, ocpVersion string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:          t,
		TerraformDir:     terraformDir,
		Prefix:           prefix,
		ResourceGroup:    resourceGroup,
		CloudInfoService: sharedInfoSvc,
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{
				"module.logs_agents.helm_release.logs_agent",
			},
		},
		TerraformVars: map[string]interface{}{
			"ocp_version":     ocpVersion,
			"access_tags":     permanentResources["accessTags"],
			"ocp_entitlement": "cloud_pak",
		},
		CheckApplyResultForUpgrade: true,
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
				"module.ocp_base_cluster_2.null_resource.confirm_network_healthy",
			},
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
		TerraformVersion:       terraformVersion,
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

func provisionPreReq(t *testing.T, p string) (string, *terraform.Options, error) {
	// ------------------------------------------------------------------------------------
	// Provision existing resources first
	// ------------------------------------------------------------------------------------
	prefix := fmt.Sprintf("%s-%s", p, strings.ToLower(random.UniqueId()))
	realTerraformDir := "./existing-resources-monolith"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, prefix)

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix": prefix,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)
	if existErr != nil {
		// assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
		return "", nil, existErr
	}
	return prefix, existingTerraformOptions, nil
}

func TestMonolithExample(t *testing.T) {
	t.Parallel()

	prefix, existingTerraformOptions, existErr := provisionPreReq(t, "mon-ocp")

	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {
		options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  prefix,
			TarIncludePatterns: []string{
				"*.tf",
				monolithExampleDir + "/*.tf",
				fullyConfigurableTerraformDir + "/scripts/*.*",
				"/scripts/*.*",
				"kubeconfig/*.*",
				"modules/kube-audit/*.*",
				"modules/worker-pool/*.*",
				"modules/kube-audit/kubeconfig/*.*",
				"modules/kube-audit/scripts/*.*",
				"modules/kube-audit/helm-charts/kube-audit/*.*",
				"modules/kube-audit/helm-charts/kube-audit/templates/*.*",
				"modules/monolith/*.tf",
			},
			TemplateFolder:         monolithExampleDir,
			Tags:                   []string{"monolith-base-ocp-test"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 240,
			IgnoreAdds: testhelper.Exemptions{
				List: []string{"module.monolith_add_ons.module.scc_wp.restapi_object.cspm"},
			},
			IgnoreUpdates: testhelper.Exemptions{
				List: []string{"module.ocp_base.ibm_container_addons.addons"},
			},
		})
		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "prefix", Value: prefix, DataType: "string"},
			{Name: "existing_resource_group_name", Value: terraform.Output(t, existingTerraformOptions, "resource_group_name"), DataType: "string"},
			{Name: "kms_encryption_enabled_cluster", Value: true, DataType: "bool"},
			{Name: "existing_event_notifications_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "event_notifications_instance_crn"), DataType: "string"},
		}

		err := options.RunSchematicTest()
		assert.Nil(t, err, "This should not have errored")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (prereq resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (prereq resources)")
	}

func TestAddonPermutations(t *testing.T) {
	testCases := []testaddons.AddonTestCase{
		{
			Name:   "no-addons",
			Prefix: "no-addons",
			Dependencies: []cloudinfo.AddonConfig{
				{
					OfferingName:   "deploy-arch-ibm-slz-vpc",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true), // required addon
				},
				{
					OfferingName:   "deploy-arch-ibm-kms",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-cos",
					OfferingFlavor: "instance",
					Enabled:        core.BoolPtr(true), // required addon
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-logs",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-monitoring",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-activity-tracker",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-secrets-manager",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-scc-workload-protection",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
			},
		},
		{
			Name:   "all-addons",
			Prefix: "all-addons",
			Dependencies: []cloudinfo.AddonConfig{
				{
					OfferingName:   "deploy-arch-ibm-slz-vpc",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-kms",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-cos",
					OfferingFlavor: "instance",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-logs",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-monitoring",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-activity-tracker",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-secrets-manager",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-scc-workload-protection",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
			},
		},
		{
			Name:   "observability-with-no-deps",
			Prefix: "obs-no-dep",
			Dependencies: []cloudinfo.AddonConfig{
				{
					OfferingName:   "deploy-arch-ibm-slz-vpc",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true), // required addon
				},
				{
					OfferingName:   "deploy-arch-ibm-kms",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-cos",
					OfferingFlavor: "instance",
					Enabled:        core.BoolPtr(true), // required addon
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-logs",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-monitoring",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-activity-tracker",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-secrets-manager",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-scc-workload-protection",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-event-notifications",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
			},
		},
	}

	baseOptions := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing:              t,
		ResourceGroup:        resourceGroup,
		QuietMode:            true,
		DeployTimeoutMinutes: 240,
	})

	matrix := testaddons.AddonTestMatrix{
		BaseOptions: baseOptions,
		TestCases:   testCases,
		BaseSetupFunc: func(baseOptions *testaddons.TestAddonOptions, testCase testaddons.AddonTestCase) *testaddons.TestAddonOptions {
			return testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
				Testing:          t,
				Prefix:           testCase.Prefix,
				ResourceGroup:    resourceGroup,
				VerboseOnFailure: true,
			})
		},
		AddonConfigFunc: func(options *testaddons.TestAddonOptions, testCase testaddons.AddonTestCase) cloudinfo.AddonConfig {
			return cloudinfo.NewAddonConfigTerraform(
				options.Prefix,
				"deploy-arch-ibm-slz-ocp",
				"fully-configurable",
				map[string]interface{}{},
			)
		},
	}

	baseOptions.RunAddonTestMatrix(matrix)
}
