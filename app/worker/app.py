import json
import time
import os
import psycopg2
from kafka import KafkaConsumer
from prometheus_client import start_http_server, Counter

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("POSTGRES_DB")
DB_USER = os.getenv("POSTGRES_USER")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD")
KAFKA_BROKER = os.getenv("KAFKA_BROKER")
API_TOKEN_EXPIRATION = int(os.getenv("API_TOKEN_EXPIRATION"))
METRICS_PORT = int(os.getenv("METRICS_PORT"))

# Metric
PROCESSED_COUNT = Counter(
    "extraction_processed_total",
    "Total de extrações processadas com sucesso"
)
FAILURE_COUNT = Counter(
    "extraction_failure_total",
    "Total de falhas no processamento"
)

start_http_server(METRICS_PORT)
print(f"Metrics server started on port {METRICS_PORT}")

def safe_deserializer(x):
    try:
        return json.loads(x.decode("utf-8"))
    except Exception as e:
        print(f"[ERRO] Mensagem inválida: {x} | erro: {e}")
        return None


def connect_db():
    while True:
        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD
            )
            conn.autocommit = False
            print("Connected to Postgres")
            return conn
        except Exception as e:
            print(f"[DB] Waiting for Postgres... {e}")
            time.sleep(3)


def ensure_table(conn):
    """Garante tabela"""
    while True:
        try:
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS jobs (
                    id SERIAL PRIMARY KEY,
                    external_id INT,
                    status TEXT,
                    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            conn.commit()
            print("Table ensured")
            return
        except Exception as e:
            print(f"[DB] Error creating table: {e}")
            try:
                conn.close()
            except:
                pass
            conn = connect_db()


def connect_kafka():
    while True:
        try:
            consumer = KafkaConsumer(
                "extractions",
                bootstrap_servers=KAFKA_BROKER,
                group_id="worker-group",
                auto_offset_reset="earliest",
                value_deserializer=safe_deserializer,
            )
            print("Connected to Kafka")
            return consumer
        except Exception as e:
            print(f"[KAFKA] Waiting for Kafka... {e}")
            time.sleep(3)


# init
conn = connect_db()
ensure_table(conn)
cursor = conn.cursor()

consumer = connect_kafka()

print("Worker started processing messages...")


for message in consumer:
    if message.value is None:
        continue

    data = message.value
    print(f"Processing: {data}")

    # Token check
    if time.time() > API_TOKEN_EXPIRATION:
        print("[AVISO] Token expirado!")
        FAILURE_COUNT.inc()
        continue

    try:
        # Simulador processamento pesado
        time.sleep(0.5)

        cursor.execute(
            "INSERT INTO jobs (external_id, status) VALUES (%s, %s)",
            (data.get("id"), "processed")
        )
        conn.commit()

        print(f"Job {data.get('id')} saved to database.")
        PROCESSED_COUNT.inc()

    except psycopg2.OperationalError as e:
        print(f"[ERRO DB - reconectando] {e}")
        FAILURE_COUNT.inc()

        try:
            conn.close()
        except:
            pass

        conn = connect_db()
        cursor = conn.cursor()

    except Exception as e:
        print(f"[ERRO GERAL] {e}")
        FAILURE_COUNT.inc()
        try:
            conn.rollback()
        except:
            pass
