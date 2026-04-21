# ─── Stage 1: Builder ───────────────────────────────
FROM python:3.11.12-slim-bookworm AS builder

WORKDIR /app

COPY requirements.txt .

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir --upgrade pip==25.3 && \
    pip install --no-cache-dir --upgrade setuptools==78.1.1 wheel==0.46.2 && \
    pip install --no-cache-dir -r requirements.txt

# ─── Stage 2: Final image ───────────────────────────
FROM python:3.11.12-slim-bookworm

WORKDIR /app

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser

COPY --from=builder /usr/local/lib/python3.11/site-packages/ \
                    /usr/local/lib/python3.11/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

COPY app.py .

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

CMD ["python3", "app.py"]