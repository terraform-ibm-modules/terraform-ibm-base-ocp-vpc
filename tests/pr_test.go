// Tests in this file are run in the PR pipeline
package test

import (
	"log"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"

	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const resourceGroup = "geretain-test-base-ocp-vpc"
const advancedExampleDir = "examples/advanced"
const basicExampleDir = "examples/basic"
const fscloudExampleDir = "examples/fscloud"
const crossKmsSupportExampleDir = "examples/cross_kms_support"
const customsgExampleDir = "examples/custom_sg"

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

// Ensure there is one test per supported OCP version
const ocpVersion1 = "4.17" // used by TestRunUpgradeAdvancedExample , TestFSCloudInSchematic and TestRunMultiClusterExample
const ocpVersion2 = "4.16" // used by TestCustomSGExample and TestRunCustomsgExample
const ocpVersion3 = "4.15" // used by TestRunAdvancedExample and TestCrossKmsSupportExample
const ocpVersion4 = "4.14" // used by TestRunAddRulesToSGExample and TestRunBasicExample

var sharedInfoSvc *cloudinfo.CloudInfoService
var permanentResources map[string]interface{}

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

func setupOptions(t *testing.T, prefix string, terraformDir string, ocpVersion string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:          t,
		TerraformDir:     terraformDir,
		Prefix:           prefix,
		ResourceGroup:    resourceGroup,
		CloudInfoService: sharedInfoSvc,
		TerraformVars: map[string]interface{}{
			"ocp_version":     ocpVersion,
			"access_tags":     permanentResources["accessTags"],
			"ocp_entitlement": "cloud_pak",
		},
	})

	return options
}

func TestRunAdvancedExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "base-ocp-adv", advancedExampleDir, ocpVersion3)
	options.PostApplyHook = getClusterIngress

	output, err := options.RunTestConsistency()

	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
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

func TestRunUpgradeAdvancedExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "base-ocp-upg", advancedExampleDir, ocpVersion2)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
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
