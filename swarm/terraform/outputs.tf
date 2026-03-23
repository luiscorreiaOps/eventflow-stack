

output "stack_status" {
  description = "Status do stack deployado"
  value       = "Stack 'redecor' deployado com sucesso!"
}

output "prometheus_url" {
  description = "URL do Prometheus"
  value       = "http://localhost:${var.prometheus_port}"
}

output "grafana_url" {
  description = "URL do Grafana"
  value       = "http://localhost:${var.grafana_port}"
}

output "kafka_ui_url" {
  description = "URL do Kafka UI"
  value       = "http://localhost:${var.kafka_ui_port}"
}

output "postgres_connection" {
  description = "PostgreSQL"
  value       = "postgresql://devops:supersecret@localhost:${var.postgres_port}/extractions"
  sensitive   = true
}

output "useful_commands" {
  description = "Comandos"
  value = <<-EOT

    docker service ls

    docker service logs redecor_autoscaler -f

    docker service logs redecor_worker -f

    bash swarm/simulate_load.sh

    docker service scale redecor_worker=3

    docker stack rm redecor

    docker config rm prometheus_config_v1 grafana_datasource_v1 grafana_provider_v1 grafana_dashboard_v1

  EOT
}

output "autoscaler_config" {
  description = "Config"
  value = {
    min_replicas     = var.autoscaler_min_replicas
    max_replicas     = var.autoscaler_max_replicas
    up_threshold     = var.autoscaler_up_threshold
    down_threshold   = var.autoscaler_down_threshold
  }
}
