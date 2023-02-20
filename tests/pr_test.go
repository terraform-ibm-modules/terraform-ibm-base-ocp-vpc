// Tests in this file are run in the PR pipeline
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Resource groups are maintained https://github.ibm.com/GoldenEye/ge-dev-account-management
const resourceGroup = "geretain-test-base-ocp-vpc"
const standardExampleTerraformDir = "examples/standard"

// Ensure there is one test per supported OCP version
const ocpVersion1 = "4.10"
const ocpVersion2 = "4.9"
const ocpVersion3 = "4.8"

func TestRunStandardExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  standardExampleTerraformDir,
		Prefix:        "base-ocp",
		ResourceGroup: resourceGroup,
		TerraformVars: map[string]interface{}{
			"ocp_version": ocpVersion2,
		},
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  standardExampleTerraformDir,
		Prefix:        "base-ocp-upg",
		ResourceGroup: resourceGroup,
		TerraformVars: map[string]interface{}{
			"ocp_version": ocpVersion2,
		},
	})

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
