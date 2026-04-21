# ─── Stage 1: Builder ───────────────────────────────
FROM python:3.11.12-slim-bookworm AS builder

WORKDIR /app

COPY requirements.txt .

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Upgrade pip, setuptools, wheel to patched versions
    pip install --no-cache-dir --upgrade pip==25.3 setuptools==78.1.1 wheel==0.46.2 && \
    # Remove old versions left behind by base image
    find /usr/local/lib/python3.11/site-packages -maxdepth 1 \
      -name "pip-24*" -o \
      -name "setuptools-65*" -o \
      -name "wheel-0.4[0-5]*" | xargs rm -rf && \
    pip install --no-cache-dir -r requirements.txt

# ─── Stage 2: Final image ───────────────────────────
FROM python:3.11.12-slim-bookworm

WORKDIR /app

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Also remove old pip/setuptools from final stage base image
    find /usr/local/lib/python3.11/site-packages -maxdepth 1 \
      -name "pip-24*" -o \
      -name "setuptools-65*" -o \
      -name "wheel-0.4[0-5]*" | xargs rm -rf

RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser

# Copy ONLY the upgraded packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages/ \
                    /usr/local/lib/python3.11/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

COPY app.py .

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

CMD ["python3", "app.py"]