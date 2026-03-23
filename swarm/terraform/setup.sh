#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}[1/6] Verificando dp...${NC}"

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}✗ $1 não encontrado${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 encontrado ($(which $1))${NC}"
        return 0
    fi
}

MISSING=0
check_command docker || MISSING=1
check_command terraform || MISSING=1

if [ $MISSING -eq 1 ]; then
    echo ""
    echo -e "${RED}Iinstale as dp:${NC}"
    echo "  - Docker: https://docs.docker.com/get-docker/"
    echo "  - Terraform: https://www.terraform.io/downloads"
    exit 1
fi

echo ""
echo -e "${YELLOW}[2/6] Verificando se Docker esta rodando...${NC}"
if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker nao esta rodando.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker está rodando${NC}"

echo ""
echo -e "${YELLOW}[3/6] Verificando Docker Swarm...${NC}"
if docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
    echo -e "${GREEN}✓ Docker Swarm ja inicializado${NC}"
else
    echo -e "${YELLOW}Inicializando Docker Swarm...${NC}"
    docker swarm init --advertise-addr 127.0.0.1
    echo -e "${GREEN}✓ Docker Swarm inicializado${NC}"
fi

echo ""
echo -e "${YELLOW}[4/6] Configurando Terraform...${NC}"
if [ ! -f terraform/terraform.tfvars ]; then
    cp terraform/terraform.tfvars.example terraform/terraform.tfvars
    echo -e "${GREEN}✓ terraform.tfvars criado${NC}"
else
    echo -e "${GREEN}✓ terraform.tfvars já existe${NC}"
fi

echo ""
echo -e "${YELLOW}[5/6] Inicializando Terraform...${NC}"
cd terraform
terraform init
cd ..
echo -e "${GREEN}✓ Terraform inicializado${NC}"

echo ""
echo -e "${YELLOW}[6/6] Fazendo deploy do stack...${NC}"
echo ""
cd terraform
terraform apply -auto-approve
cd ..

echo ""
echo -e "${GREEN}Serviços disponiveis:${NC}"
echo "  Prometheus: http://localhost:9090"
echo "  Grafana:    http://localhost:3000"
echo "  UI:   http://localhost:8080"
echo ""
echo -e "${YELLOW}Comandos:${NC}"
echo "  make status   "
echo "  make logs     "
echo "  make simulate "
echo "  make destroy  "
echo ""
