#!/bin/bash
# NATS server setup script for regional deployments
# Template variables: synadia_account, github_org, region

set -e

echo "🚀 Setting up regional NATS server"
echo "   Organization: ${github_org}"
echo "   Region: ${region}"
echo "   Synadia Account: ${synadia_account}"

# Update system
yum update -y
yum install -y wget curl

# Install NATS server
cd /tmp
wget https://github.com/nats-io/nats-server/releases/download/v2.10.7/nats-server-v2.10.7-linux-amd64.tar.gz
tar -xzf nats-server-v2.10.7-linux-amd64.tar.gz
mv nats-server-v2.10.7-linux-amd64/nats-server /usr/local/bin/
chmod +x /usr/local/bin/nats-server

# Install NATS CLI
wget https://github.com/nats-io/natscli/releases/download/v0.1.4/nats-0.1.4-linux-amd64.tar.gz
tar -xzf nats-0.1.4-linux-amd64.tar.gz
mv nats-0.1.4-linux-amd64/nats /usr/local/bin/
chmod +x /usr/local/bin/nats

# Create NATS configuration
mkdir -p /etc/nats
cat > /etc/nats/nats-server.conf << 'EOF'
# Regional NATS server configuration
server_name: regional-${region}
host: 0.0.0.0
port: 4222
http_port: 8222

# JetStream enabled
jetstream: {
  store_dir: "/var/lib/nats"
  max_memory_store: 1GB
  max_file_store: 10GB
}

# Connect to Synadia Cloud as leaf node
leaf {
  remotes: [
    {
      url: "nats-leaf://connect.ngs.global:7422"
      credentials: "/etc/nats/synadia.creds"
    }
  ]
}

# Cluster configuration for regional redundancy
cluster {
  name: regional-${region}
  host: 0.0.0.0
  port: 6222
  
  routes: [
    nats-route://127.0.0.1:6222
  ]
}

# Logging
log_file: "/var/log/nats/nats-server.log"
log_size_limit: 100MB
max_traced_msg_len: 32768

# Monitoring
system_account: SYS
EOF

# Create data directory
mkdir -p /var/lib/nats
mkdir -p /var/log/nats
chown -R nats:nats /var/lib/nats /var/log/nats

# Create nats user
useradd -r -s /bin/false nats || true

# Create systemd service
cat > /etc/systemd/system/nats-server.service << 'EOF'
[Unit]
Description=NATS Server
After=network.target

[Service]
Type=simple
User=nats
Group=nats
ExecStart=/usr/local/bin/nats-server -c /etc/nats/nats-server.conf
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Set up Synadia credentials (would be provided by parent NATS controller)
# In a real deployment, this would be securely injected
echo "# Synadia credentials would be configured here" > /etc/nats/synadia.creds

# Enable and start NATS server
systemctl daemon-reload
systemctl enable nats-server
systemctl start nats-server

# Install CloudWatch agent for monitoring
yum install -y amazon-cloudwatch-agent

# Configure CloudWatch monitoring
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "metrics": {
    "namespace": "NATS/Regional",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nats/nats-server.log",
            "log_group_name": "/aws/nats/regional-${region}",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Install GitHub webhook receiver (simple HTTP server)
cat > /usr/local/bin/github-webhook-receiver.py << 'EOF'
#!/usr/bin/env python3
import json
import asyncio
import nats
from aiohttp import web
import os

async def webhook_handler(request):
    """Handle GitHub webhooks and forward to NATS"""
    try:
        data = await request.json()
        
        # Connect to local NATS
        nc = await nats.connect("nats://localhost:4222")
        
        # Determine event type and subject
        event_type = request.headers.get('X-GitHub-Event', 'unknown')
        repo = data.get('repository', {}).get('name', 'unknown')
        
        subject = f"github.${github_org}.{repo}.{event_type}"
        
        # Publish to NATS
        await nc.publish(subject, json.dumps(data).encode())
        await nc.close()
        
        return web.Response(text="OK")
    except Exception as e:
        print(f"Error processing webhook: {e}")
        return web.Response(status=500, text=str(e))

async def main():
    app = web.Application()
    app.router.add_post('/webhook', webhook_handler)
    
    runner = web.AppRunner(app)
    await runner.setup()
    
    site = web.TCPSite(runner, '0.0.0.0', 8080)
    await site.start()
    
    print("GitHub webhook receiver started on port 8080")
    
    # Keep running
    while True:
        await asyncio.sleep(1)

if __name__ == '__main__':
    asyncio.run(main())
EOF

chmod +x /usr/local/bin/github-webhook-receiver.py

# Install Python dependencies
pip3 install aiohttp nats-py

echo "✅ Regional NATS server setup complete"
echo "   NATS server: localhost:4222"
echo "   HTTP monitoring: localhost:8222"
echo "   GitHub webhooks: localhost:8080/webhook"
