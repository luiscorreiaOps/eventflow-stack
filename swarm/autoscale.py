import time
import requests
import subprocess
import os

PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://prometheus:9090")
SERVICE_NAME = os.getenv("SERVICE_NAME", "redecor_worker")
PROMETHEUS_JOB = os.getenv("PROMETHEUS_JOB", "worker")
UP_THRESHOLD = float(os.getenv("UP_THRESHOLD", 70.0))
DOWN_THRESHOLD = float(os.getenv("DOWN_THRESHOLD", 20.0))
MIN_REPLICAS = int(os.getenv("MIN_REPLICAS", 1))
MAX_REPLICAS = int(os.getenv("MAX_REPLICAS", 5))

def get_current_replicas():
    try:
        cmd = f"docker service inspect {SERVICE_NAME} --format '{{{{.Spec.Mode.Replicated.Replicas}}}}'"
        out = subprocess.check_output(cmd, shell=True).decode().strip()
        return int(out)
    except:
        return 1

def scale_service(replicas):
    print(f"Scaling {SERVICE_NAME} to {replicas} replicas")
    subprocess.run(f"docker service scale {SERVICE_NAME}={replicas}", shell=True)

def get_metric():
    query = 'avg(rate(container_cpu_usage_seconds_total{container_label_com_docker_swarm_service_name="' + SERVICE_NAME + '"}[1m])) * 100'
    try:
        response = requests.get(f"{PROMETHEUS_URL}/api/v1/query", params={"query": query})
        data = response.json()
        if data['status'] == 'success' and data['data']['result']:
            return float(data['data']['result'][0]['value'][1])
    except Exception as e:
        print(f"Error querying Prometheus: {e}")
    return None

print(f"Autoscaler started for {SERVICE_NAME}")
while True:
    metric = get_metric()
    if metric is not None:
        print(f"Current metric for {SERVICE_NAME}: {metric:.2f}%")
        current = get_current_replicas()
        if metric > UP_THRESHOLD and current < MAX_REPLICAS:
            scale_service(current + 1)
        elif metric < DOWN_THRESHOLD and current > MIN_REPLICAS:
            scale_service(current - 1)
    else:
        print(f"Could not get metric for {SERVICE_NAME}")
    time.sleep(15)
