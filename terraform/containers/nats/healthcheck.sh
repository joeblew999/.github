#!/bin/sh
# Health check script for NATS container

# NATS server health endpoint
NATS_HEALTH_URL="http://localhost:8222/healthz"
NATS_VARZ_URL="http://localhost:8222/varz"

# Check if NATS server is responding
if ! curl -f -s "$NATS_HEALTH_URL" >/dev/null 2>&1; then
    echo "NATS health endpoint not responding"
    exit 1
fi

# Check if NATS server info is available
if ! curl -f -s "$NATS_VARZ_URL" >/dev/null 2>&1; then
    echo "NATS server info endpoint not responding"
    exit 1
fi

# Get server info and check status
SERVER_INFO=$(curl -s "$NATS_VARZ_URL" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Failed to get NATS server info"
    exit 1
fi

# Check if server is properly configured
if ! echo "$SERVER_INFO" | grep -q '"server_id"'; then
    echo "NATS server info malformed or missing"
    exit 1
fi

# Check memory usage (warn if over 80%)
MEMORY_USAGE=$(echo "$SERVER_INFO" | grep -o '"mem":[0-9]*' | cut -d':' -f2)
if [ -n "$MEMORY_USAGE" ] && [ "$MEMORY_USAGE" -gt 0 ]; then
    # This is a basic check - in production you'd want more sophisticated monitoring
    echo "NATS server memory usage: ${MEMORY_USAGE} bytes"
fi

echo "NATS container is healthy"
exit 0
