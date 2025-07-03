# NATS Server Container for Cloudflare Containers
FROM nats:2.10-alpine

# Install additional tools for monitoring and debugging
RUN apk add --no-cache curl jq

# Copy NATS configuration
COPY nats-server.conf /etc/nats/nats-server.conf

# Create directories for persistence and logging
RUN mkdir -p /data/nats /var/log/nats

# Set proper permissions
RUN chown -R 1000:1000 /data/nats /var/log/nats

# Health check script
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Expose NATS ports
EXPOSE 4222 8222 6222

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD /usr/local/bin/healthcheck.sh

# Switch to non-root user
USER 1000:1000

# Start NATS server with configuration
CMD ["nats-server", "--config", "/etc/nats/nats-server.conf"]
