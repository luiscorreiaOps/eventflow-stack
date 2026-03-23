
terraform {
  required_version = ">= 1.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.0"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

resource "docker_network" "redecor_net" {
  name   = "redecor-net"
  driver = "overlay"
  attachable = true

  lifecycle {
    ignore_changes = [name]
  }
}

resource "local_file" "prometheus_config" {
  filename = "${path.module}/../prometheus.yml"
  content  = templatefile("${path.module}/templates/prometheus.yml.tpl", {
    prometheus_port = var.prometheus_port
  })
}

resource "null_resource" "docker_configs" {
  depends_on = [null_resource.swarm_init]

  triggers = {
    prometheus_config = filemd5("${path.module}/../prometheus.yml")
  }

  provisioner "local-exec" {
    command = <<-EOT
      docker config rm prometheus_config_v1 2>/dev/null || true
      docker config rm grafana_datasource_v1 2>/dev/null || true
      docker config rm grafana_provider_v1 2>/dev/null || true
      docker config rm grafana_dashboard_v1 2>/dev/null || true

      docker config create prometheus_config_v1 ${path.module}/../prometheus.yml
      docker config create grafana_datasource_v1 ${path.module}/configs/grafana_datasource.yml
      docker config create grafana_provider_v1 ${path.module}/configs/grafana_dashboard_provider.yml
      docker config create grafana_dashboard_v1 ${path.module}/configs/grafana_dashboard.json
    EOT
  }
}


resource "null_resource" "swarm_init" {
  triggers = {
    swarm_id = var.swarm_initialized ? "already_initialized" : timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      if ! docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
        echo "Inicializando Docker Swarm..."
        docker swarm init --advertise-addr ${var.swarm_advertise_addr}
      else
        echo "inicializado"
      fi
    EOT
  }
}

resource "null_resource" "build_images" {
  depends_on = [null_resource.swarm_init]

  triggers = {
    dockerfile_hash = filemd5("${path.module}/../Dockerfile.autoscaler")
    autoscale_hash  = filemd5("${path.module}/../autoscale.py")
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Building redecor-producer..."
      docker build -t redecor-producer:latest ${path.module}/../app/producer || \
        echo "Sem producer , usando imagem dummy"

      echo "Building worker..."
      docker build -t redecor-worker:latest ${path.module}/../app/worker || \
        echo "worker nao encontrado, usando imagem dummy"

      echo "Building autoscaler..."
      docker build -t redecor-autoscaler:latest -f ${path.module}/../Dockerfile.autoscaler ${path.module}/../
    EOT
  }
}

resource "null_resource" "deploy_stack" {
  depends_on = [
    null_resource.swarm_init,
    null_resource.docker_configs,
    null_resource.build_images,
    docker_network.redecor_net
  ]

  triggers = {
    stack_hash = filemd5("${path.module}/../docker-stack.yml")
    env_hash   = filemd5("${path.module}/../.env")
  }

  provisioner "local-exec" {
    command = <<-EOT
      docker stack rm redecor 2>/dev/null || true

      sleep 5

      docker network ls --filter "name=redecor" -q | xargs -r docker network rm 2>/dev/null || true

      sleep 2

      # Deploy stk
      echo "Deploying redecor stack..."
      env $(grep -v '^#' ${path.module}/../.env | xargs) docker stack deploy \
        -c ${path.module}/../docker-stack.yml redecor

      echo "Stack deployed"
    EOT
  }
}

# validated
resource "null_resource" "wait_for_services" {
  depends_on = [null_resource.deploy_stack]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Aguardando servics..."

      SERVICES="kafka postgres prometheus grafana cadvisor producer worker autoscaler"

      for SERVICE in $SERVICES; do
        echo -n "Aguardando $SERVICE..."
        timeout=120
        while [ $timeout -gt 0 ]; do
          if docker service ls --filter "name=redecor_$SERVICE" --format "{{.Replicas}}" | grep -q "1/1\|[2-9]/[2-9]"; then
            echo " OK"
            break
          fi
          echo -n "."
          sleep 2
          timeout=$((timeout - 2))
        done
        if [ $timeout -le 0 ]; then
          echo " TIMEOUT"
        fi
      done

      echo ""
      docker service ls
    EOT
  }
}


resource "local_file" "deploy_state" {
  depends_on = [null_resource.wait_for_services]

  filename = "${path.module}/.deploy_state"
  content  = <<-EOT
    DEPLOY_TIME=${timestamp()}
    SWARM_ADVERTISE_ADDR=${var.swarm_advertise_addr}
    PROMETHEUS_PORT=${var.prometheus_port}
    GRAFANA_PORT=${var.grafana_port}
    KAFKA_UI_PORT=${var.kafka_ui_port}
  EOT
}
