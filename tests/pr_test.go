// Tests in this file are run in the PR pipeline
package test

import (
	"fmt"
	"log"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const fullyConfigurableTerraformDir = "solutions/fully-configurable"
const customsgExampleDir = "examples/custom_sg"
const quickStartTerraformDir = "solutions/quickstart"
const resourceGroup = "geretain-test-base-ocp-vpc"

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

// Ensure there is one test per supported OCP version
const ocpVersion1 = "4.18" // used by TestRunFullyConfigurable, TestRunUpgradeFullyConfigurable, TestFSCloudInSchematic and TestRunMultiClusterExample
const ocpVersion2 = "4.17" // used by TestCustomSGExample and TestRunCustomsgExample
const ocpVersion3 = "4.16" // used by TestRunAdvancedExample and TestCrossKmsSupportExample
const ocpVersion4 = "4.15" // used by TestRunAddRulesToSGExample and TestRunBasicExample

var (
	sharedInfoSvc      *cloudinfo.CloudInfoService
	permanentResources map[string]interface{}
)

// TestMain will be run before any parallel tests, used to set up a shared InfoService object to track region usage
// for multiple tests
func TestMain(m *testing.M) {
	sharedInfoSvc, _ = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})

	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func validateEnvVariable(t *testing.T, varName string) string {
	val, present := os.LookupEnv(varName)
	require.True(t, present, "%s environment variable not set", varName)
	require.NotEqual(t, "", val, "%s environment variable is empty", varName)
	return val
}

func setupTerraform(t *testing.T, prefix, realTerraformDir string) *terraform.Options {
	tempTerraformDir, err := files.CopyTerraformFolderToTemp(realTerraformDir, prefix)
	require.NoError(t, err, "Failed to create temporary Terraform folder")
	apiKey := validateEnvVariable(t, "TF_VAR_ibmcloud_api_key")
	region, err := testhelper.GetBestVpcRegion(apiKey, "../common-dev-assets/common-go-assets/cloudinfo-region-vpc-gen2-prefs.yaml", "eu-de")
	require.NoError(t, err, "Failed to get best VPC region")

	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix": prefix,
			"region": region,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, err = terraform.InitAndApplyE(t, existingTerraformOptions)
	require.NoError(t, err, "Init and Apply of temp existing resource failed")

	return existingTerraformOptions
}
func setupQuickstartOptions(t *testing.T, prefix string) *testschematic.TestSchematicOptions {
	apiKey := validateEnvVariable(t, "TF_VAR_ibmcloud_api_key")
	region, err := testhelper.GetBestVpcRegion(apiKey, "../common-dev-assets/common-go-assets/cloudinfo-region-vpc-gen2-prefs.yaml", "eu-de")
	require.NoError(t, err, "Failed to get best VPC region")
	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing:       t,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		Region:        region,
		TarIncludePatterns: []string{
			"*.tf",
			quickStartTerraformDir + "/*.tf", "scripts/*.sh", "kubeconfig/README.md",
		},
		TemplateFolder:         quickStartTerraformDir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 360,
	})
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "region", Value: region, DataType: "string"},
		{Name: "existing_resource_group_name", Value: resourceGroup, DataType: "string"},
		{Name: "size", Value: "mini", DataType: "string"},
		{Name: "ocp_entitlement", Value: "cloud_pak", DataType: "string"},
	}
	return options
}

func cleanupTerraform(t *testing.T, options *terraform.Options, prefix string) {
	if t.Failed() && strings.ToLower(os.Getenv("DO_NOT_DESTROY_ON_FAILURE")) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
		return
	}
	logger.Log(t, "START: Destroy (existing resources)")
	terraform.Destroy(t, options)
	terraform.WorkspaceDelete(t, options, prefix)
	logger.Log(t, "END: Destroy (existing resources)")
}

