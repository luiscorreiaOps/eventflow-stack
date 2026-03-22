FROM python:3.11-slim

WORKDIR /app

COPY app.py .

RUN pip install kafka-python prometheus-client

CMD ["python","-u", "app.py"]
