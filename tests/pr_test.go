// Tests in this file are run in the PR pipeline
package test

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Resource groups are maintained https://github.ibm.com/GoldenEye/ge-dev-account-management
const resourceGroup = "geretain-test-base-ocp-vpc"

// const standardExampleTerraformDir = "examples/standard"
const mzrExampleTerraformDir = "examples/multiple_mzr_clusters"
const szExampleTerraformDir = "examples/single_zone_cluster"

// Ensure there is one test per supported OCP version (see if we can automate this - https://github.ibm.com/GoldenEye/issues/issues/1671)
const ocpVersion1 = "4.10"
const ocpVersion2 = "4.9"
const ocpVersion3 = "4.8"

var sharedInfoSvc *cloudinfo.CloudInfoService

// TestMain will be run before any parallel tests, used to set up a shared InfoService object to track region usage
// for multiple tests
func TestMain(m *testing.M) {

	sharedInfoSvc, _ = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})
	os.Exit(m.Run())
}

func setupOptions(t *testing.T, prefix string, terraformDir string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:          t,
		TerraformDir:     terraformDir,
		Prefix:           prefix,
		ResourceGroup:    resourceGroup,
		CloudInfoService: sharedInfoSvc,
		TerraformVars: map[string]interface{}{
			"ocp_version": ocpVersion2,
		},
	})

	return options
}

// func TestRunStandardExample(t *testing.T) {
// 	t.Parallel()

// 	options := setupOptions(t, "base-ocp", standardExampleTerraformDir)

// 	output, err := options.RunTestConsistency()

// 	assert.Nil(t, err, "This should not have errored")
// 	assert.NotNil(t, output, "Expected some output")
// }

// Validating other examples :
func TestRunMZRClustersExample(t *testing.T) {
	t.Parallel()
	options := setupOptions(t, "base-ocp-mzr", mzrExampleTerraformDir)
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
func TestRunSingleZoneClusterExample(t *testing.T) {
	t.Parallel()
	options := setupOptions(t, "base-ocp-sz", szExampleTerraformDir)
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

// func TestRunUpgradeExample(t *testing.T) {
// 	t.Parallel()

// 	// TODO: Remove this line after the first merge to primary branch is complete to enable upgrade test
// 	t.Skip("Skipping upgrade test until initial code is in primary branch")

// 	options := setupOptions(t, "base-ocp-upg", standardExampleTerraformDir)

// 	output, err := options.RunTestUpgrade()
// 	if !options.UpgradeTestSkipped {
// 		assert.Nil(t, err, "This should not have errored")
// 		assert.NotNil(t, output, "Expected some output")
// 	}
// }