func TestRunFullyConfigurableInSchematics(t *testing.T) {
	t.Parallel()

	// Provision resources first
	prefix := fmt.Sprintf("ocp-fc-%s", strings.ToLower(random.UniqueId()))
	existingTerraformOptions := setupTerraform(t, prefix, "./existing-resources")

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing:               t,
		Prefix:                "ocp-fc",
		TarIncludePatterns:    []string{"*.tf", fullyConfigurableTerraformDir + "/*.*", fullyConfigurableTerraformDir + "/scripts/*.*", "scripts/*.sh", "kubeconfig/README.md", "modules/kube-audit/*.*", "modules/kube-audit/kubeconfig/README.md", "modules/kube-audit/scripts/*.sh", fullyConfigurableTerraformDir + "/kubeconfig/README.md", "modules/kube-audit/helm-charts/kube-audit/*.*", "modules/kube-audit/helm-charts/kube-audit/templates/*.*"},
		TemplateFolder:        fullyConfigurableTerraformDir,
		Tags:                  []string{"test-schematic"},
		DeleteWorkspaceOnFail: false,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "cluster_name", Value: "cluster", DataType: "string"},
		{Name: "ocp_version", Value: ocpVersion1, DataType: "string"},
		{Name: "ocp_entitlement", Value: "cloud_pak", DataType: "string"},
		{Name: "existing_resource_group_name", Value: terraform.Output(t, existingTerraformOptions, "resource_group_name"), DataType: "string"},
		{Name: "existing_cos_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "cos_instance_id"), DataType: "string"},
		{Name: "existing_vpc_crn", Value: terraform.Output(t, existingTerraformOptions, "vpc_crn"), DataType: "string"},
		{Name: "kms_encryption_enabled_cluster", Value: "true", DataType: "bool"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "kms_encryption_enabled_boot_volume", Value: "true", DataType: "bool"},
		{Name: "enable_secrets_manager_integration", Value: "true", DataType: "bool"},
		{Name: "existing_secrets_manager_instance_crn", Value: permanentResources["secretsManagerCRN"], DataType: "string"},
	}
	require.NoError(t, options.RunSchematicTest(), "This should not have errored")
	cleanupTerraform(t, existingTerraformOptions, prefix)
}

// Upgrade Test does not require KMS encryption
func TestRunUpgradeFullyConfigurable(t *testing.T) {
	t.Parallel()

	// Provision existing resources first
	prefix := fmt.Sprintf("ocp-existing-%s", strings.ToLower(random.UniqueId()))
	existingTerraformOptions := setupTerraform(t, prefix, "./existing-resources")

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing:               t,
		Prefix:                "fc-upg",
		TarIncludePatterns:    []string{"*.tf", fullyConfigurableTerraformDir + "/*.*", fullyConfigurableTerraformDir + "/scripts/*.*", "scripts/*.sh", "kubeconfig/README.md", "modules/kube-audit/*.*", "modules/kube-audit/kubeconfig/README.md", "modules/kube-audit/scripts/*.sh", fullyConfigurableTerraformDir + "/kubeconfig/README.md", "modules/kube-audit/helm-charts/kube-audit/*.*", "modules/kube-audit/helm-charts/kube-audit/templates/*.*"},
		TemplateFolder:        fullyConfigurableTerraformDir,
		Tags:                  []string{"test-schematic"},
		DeleteWorkspaceOnFail: false,
	})

	options.IgnoreUpdates = testhelper.Exemptions{List: []string{"module.kube_audit[0].helm_release.kube_audit"}}

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "cluster_name", Value: "cluster", DataType: "string"},
		{Name: "ocp_version", Value: ocpVersion1, DataType: "string"},
		{Name: "existing_resource_group_name", Value: terraform.Output(t, existingTerraformOptions, "resource_group_name"), DataType: "string"},
		{Name: "existing_cos_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "cos_instance_id"), DataType: "string"},
		{Name: "existing_vpc_crn", Value: terraform.Output(t, existingTerraformOptions, "vpc_crn"), DataType: "string"},
		{Name: "enable_secrets_manager_integration", Value: "true", DataType: "bool"},
		{Name: "existing_secrets_manager_instance_crn", Value: permanentResources["secretsManagerCRN"], DataType: "string"},
	}

	require.NoError(t, options.RunSchematicUpgradeTest(), "This should not have errored")
	cleanupTerraform(t, existingTerraformOptions, prefix)
}

// Adding the custom_sg example test to PR test.
// The custom_sg example was the subject of an IBM-Cloud provider bug in the past that has been resolved,
// so we want to keep testing this use-case in the PR pipelines.
func TestRunCustomsgExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:          t,
		TerraformDir:     customsgExampleDir,
		Prefix:           "base-ocp-customsg",
		ResourceGroup:    "geretain-test-base-ocp-vpc",
		CloudInfoService: sharedInfoSvc,
		ImplicitDestroy: []string{
			"module.ocp_base.null_resource.confirm_network_healthy",
			"module.ocp_base.null_resource.reset_api_key",
		},
		ImplicitRequired: false,
		TerraformVars: map[string]interface{}{
			"ocp_version":     ocpVersion2,
			"access_tags":     permanentResources["accessTags"],
			"ocp_entitlement": "cloud_pak",
		},
	})

	output, err := options.RunTestConsistency()

	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

/*******************************************************************
* TESTS FOR THE TERRAFORM BASED QUICKSTART DEPLOYABLE ARCHITECTURE *
********************************************************************/
func TestRunQuickstartSchematics(t *testing.T) {
	t.Parallel()

	options := setupQuickstartOptions(t, "ocp-qs")
	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

// Upgrade test for the Quickstart DA
func TestRunQuickstartUpgradeSchematics(t *testing.T) {
	t.Parallel()

	options := setupQuickstartOptions(t, "ocp-qs-upg")
	err := options.RunSchematicUpgradeTest()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
}
