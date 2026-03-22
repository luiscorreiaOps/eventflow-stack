FROM python:3.11-slim

WORKDIR /app

COPY . .

RUN pip install kafka-python psycopg2-binary prometheus-client

CMD ["python", "-u", "app.py"]
