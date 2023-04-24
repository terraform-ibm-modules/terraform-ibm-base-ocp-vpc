// Tests in this file are run in the PR pipeline
package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"log"
	"os"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const resourceGroup = "geretain-test-base-ocp-vpc"
const standardExampleTerraformDir = "examples/standard"
const fscloudExampleTerraformDir = "examples/fscloud"
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var permanentResources map[string]interface{}
var sharedInfoSvc *cloudinfo.CloudInfoService

// TestMain will be run before any parallel tests, used to set up a shared InfoService object to track region usage
// for multiple tests
func TestMain(m *testing.M) {
	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}
	sharedInfoSvc, _ = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})
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
		ResourceGroup:    fmt.Sprintf("%s-%s", resourceGroup, strings.ToLower(random.UniqueId())), // unique rg to avoid dup policy
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
