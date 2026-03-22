import time
import json
import os
from kafka import KafkaProducer
from prometheus_client import start_http_server, Counter

# Configs
KAFKA_BROKER = os.getenv("KAFKA_BROKER")
METRICS_PORT = int(os.getenv("METRICS_PORT"))

# Metrics
SENT_COUNT = Counter("extraction_sent_total", "Total de mensagens enviadas")

start_http_server(METRICS_PORT)
print(f"Metrics server started on port {METRICS_PORT}")

# w8 Kafka
while True:
    try:
        producer = KafkaProducer(
            bootstrap_servers=KAFKA_BROKER,
            value_serializer=lambda v: json.dumps(v).encode("utf-8")
        )
        print("Connected to Kafka (producer)")
        break
    except Exception as e:
        print(f"Waiting for Kafka... {e}")
        time.sleep(5)

i = 0
while True:
    data = {
        "id": i,
        "timestamp": time.time(),
        "type": "extraction_request"
    }

    try:
        producer.send("extractions", data)
        print(f"Sent: {data}")
        SENT_COUNT.inc()
        i += 1
    except Exception as e:
        print(f"Error sending message: {e}")

    time.sleep(5)
