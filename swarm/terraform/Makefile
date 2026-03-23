
.PHONY: help init plan apply destroy output logs status clean

TF_DIR := terraform
TF := cd $(TF_DIR) && terraform

GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

help:
	@echo ""
	@echo "$(GREEN)Docker Swarm Autoscale - Comandos $(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

init:
	@echo "$(GREEN)Inicializando Terraform...$(NC)"
	$(TF) init

plan:
	@echo "$(GREEN)Gerando plano...$(NC)"
	$(TF) plan

apply:
	@echo "$(GREEN)Aplicando mudanças...$(NC)"
	$(TF) apply -auto-approve
	@echo ""
	@echo "$(GREEN)✓Concluido!$(NC)"
	@echo ""
	@$(TF) output -json | jq -r '.useful_commands.value' 2>/dev/null || true

destroy:
	@echo "$(RED)Removendo stack...$(NC)"
	@docker stack rm redecor 2>/dev/null || true
	@sleep 5
	@echo "$(RED)Removendo configs...$(NC)"
	@docker config rm prometheus_config_v1 grafana_datasource_v1 grafana_provider_v1 grafana_dashboard_v1 2>/dev/null || true
	@echo "$(RED)Destruindo recursos Terraform...$(NC)"
	$(TF) destroy -auto-approve
	@echo "$(GREEN)✓ Recursos removidos!$(NC)"

output:
	$(TF) output

logs:
	@echo "$(GREEN)Logs do Autoscaler:$(NC)"
	docker service logs redecor_autoscaler -f --tail 50

logs-worker:
	@echo "$(GREEN)Logs do Worker:$(NC)"
	docker service logs redecor_worker -f --tail 50

status:
	@echo ""
	@echo "$(GREEN)=== Status dos Serviços ===$(NC)"
	@docker service ls
	@echo ""
	@echo "$(GREEN)=== URLs Disponíveis ===$(NC)"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana:    http://localhost:3000"
	@echo "  Kafka UI:   http://localhost:8080"

simulate:
	@echo "$(YELLOW)Iniciando simulação de carga...$(NC)"
	@echo "$(YELLOW)Pressione Ctrl+C para parar$(NC)"
	bash simulate_load.sh

clean:
	@echo "$(RED)Limpando recursos...$(NC)"
	@docker system prune -f
	@docker volume prune -f
	@echo "$(GREEN)✓ Concluido!$(NC)"

redeploy: destroy apply

setup:
	@echo "$(GREEN)Instalando dependencias...$(NC)"
	@which terraform > /dev/null || (echo "$(RED) Sem Terraform" && exit 1)
	@which docker > /dev/null || (echo "$(RED)Sem Docker" && exit 1)
	@echo "$(YELLOW)Copiando terraform.tfvars.example para terraform.tfvars...$(NC)"
	@cp -n $(TF_DIR)/terraform.tfvars.example $(TF_DIR)/terraform.tfvars 2>/dev/null || echo "terraform.tfvars existe"
	@echo "$(GREEN)✓ concluido!$(NC)"
	@echo ""
