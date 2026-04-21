# ─── Stage 1: Builder ───────────────────────────────
FROM python:3.11.12-slim-bookworm AS builder

WORKDIR /app

COPY requirements.txt .

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Upgrade tools first
RUN pip install --no-cache-dir pip==25.3 setuptools==78.1.1 wheel==0.46.2

# Manually delete ALL old dist-info for pip, setuptools, wheel
RUN find /usr/local/lib/python3.11/site-packages/ -maxdepth 1 -type d \( \
      -name "pip-*.dist-info" \
      -o -name "setuptools-*.dist-info" \
      -o -name "wheel-*.dist-info" \
      -o -name "setuptools-*.egg-info" \
    \) | grep -v "pip-25.3" | grep -v "setuptools-78" | grep -v "wheel-0.46" \
    | xargs -r rm -rf

# Install app dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Verify — should show ONLY new versions
RUN pip list | grep -E "pip|setuptools|wheel"

# ─── Stage 2: Final clean image ─────────────────────
FROM python:3.11.12-slim-bookworm

WORKDIR /app

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser

# Copy site-packages from builder (already clean)
COPY --from=builder /usr/local/lib/python3.11/site-packages/ \
                    /usr/local/lib/python3.11/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# Delete old dist-info again in final stage to be sure
RUN find /usr/local/lib/python3.11/site-packages/ -maxdepth 1 -type d \( \
      -name "pip-*.dist-info" \
      -o -name "setuptools-*.dist-info" \
      -o -name "wheel-*.dist-info" \
    \) | grep -v "pip-25.3" | grep -v "setuptools-78" | grep -v "wheel-0.46" \
    | xargs -r rm -rf

# Final verification — print what's installed
RUN find /usr/local/lib/python3.11/site-packages/ -maxdepth 1 \
    -name "pip-*.dist-info" \
    -o -name "setuptools-*.dist-info" \
    -o -name "wheel-*.dist-info" \
    | sort

COPY app.py .

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

CMD ["python3", "app.py"]