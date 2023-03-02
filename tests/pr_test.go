// Tests in this file are run in the PR pipeline
package test

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const resourceGroup = "geretain-test-base-ocp-vpc"
const standardExampleTerraformDir = "examples/standard"

// Ensure there is one test per supported OCP version
const ocpVersion1 = "4.11"
const ocpVersion2 = "4.12"
const ocpVersion3 = "4.10"
const ocpVersion4 = "4.9"
const ocpVersion5 = "4.8"

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

func TestRunStandardExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "base-ocp", standardExampleTerraformDir)

	output, err := options.RunTestConsistency()

	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	// TODO: Remove this line after the first merge to primary branch is complete to enable upgrade test
	t.Skip("Skipping upgrade test until initial code is in primary branch")

	options := setupOptions(t, "base-ocp-upg", standardExampleTerraformDir)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
