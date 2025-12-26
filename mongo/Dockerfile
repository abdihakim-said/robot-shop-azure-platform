# Use specific secure version instead of latest
FROM mongo:7.0.5

# Copy initialization scripts
COPY *.js /docker-entrypoint-initdb.d/

# Set security context
USER mongodb

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD mongo --eval "db.adminCommand('ping')" || exit 1

