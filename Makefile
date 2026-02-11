# Build the p0 provider from the local repo with the binary name Terraform expects.
# Terraform dev_overrides looks for terraform-provider-p0 in the override directory.
.PHONY: build-local-provider
build-local-provider:
	cd ../terraform-provider-p0 && go build -o terraform-provider-p0 .

# Use local provider: build it, then run terraform with TF_CLI_CONFIG_FILE set.
# Example: make use-local-provider plan
.PHONY: use-local-provider
use-local-provider: build-local-provider
	@echo "Run: export TF_CLI_CONFIG_FILE=\"$$(pwd)/terraform.rc\""
	@echo "Then: terraform init -upgrade && terraform plan"
