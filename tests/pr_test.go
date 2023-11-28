// Tests in this file are run in the PR pipeline
package test

import (
	"log"
	"os"
	"testing"

	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const resourceGroup = "geretain-test-base-ocp-vpc"
const advancedExampleDir = "examples/advanced"
const basicExampleDir = "examples/basic"
const fscloudExampleDir = "examples/fscloud"

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

// Ensure there is one test per supported OCP version
const ocpVersion1 = "4.13" // used by TestRunUpgradeAdvancedExample, TestFSCloudExample and TestRunMultiClusterExample
const ocpVersion2 = "4.12" // used by TestRunAdvancedExample and TestRunAddRulesToSGExample
const ocpVersion3 = "4.11" // used by TestRunBasicExample

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
			"ocp_version": ocpVersion,
			"access_tags": permanentResources["accessTags"],
		},
	})

	return options
}

func TestRunAdvancedExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "base-ocp-adv", advancedExampleDir, ocpVersion2)

	output, err := options.RunTestConsistency()

	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunUpgradeAdvancedExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "base-ocp-upg", advancedExampleDir, ocpVersion1)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

func TestFSCloudExample(t *testing.T) {
	t.Parallel()

	/*
	 The 'ResourceGroup' is not set to force this test to create a unique resource group to ensure tests do
	 not clash. This is due to the fact that an auth policy may already exist in this resource group since we are
	 re-using a permanent HPCS instance. By using a new resource group, the auth policy will not already exist
	 since this module scopes auth policies by resource group.
	*/
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: fscloudExampleDir,
		Prefix:       "base-ocp-fscloud",
		TerraformVars: map[string]interface{}{
			"existing_at_instance_crn": permanentResources["activityTrackerFrankfurtCrn"],
			"hpcs_instance_guid":       permanentResources["hpcs_south"],
			"hpcs_key_crn_cluster":     permanentResources["hpcs_south_root_key_crn"],
			"hpcs_key_crn_worker_pool": permanentResources["hpcs_south_root_key_crn"],
			"ocp_version":              ocpVersion1,
		},
	})

	// If "jp-osa" was the best region selected, default to us-south instead.
	// "jp-osa" is currently not allowing hs-crypto be used for encrypting in that region.
	currentRegion, ok := options.TerraformVars["region"]
	if ok && currentRegion == "jp-osa" {
		options.TerraformVars["region"] = "us-south"
	}

	output, err := options.RunTestConsistency()

	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")

}
