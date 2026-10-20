FROM python:3.13-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 DATA_DIR=/data
WORKDIR /app
COPY requirements.txt .
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir -r requirements.txt && useradd --uid 10001 --create-home kiss
COPY . .
RUN SECRET_KEY=build-only-key-not-used-in-production-12345 python manage.py collectstatic --noinput && mkdir -p /data && chown -R kiss:kiss /data /app
USER kiss
EXPOSE 8000
CMD ["sh", "entrypoint.sh"]
