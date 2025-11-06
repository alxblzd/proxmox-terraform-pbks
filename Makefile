.PHONY: help fmt validate clean

.DEFAULT_GOAL := help

PLAYBOOKS := 01-debian13-vms 02-ubuntu24-vms 03-lxc-containers 04-k3s-cluster 05-docker-swarm 06-debian-dev-ansible

help:
	@echo "Terraform Proxmox Commands:"
	@echo ""
	@echo "  make fmt         Format all Terraform files"
	@echo "  make validate    Validate all playbook configs"
	@echo "  make clean       Remove Terraform artifacts"
	@echo ""

fmt:
	@terraform fmt -recursive .

validate:
	@for pb in $(PLAYBOOKS); do \
		echo "Validating $$pb..."; \
		cd $$pb && terraform init -backend=false >/dev/null 2>&1 && terraform validate && cd ..; \
	done

clean:
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@find . -type f -name "terraform.tfstate*" -delete 2>/dev/null || true
