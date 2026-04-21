# ─── Stage 1: Builder ───────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

# Copy only requirements first (Docker layer cache)
# If requirements.txt unchanged → this layer is cached
# saves rebuild time on every push
COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ─── Stage 2: Final image ───────────────────────────
FROM python:3.11-slim

WORKDIR /app

# Create non-root user → security best practice
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages/ \
                    /usr/local/lib/python3.11/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# Copy only app code — not tests, not .git, not cache
COPY app.py .

# Own files as non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root
USER appuser

EXPOSE 8080

CMD ["python3", "app.py"]