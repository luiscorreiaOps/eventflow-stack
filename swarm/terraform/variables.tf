
variable "docker_host" {
  description = "host"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "swarm_advertise_addr" {
  description = "advertise do Swarm"
  type        = string
  default     = "127.0.0.1"
}

variable "swarm_initialized" {
  description = "para evitar re-init"
  type        = bool
  default     = false
}

variable "prometheus_port" {
  description = "Prometheus"
  type        = number
  default     = 9090
}

variable "grafana_port" {
  description = "Grafana"
  type        = number
  default     = 3000
}

variable "kafka_ui_port" {
  description = "Kafka UI"
  type        = number
  default     = 8080
}

variable "postgres_port" {
  description = "PostgreSQL"
  type        = number
  default     = 5432
}

variable "api_token" {
  description = "API para o worker"
  type        = string
  default     = "abc123"
  sensitive   = true
}

variable "api_token_expiration" {
  description = "Expi"
  type        = string
  default     = "1810000000"
}

variable "autoscaler_min_replicas" {
  description = "Min worker"
  type        = number
  default     = 1
}

variable "autoscaler_max_replicas" {
  description = "Max worker"
  type        = number
  default     = 5
}

variable "autoscaler_up_threshold" {
  description = "CPU para scale up "
  type        = number
  default     = 0.9
}

variable "autoscaler_down_threshold" {
  description = "CPU para scale down"
  type        = number
  default     = 0.6
}

variable "worker_cpu_limit" {
  description = "Limite worker"
  type        = string
  default     = "1.0"
}

variable "worker_memory_limit" {
  description = "Limite de mem"
  type        = string
  default     = "256M"
}
