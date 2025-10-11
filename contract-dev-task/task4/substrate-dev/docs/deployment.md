# Deployment Guide

This guide covers deploying the Substrate Development blockchain in various environments, from local development to production networks.

## 🏗️ Build Configurations

### Development Build

For local development and testing:

```bash
# Quick development build
cargo build

# Run development node
./target/debug/substrate-dev --dev --tmp
```

### Release Build

For production deployment:

```bash
# Optimized release build
cargo build --release

# Build with specific features
cargo build --release --features runtime-benchmarks
```

### Docker Build

```dockerfile
# Dockerfile
FROM rust:1.70 as builder

WORKDIR /substrate-dev
COPY . .

# Install dependencies
RUN apt-get update && apt-get install -y \
    clang \
    libclang-dev \
    cmake \
    build-essential

# Add wasm target
RUN rustup target add wasm32-unknown-unknown

# Build the project
RUN cargo build --release

# Runtime stage
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /substrate-dev/target/release/substrate-dev /usr/local/bin/

EXPOSE 9933 9944 30333

ENTRYPOINT ["/usr/local/bin/substrate-dev"]
```

Build and run:

```bash
# Build Docker image
docker build -t substrate-dev:latest .

# Run container
docker run -p 9933:9933 -p 9944:9944 -p 30333:30333 \
  substrate-dev:latest --dev --unsafe-ws-external --unsafe-rpc-external
```

## 🌐 Network Configurations

### Local Development Network

Single node development setup:

```bash
./target/release/substrate-dev \
  --dev \
  --tmp \
  --ws-port 9944 \
  --rpc-port 9933 \
  --port 30333
```

### Local Test Network

Multi-node local network:

#### Node 1 (Alice)
```bash
./target/release/substrate-dev \
  --chain local \
  --alice \
  --node-key 0000000000000000000000000000000000000000000000000000000000000001 \
  --base-path /tmp/alice \
  --ws-port 9944 \
  --rpc-port 9933 \
  --port 30333 \
  --validator
```

#### Node 2 (Bob)
```bash
./target/release/substrate-dev \
  --chain local \
  --bob \
  --base-path /tmp/bob \
  --ws-port 9945 \
  --rpc-port 9934 \
  --port 30334 \
  --validator \
  --bootnodes /ip4/127.0.0.1/tcp/30333/p2p/12D3KooWEyoppNCUx8Yx66oV9fJnriXwCcXwDDUA2kj6vnc6iDEp
```

### Private Network

For private consortium networks:

1. **Generate Chain Specification**

```bash
# Generate raw chain spec
./target/release/substrate-dev build-spec --chain local > customSpec.json

# Convert to raw format
./target/release/substrate-dev build-spec --chain customSpec.json --raw > customSpecRaw.json
```

2. **Customize Chain Spec**

Edit `customSpec.json`:

```json
{
  "name": "Private Network",
  "id": "private_network",
  "chainType": "Live",
  "bootNodes": [],
  "telemetryEndpoints": null,
  "protocolId": "private",
  "properties": {
    "tokenDecimals": 12,
    "tokenSymbol": "PRIV"
  },
  "genesis": {
    "runtime": {
      "system": {
        "code": "0x..."
      },
      "balances": {
        "balances": [
          ["5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY", 1000000000000000],
          ["5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty", 1000000000000000]
        ]
      },
      "aura": {
        "authorities": [
          "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY",
          "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty"
        ]
      },
      "grandpa": {
        "authorities": [
          ["5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY", 1],
          ["5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty", 1]
        ]
      },
      "sudo": {
        "key": "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY"
      }
    }
  }
}
```

3. **Start Network Nodes**

```bash
# Validator 1
./target/release/substrate-dev \
  --chain customSpecRaw.json \
  --validator \
  --key-type aura \
  --key-type gran \
  --base-path /data/validator1 \
  --name "Validator-1"

# Validator 2
./target/release/substrate-dev \
  --chain customSpecRaw.json \
  --validator \
  --key-type aura \
  --key-type gran \
  --base-path /data/validator2 \
  --name "Validator-2" \
  --port 30334 \
  --ws-port 9945 \
  --rpc-port 9934
```

## ☁️ Cloud Deployment

### AWS Deployment

#### EC2 Instance Setup

1. **Launch EC2 Instance**
   - Instance type: t3.medium or larger
   - OS: Ubuntu 22.04 LTS
   - Storage: 100GB+ SSD
   - Security groups: Allow ports 22, 9933, 9944, 30333

2. **Install Dependencies**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install build dependencies
sudo apt install -y \
  build-essential \
  clang \
  libclang-dev \
  cmake \
  git \
  pkg-config \
  libssl-dev

# Add wasm target
rustup target add wasm32-unknown-unknown
```

3. **Deploy Application**

```bash
# Clone repository
git clone <your-repo-url>
cd substrate-dev

