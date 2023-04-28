// Tests in this file are run in the PR pipeline
package test

import (
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"log"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const resourceGroup = "geretain-test-base-ocp-vpc"
const standardExampleTerraformDir = "examples/standard"
const fscloudExampleTerraformDir = "examples/fscloud"

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

// Ensure there is one test per supported OCP version
const ocpVersion1 = "4.12"
const ocpVersion2 = "4.11"
const ocpVersion3 = "4.10"
const ocpVersion4 = "4.9"

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

func TestRunCompleteExample(t *testing.T) {
	t.Parallel()

	versions := []string{"4.12", "4.11", "4.10", "4.9"}
	for _, version := range versions {
		t.Run(version, func(t *testing.T) { testRunStandardExample(t, version) })
	}
}

func testRunStandardExample(t *testing.T, version string) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:          t,
		TerraformDir:     standardExampleTerraformDir,
		Prefix:           "ocp-standard",
		ResourceGroup:    resourceGroup,
		CloudInfoService: sharedInfoSvc,
		TerraformVars: map[string]interface{}{
			"ocp_version": version,
			"access_tags": permanentResources["accessTags"],
		},
	})
	output, err := options.RunTestConsistency()

	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:          t,
		TerraformDir:     standardExampleTerraformDir,
		Prefix:           "base-ocp-upg",
		ResourceGroup:    resourceGroup,
		CloudInfoService: sharedInfoSvc,
	})
	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

func TestFSCloudExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:          t,
		TerraformDir:     fscloudExampleTerraformDir,
		Prefix:           "base-ocp-fscloud",
		Region:           "us-south",
		CloudInfoService: sharedInfoSvc,
		TerraformVars: map[string]interface{}{
			"existing_at_instance_crn":              permanentResources["activityTrackerFrankfurtCrn"],
			"hpcs_instance_guid":                    permanentResources["hpcs_south"],
			"hpcs_key_crn_cluster":                  permanentResources["hpcs_south_root_key_crn"],
			"hpcs_key_crn_worker_pool":              permanentResources["hpcs_south_root_key_crn"],
			"primary_existing_hpcs_instance_guid":   permanentResources["hpcs_south"],
			"primary_hpcs_key_crn":                  permanentResources["hpcs_south_root_key_crn"],
			"secondary_existing_hpcs_instance_guid": permanentResources["hpcs_east"],
			"secondary_hpcs_key_crn":                permanentResources["hpcs_east_root_key_crn"],
		},
	})

	output, err := options.RunTestConsistency()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
