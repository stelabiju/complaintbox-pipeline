# Stage 1: Build dependencies
FROM python:3.9-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends gcc pkg-config default-libmysqlclient-dev && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# Stage 2: Run application
FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends libmariadb3 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local
COPY . .

RUN useradd --create-home appuser && mkdir -p /app/media && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["gunicorn", "complaint_box.wsgi:application", "--bind", "0.0.0.0:8000"]