# Build release
cargo build --release

# Create systemd service
sudo tee /etc/systemd/system/substrate-dev.service > /dev/null <<EOF
[Unit]
Description=Substrate Development Node
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/substrate-dev
ExecStart=/home/ubuntu/substrate-dev/target/release/substrate-dev \\
  --chain local \\
  --validator \\
  --base-path /home/ubuntu/.substrate-dev \\
  --name "AWS-Node" \\
  --ws-external \\
  --rpc-external \\
  --rpc-cors all
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl enable substrate-dev
sudo systemctl start substrate-dev
```

#### Application Load Balancer

```yaml
# ALB configuration for multiple nodes
apiVersion: v1
kind: ConfigMap
metadata:
  name: substrate-alb-config
data:
  nginx.conf: |
    upstream substrate_rpc {
        server node1:9933;
        server node2:9933;
        server node3:9933;
    }
    
    upstream substrate_ws {
        server node1:9944;
        server node2:9944;
        server node3:9944;
    }
    
    server {
        listen 80;
        
        location /rpc {
            proxy_pass http://substrate_rpc;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location /ws {
            proxy_pass http://substrate_ws;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
```

### Google Cloud Platform

#### Compute Engine Deployment

```bash
# Create instance
gcloud compute instances create substrate-node \
  --image-family ubuntu-2204-lts \
  --image-project ubuntu-os-cloud \
  --machine-type e2-standard-4 \
  --boot-disk-size 100GB \
  --tags substrate-node

# Configure firewall
gcloud compute firewall-rules create substrate-ports \
  --allow tcp:9933,tcp:9944,tcp:30333 \
  --source-ranges 0.0.0.0/0 \
  --target-tags substrate-node
```

#### Kubernetes Deployment

```yaml
# substrate-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: substrate-dev
spec:
  replicas: 3
  selector:
    matchLabels:
      app: substrate-dev
  template:
    metadata:
      labels:
        app: substrate-dev
    spec:
      containers:
      - name: substrate-dev
        image: substrate-dev:latest
        ports:
        - containerPort: 9933
        - containerPort: 9944
        - containerPort: 30333
        args:
        - "--chain"
        - "local"
        - "--validator"
        - "--ws-external"
        - "--rpc-external"
        - "--rpc-cors"
        - "all"
        volumeMounts:
        - name: substrate-data
          mountPath: /data
      volumes:
      - name: substrate-data
        persistentVolumeClaim:
          claimName: substrate-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: substrate-service
spec:
  selector:
    app: substrate-dev
  ports:
  - name: rpc
    port: 9933
    targetPort: 9933
  - name: ws
    port: 9944
    targetPort: 9944
  - name: p2p
    port: 30333
    targetPort: 30333
  type: LoadBalancer

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: substrate-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
```

Deploy to GKE:

```bash
# Create cluster
gcloud container clusters create substrate-cluster \
  --num-nodes 3 \
  --machine-type e2-standard-4

# Deploy application
kubectl apply -f substrate-deployment.yaml

# Get external IP
kubectl get services substrate-service
```

### Digital Ocean

#### Droplet Deployment

```bash
# Create droplet using doctl
doctl compute droplet create substrate-node \
  --image ubuntu-22-04-x64 \
  --size s-4vcpu-8gb \
  --region nyc1 \
  --ssh-keys <your-ssh-key-id>

# Setup firewall
doctl compute firewall create substrate-fw \
  --inbound-rules protocol:tcp,ports:22,source_addresses:0.0.0.0/0 \
  --inbound-rules protocol:tcp,ports:9933,source_addresses:0.0.0.0/0 \
  --inbound-rules protocol:tcp,ports:9944,source_addresses:0.0.0.0/0 \
  --inbound-rules protocol:tcp,ports:30333,source_addresses:0.0.0.0/0
```

## 🔧 Configuration Management

### Environment Variables

```bash
# .env file
RUST_LOG=info
SUBSTRATE_CLI_IMPL_NAME=substrate-dev
SUBSTRATE_CLI_IMPL_VERSION=1.0.0

# Database configuration
DATABASE_PATH=/data/substrate-dev
DATABASE_CACHE_SIZE=1024

# Network configuration
NETWORK_LISTEN_ADDRESSES=/ip4/0.0.0.0/tcp/30333
NETWORK_PUBLIC_ADDRESSES=/ip4/YOUR_PUBLIC_IP/tcp/30333

# RPC configuration
RPC_LISTEN_ADDRESS=0.0.0.0:9933
WS_LISTEN_ADDRESS=0.0.0.0:9944
RPC_CORS=all

# Telemetry
TELEMETRY_URL=wss://telemetry.polkadot.io/submit/
```

### Configuration Files

```toml
# config.toml
[network]
listen_addresses = ["/ip4/0.0.0.0/tcp/30333"]
public_addresses = ["/ip4/YOUR_PUBLIC_IP/tcp/30333"]
reserved_nodes = []
non_reserved_mode = "Accept"

[rpc]
listen_address = "0.0.0.0:9933"
cors = ["*"]
methods = ["Safe", "Unsafe"]

[ws]
listen_address = "0.0.0.0:9944"
max_connections = 100

[database]
path = "/data/substrate-dev"
cache_size = 1024

[telemetry]
url = "wss://telemetry.polkadot.io/submit/"
verbosity = 0
```

## 📊 Monitoring and Logging

### Prometheus Metrics

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'substrate-dev'
    static_configs:
      - targets: ['localhost:9615']
    scrape_interval: 5s
    metrics_path: /metrics
```

Enable metrics in node:

```bash
./target/release/substrate-dev \
  --dev \
  --prometheus-external \
  --prometheus-port 9615
```

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "Substrate Development Node",
    "panels": [
      {
        "title": "Block Height",
        "type": "graph",
        "targets": [
          {
            "expr": "substrate_block_height{instance=\"localhost:9615\"}",
            "legendFormat": "Block Height"
          }
        ]
      },
      {
        "title": "Peer Count",
        "type": "graph",
        "targets": [
          {
            "expr": "substrate_sub_libp2p_peers_count{instance=\"localhost:9615\"}",
            "legendFormat": "Peers"
          }
        ]
      }
    ]
  }
}
```

### Log Aggregation

```yaml
# docker-compose.yml for ELK stack
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.5.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"

  logstash:
    image: docker.elastic.co/logstash/logstash:8.5.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "5044:5044"

  kibana:
    image: docker.elastic.co/kibana/kibana:8.5.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200

  substrate-dev:
    image: substrate-dev:latest
    command: >
      --dev
      --log json
    depends_on:
      - logstash
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 🔒 Security Considerations

