# Use latest secure version - updated for deployment 2026-01-08
FROM mongo:8.0

# Copy initialization scripts
COPY *.js /docker-entrypoint-initdb.d/

# Set security context
USER mongodb

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD mongosh --eval "db.adminCommand('ping')" || exit 1

