// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "base-ocp", basicExampleDir, ocpVersion6)

	output, err := options.RunTestConsistency()

	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunCustomsgExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "base-ocp-customsg", customsgExampleDir, ocpVersion2)

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
			// workaround for the issue https://github.ibm.com/GoldenEye/issues/issues/10743
			// when the issue is fixed on IKS, so the destruction of default workers pool is correctly managed on provider/clusters service the next two entries should be removed
			"'module.ocp_base_cluster_1.ibm_container_vpc_worker_pool.autoscaling_pool[\"default\"]'",
			"'module.ocp_base_cluster_1.ibm_container_vpc_worker_pool.pool[\"default\"]'",
			"'module.ocp_base_cluster_2.ibm_container_vpc_worker_pool.autoscaling_pool[\"default\"]'",
			"'module.ocp_base_cluster_2.ibm_container_vpc_worker_pool.pool[\"default\"]'",
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
			// workaround for the issue https://github.ibm.com/GoldenEye/issues/issues/10743
			// when the issue is fixed on IKS, so the destruction of default workers pool is correctly managed on provider/clusters service the next two entries should be removed
			"'module.ocp_base.ibm_container_vpc_worker_pool.autoscaling_pool[\"default\"]'",
			"'module.ocp_base.ibm_container_vpc_worker_pool.pool[\"default\"]'",
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

func TestCustomSGExample(t *testing.T) {
	t.Parallel()
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  "examples/custom_sg",
		Prefix:        "cust-sg",
		ResourceGroup: resourceGroup,
		ImplicitDestroy: []string{
			"module.ocp_base.null_resource.confirm_network_healthy",
			"module.ocp_base.null_resource.reset_api_key",
			// workaround for the issue https://github.ibm.com/GoldenEye/issues/issues/10743
			// when the issue is fixed on IKS, so the destruction of default workers pool is correctly managed on provider/clusters service the next two entries should be removed
			"'module.ocp_base.ibm_container_vpc_worker_pool.autoscaling_pool[\"default\"]'",
			"'module.ocp_base.ibm_container_vpc_worker_pool.pool[\"default\"]'",
		},
		// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
		ImplicitRequired: false,
		TerraformVars: map[string]interface{}{
			"ocp_version": ocpVersion2,
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
			"ocp_version":          ocpVersion5,
		},
		ImplicitDestroy: []string{
			// workaround for the issue https://github.ibm.com/GoldenEye/issues/issues/10743
			// when the issue is fixed on IKS, so the destruction of default workers pool is correctly managed on provider/clusters service the next two entries should be removed
			"'module.ocp_base.ibm_container_vpc_worker_pool.autoscaling_pool[\"default\"]'",
			"'module.ocp_base.ibm_container_vpc_worker_pool.pool[\"default\"]'",
		},
	})

	output, err := options.RunTestConsistency()

	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")

}