### Network Security

1. **Firewall Configuration**
```bash
# UFW firewall rules
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 9933/tcp  # RPC (restrict to trusted IPs in production)
sudo ufw allow 9944/tcp  # WebSocket (restrict to trusted IPs in production)
sudo ufw allow 30333/tcp # P2P
sudo ufw enable
```

2. **SSL/TLS Termination**
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location /rpc {
        proxy_pass http://localhost:9933;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /ws {
        proxy_pass http://localhost:9944;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

### Key Management

1. **Hardware Security Modules (HSM)**
```bash
# Generate keys using HSM
./target/release/substrate-dev key generate \
  --scheme sr25519 \
  --output-type json \
  --password-interactive
```

2. **Key Rotation**
```bash
# Rotate session keys
curl -H "Content-Type: application/json" \
     -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' \
     http://localhost:9933
```

## 🚀 Performance Optimization

### Database Optimization

```bash
# Use faster database backend
./target/release/substrate-dev \
  --dev \
  --database rocksdb \
  --db-cache 2048 \
  --state-cache-size 1073741824
```

### Runtime Optimization

```bash
# Build with optimizations
RUSTFLAGS="-C target-cpu=native" cargo build --release

# Enable specific features
cargo build --release --features runtime-benchmarks,try-runtime
```

### Network Optimization

```bash
# Optimize network settings
./target/release/substrate-dev \
  --dev \
  --max-runtime-instances 8 \
  --runtime-cache-size 64 \
  --in-peers 50 \
  --out-peers 50
```

## 🔄 Backup and Recovery

### Database Backup

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backup/substrate-dev"
DATA_DIR="/data/substrate-dev"
DATE=$(date +%Y%m%d_%H%M%S)

# Stop node
sudo systemctl stop substrate-dev

# Create backup
tar -czf "$BACKUP_DIR/substrate-backup-$DATE.tar.gz" -C "$DATA_DIR" .

# Start node
sudo systemctl start substrate-dev

# Cleanup old backups (keep last 7 days)
find "$BACKUP_DIR" -name "substrate-backup-*.tar.gz" -mtime +7 -delete
```

### Recovery Process

```bash
#!/bin/bash
# restore.sh

BACKUP_FILE="$1"
DATA_DIR="/data/substrate-dev"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup-file>"
    exit 1
fi

# Stop node
sudo systemctl stop substrate-dev

# Backup current data
mv "$DATA_DIR" "$DATA_DIR.backup.$(date +%Y%m%d_%H%M%S)"

# Restore from backup
mkdir -p "$DATA_DIR"
tar -xzf "$BACKUP_FILE" -C "$DATA_DIR"

# Start node
sudo systemctl start substrate-dev
```

This deployment guide provides comprehensive instructions for deploying the Substrate Development blockchain across various environments and platforms. Choose the deployment method that best fits your requirements and infrastructure.