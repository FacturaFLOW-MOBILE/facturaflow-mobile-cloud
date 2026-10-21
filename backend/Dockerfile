FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PORT=8080
WORKDIR /app
COPY requirements_firestore.txt /app/requirements_firestore.txt
RUN pip install --no-cache-dir -r /app/requirements_firestore.txt
COPY cloud_api /app/cloud_api
CMD ["sh", "-c", "gunicorn cloud_api.wsgi:application --bind 0.0.0.0:${PORT:-8080} --workers 2 --threads 4 --timeout 60"]
