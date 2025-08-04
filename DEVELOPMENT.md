# DEPLOYMENT.md - SEO Intelligence Platform

## Deployment Guide for Self-Hosted Enterprise Environment

This document provides comprehensive deployment instructions for the Family Dental Centres SEO Intelligence Platform, optimized for self-hosted enterprise environments with high availability and security requirements.

## 📋 Pre-Deployment Checklist

### Hardware Requirements Verification
```bash
# Verify system specifications
echo "=== System Specification Check ==="
echo "CPU Cores: $(nproc)"
echo "RAM: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "Storage: $(df -h / | tail -1 | awk '{print $2}')"
echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null || echo 'No GPU detected')"
echo "Network: $(ip route get 8.8.8.8 | grep -oP 'src \K\S+')"

# Minimum requirements check
claude-code verify-hardware-requirements \
  --cpu-cores=8 \
  --ram=32GB \
  --storage=1TB \
  --network=1Gbps
```

### Software Prerequisites
```bash
# Install required system packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  curl \
  wget \
  git \
  build-essential \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install NVIDIA drivers (if GPU present)
sudo apt install -y nvidia-driver-535 nvidia-container-toolkit
sudo systemctl restart docker
```

## 🏗️ Environment Setup

### 1. Directory Structure Creation
```bash
# Create project directory structure
claude-code create-deployment-structure \
  --project-name=seo-intelligence-platform \
  --environment=production \
  --backup-strategy=automated

# Generated structure:
mkdir -p /opt/seo-platform/{
  app,
  data/{postgresql,redis,logs,backups},
  config/{nginx,ssl,monitoring},
  scripts/{deployment,maintenance,backup}
}
```

### 2. SSL Certificate Setup
```bash
# Install and configure Let's Encrypt
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot

# Generate SSL certificates for all domains
claude-code setup-ssl-certificates \
  --domains=seo.familydentalcentres.com,api.familydentalcentres.com \
  --method=letsencrypt \
  --auto-renewal=true

# Configure SSL renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

### 3. Environment Configuration
```bash
# Generate production environment file
claude-code generate-production-env \
  --database-url="postgresql://seo_user:${DB_PASSWORD}@localhost:5432/seo_platform" \
  --redis-url="redis://localhost:6379" \
  --openai-api-key="${OPENAI_API_KEY}" \
  --gemini-api-key="${GEMINI_API_KEY}" \
  --jwt-secret="${JWT_SECRET}" \
  --encryption-key="${ENCRYPTION_KEY}"

# Example .env.production
cat > /opt/seo-platform/config/.env.production << 'EOF'
# Environment
NODE_ENV=production
PORT=3000
HOST=0.0.0.0

# Database Configuration
DATABASE_URL=postgresql://seo_user:${DB_PASSWORD}@localhost:5432/seo_platform
DATABASE_POOL_MIN=5
DATABASE_POOL_MAX=20
DATABASE_IDLE_TIMEOUT=30000

# Redis Configuration
REDIS_URL=redis://localhost:6379
REDIS_TTL_DEFAULT=3600
REDIS_TTL_CACHE=7200

# AI API Configuration
OPENAI_API_KEY=${OPENAI_API_KEY}
OPENAI_MODEL=gpt-4-turbo
OPENAI_MAX_TOKENS=4000
GEMINI_API_KEY=${GEMINI_API_KEY}
GEMINI_MODEL=gemini-pro

# Security Configuration
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRATION=1h
JWT_REFRESH_EXPIRATION=7d
ENCRYPTION_KEY=${ENCRYPTION_KEY}
ENCRYPTION_ALGORITHM=aes-256-gcm

# Scraping Configuration
PROXY_LIST=${PROXY_LIST}
USER_AGENT_ROTATION=true
SCRAPING_DELAY_MIN=1000
SCRAPING_DELAY_MAX=5000
CAPTCHA_SERVICE_KEY=${CAPTCHA_SERVICE_KEY}

# Monitoring Configuration
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001
LOG_LEVEL=info
LOG_FORMAT=json

# Email Configuration
SMTP_HOST=${SMTP_HOST}
SMTP_PORT=${SMTP_PORT}
SMTP_USER=${SMTP_USER}
SMTP_PASS=${SMTP_PASS}

# Backup Configuration
BACKUP_SCHEDULE="0 2 * * *"
BACKUP_RETENTION_DAYS=30
BACKUP_S3_BUCKET=${BACKUP_S3_BUCKET}
BACKUP_S3_KEY=${BACKUP_S3_KEY}
BACKUP_S3_SECRET=${BACKUP_S3_SECRET}
EOF
```

## 🗄️ Database Deployment

### PostgreSQL Setup
```bash
# Install PostgreSQL 15
sudo apt install -y postgresql-15 postgresql-contrib-15 postgresql-15-postgis-3

# Configure PostgreSQL for production
claude-code configure-postgresql-production \
  --version=15 \
  --performance=seo-workload \
  --memory=32GB \
  --storage=ssd

# Create database and user
sudo -u postgres psql << 'EOF'
CREATE USER seo_user WITH PASSWORD '${DB_PASSWORD}';
CREATE DATABASE seo_platform OWNER seo_user;
GRANT ALL PRIVILEGES ON DATABASE seo_platform TO seo_user;

-- Install extensions
\c seo_platform
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "postgis";
EOF

# Optimize PostgreSQL configuration
cat > /etc/postgresql/15/main/conf.d/seo-platform.conf << 'EOF'
# Performance Tuning for SEO Platform
shared_buffers = 8GB
effective_cache_size = 24GB
maintenance_work_mem = 2GB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 64MB
min_wal_size = 1GB
max_wal_size = 4GB
max_worker_processes = 16
max_parallel_workers_per_gather = 4
max_parallel_workers = 16
max_parallel_maintenance_workers = 4
EOF

sudo systemctl restart postgresql
```

### Redis Setup
```bash
# Install Redis 7
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
sudo apt update && sudo apt install -y redis

# Configure Redis for production
cat > /etc/redis/redis.conf << 'EOF'
# Redis Configuration for SEO Platform
bind 127.0.0.1
port 6379
timeout 0
keepalive 60
maxmemory 8gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
rdbcompression yes
rdbchecksum yes
dbfilename seo-platform.rdb
dir /var/lib/redis
appendonly yes
appendfsync everysec
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
EOF

sudo systemctl restart redis-server
sudo systemctl enable redis-server
```

## 🐳 Container Deployment

### Docker Compose Configuration
```bash
# Create production docker-compose.yml
claude-code generate-docker-compose \
  --environment=production \
  --services=api,frontend,scraper,ai-processor \
  --networking=internal \
  --volumes=persistent

cat > /opt/seo-platform/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Main API Service
  api:
    build:
      context: ./backend
      dockerfile: Dockerfile.production
    container_name: seo-api
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    env_file:
      - ./config/.env.production
    volumes:
      - ./data/logs:/app/logs
      - ./data/uploads:/app/uploads
    depends_on:
      - postgresql
      - redis
    networks:
      - seo-internal
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G

  # Frontend Service
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.production
    container_name: seo-frontend
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./config/nginx:/etc/nginx/conf.d
      - ./config/ssl:/etc/ssl/certs
      - ./data/logs/nginx:/var/log/nginx
    depends_on:
      - api
    networks:
      - seo-internal
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G

  # Web Scraping Service
  scraper:
    build:
      context: ./scraper
      dockerfile: Dockerfile.production
    container_name: seo-scraper
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - SCRAPER_WORKERS=4
    env_file:
      - ./config/.env.production
    volumes:
      - ./data/logs:/app/logs
      - ./data/scraper-cache:/app/cache
    depends_on:
      - postgresql
      - redis
    networks:
      - seo-internal
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 8G
        reservations:
          cpus: '2.0'
          memory: 4G

  # AI Processing Service
  ai-processor:
    build:
      context: ./ai-services
      dockerfile: Dockerfile.production
    container_name: seo-ai-processor
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - GPU_ENABLED=true
    env_file:
      - ./config/.env.production
    volumes:
      - ./data/ai-models:/app/models
      - ./data/logs:/app/logs
    depends_on:
      - postgresql
      - redis
    networks:
      - seo-internal
    runtime: nvidia
    deploy:
      resources:
        limits:
          cpus: '8.0'
          memory: 16G
        reservations:
          cpus: '4.0'
          memory: 8G

  # PostgreSQL Database
  postgresql:
    image: postgres:15-alpine
    container_name: seo-postgresql
    restart: unless-stopped
    environment:
      - POSTGRES_DB=seo_platform
      - POSTGRES_USER=seo_user
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./data/postgresql:/var/lib/postgresql/data
      - ./scripts/db-init:/docker-entrypoint-initdb.d
    ports:
      - "127.0.0.1:5432:5432"
    networks:
      - seo-internal
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 8G
        reservations:
          cpus: '2.0'
          memory: 4G

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: seo-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --maxmemory 4gb --maxmemory-policy allkeys-lru
    volumes:
      - ./data/redis:/data
    ports:
      - "127.0.0.1:6379:6379"
    networks:
      - seo-internal
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G

  # Monitoring Stack
  prometheus:
    image: prom/prometheus:latest
    container_name: seo-prometheus
    restart: unless-stopped
    ports:
      - "127.0.0.1:9090:9090"
    volumes:
      - ./config/prometheus:/etc/prometheus
      - ./data/prometheus:/prometheus
    networks:
      - seo-internal

  grafana:
    image: grafana/grafana:latest
    container_name: seo-grafana
    restart: unless-stopped
    ports:
      - "127.0.0.1:3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    volumes:
      - ./data/grafana:/var/lib/grafana
      - ./config/grafana:/etc/grafana/provisioning
    networks:
      - seo-internal

networks:
  seo-internal:
    driver: bridge

volumes:
  postgresql-data:
  redis-data:
  grafana-data:
  prometheus-data:
EOF
```

### Nginx Configuration
```bash
# Create Nginx configuration for reverse proxy
cat > /opt/seo-platform/config/nginx/default.conf << 'EOF'
# SEO Platform Nginx Configuration

# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=scraper:10m rate=1r/s;

# Upstream servers
upstream api_backend {
    least_conn;
    server api:3000 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

upstream websocket_backend {
    ip_hash;
    server api:3000;
}

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name seo.familydentalcentres.com api.familydentalcentres.com;
    return 301 https://$server_name$request_uri;
}

# Main HTTPS server
server {
    listen 443 ssl http2;
    server_name seo.familydentalcentres.com;

    # SSL Configuration
    ssl_certificate /etc/ssl/certs/fullchain.pem;
    ssl_certificate_key /etc/ssl/certs/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20:!aNULL:!MD5:!DSS;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' wss:; font-src 'self' data:;" always;

    # Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Static files caching
    location /static/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri $uri/ =404;
    }

    # Frontend application
    location / {
        try_files $uri $uri/ /index.html;
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # API endpoints
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 10s;
        proxy_send_timeout 300s;
    }

    # WebSocket connections
    location /socket.io/ {
        proxy_pass http://websocket_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }

    # Health check endpoint
    location /health {
        access_log off;
        proxy_pass http://api_backend/health;
        proxy_read_timeout 5s;
        proxy_connect_timeout 5s;
    }
}

# API subdomain
server {
    listen 443 ssl http2;
    server_name api.familydentalcentres.com;

    # SSL Configuration (same as above)
    ssl_certificate /etc/ssl/certs/fullchain.pem;
    ssl_certificate_key /etc/ssl/certs/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20:!aNULL:!MD5:!DSS;

    # API-specific rate limiting
    location / {
        limit_req zone=api burst=50 nodelay;
        
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
    }
}
EOF
```

## 🚀 Application Deployment

### Build and Deploy
```bash
# Clone the repository
cd /opt/seo-platform
git clone https://github.com/family-dental-centres/seo-intelligence-platform.git app
cd app

# Build the application
claude-code build-production \
  --optimize=true \
  --minify=true \
  --bundle-analysis=true

# Run database migrations
claude-code run-migrations \
  --environment=production \
  --verify-schemas=true

# Seed initial data
claude-code seed-database \
  --clinics-data=./config/clinics.json \
  --keywords-data=./config/keywords.json \
  --competitors-data=./config/competitors.json

# Deploy containers
docker-compose up -d --build

# Verify deployment
claude-code verify-deployment \
  --health-checks=all \
  --performance-tests=basic \
  --security-scan=true
```

### Service Configuration
```bash
# Create systemd service for container management
cat > /etc/systemd/system/seo-platform.service << 'EOF'
[Unit]
Description=SEO Intelligence Platform
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/opt/seo-platform
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable seo-platform.service
sudo systemctl start seo-platform.service
```

## 🔍 Monitoring Setup

### Prometheus Configuration
```bash
# Create Prometheus configuration
cat > /opt/seo-platform/config/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'seo-api'
    static_configs:
      - targets: ['api:3000']
    metrics_path: '/metrics'
    scrape_interval: 10s

  - job_name: 'seo-scraper'
    static_configs:
      - targets: ['scraper:3001']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'seo-ai-processor'
    static_configs:
      - targets: ['ai-processor:3002']
    metrics_path: '/metrics'
    scrape_interval: 15s

  - job_name: 'postgresql'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
EOF

# Create alerting rules
mkdir -p /opt/seo-platform/config/prometheus/rules
cat > /opt/seo-platform/config/prometheus/rules/seo-platform.yml << 'EOF'
groups:
  - name: seo-platform.rules
    rules:
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.90
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 90% for more than 2 minutes"

      - alert: HighCPUUsage
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% for more than 5 minutes"

      - alert: APIHighLatency
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="seo-api"}[5m])) > 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "API high latency detected"
          description: "95th percentile latency is above 1 second"

      - alert: ScrapingJobFailures
        expr: rate(scraping_jobs_failed_total[5m]) > 0.1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "High scraping job failure rate"
          description: "Scraping job failure rate is above 10%"

      - alert: DatabaseConnectionIssues
        expr: postgresql_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL is down"
          description: "PostgreSQL database is not responding"
EOF
```

### Grafana Dashboard Setup
```bash
# Create Grafana provisioning configuration
mkdir -p /opt/seo-platform/config/grafana/provisioning/{datasources,dashboards}

cat > /opt/seo-platform/config/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

cat > /opt/seo-platform/config/grafana/provisioning/dashboards/seo-platform.yml << 'EOF'
apiVersion: 1
providers:
  - name: 'seo-platform'
    type: file
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

# Import pre-built dashboards
claude-code import-grafana-dashboards \
  --source=./config/grafana/dashboards \
  --dashboards=seo-overview,technical-metrics,business-kpis,system-health
```

## 🔐 Security Hardening

### Firewall Configuration
```bash
# Configure UFW firewall
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (change port if needed)
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow internal monitoring (localhost only)
sudo ufw allow from 127.0.0.1 to any port 9090  # Prometheus
sudo ufw allow from 127.0.0.1 to any port 3001  # Grafana
sudo ufw allow from 127.0.0.1 to any port 5432  # PostgreSQL
sudo ufw allow from 127.0.0.1 to any port 6379  # Redis

sudo ufw --force enable
```

### Security Scanning Setup
```bash
# Install and configure fail2ban
sudo apt install -y fail2ban

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true

[nginx-http-auth]
enabled = true

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
action = iptables-multiport[name=ReqLimit, port="http,https", protocol=tcp]
logpath = /opt/seo-platform/data/logs/nginx/error.log
maxretry = 10
findtime = 600
bantime = 7200
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Setup automated security updates
sudo apt install -y unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "false";' >> /etc/apt/apt.conf.d/50unattended-upgrades
```

## 📦 Backup Strategy

### Automated Backup Setup
```bash
# Create backup scripts
claude-code create-backup-scripts \
  --database=postgresql \
  --redis=true \
  --files=application-data \
  --retention=30days \
  --encryption=true

# Example backup script
cat > /opt/seo-platform/scripts/backup/backup.sh << 'EOF'
#!/bin/bash
set -e

BACKUP_DIR="/opt/seo-platform/data/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p $BACKUP_DIR/$DATE

# Database backup
echo "Backing up PostgreSQL..."
docker exec seo-postgresql pg_dump -U seo_user seo_platform | gzip > $BACKUP_DIR/$DATE/database.sql.gz

# Redis backup
echo "Backing up Redis..."
docker exec seo-redis redis-cli BGSAVE
docker cp seo-redis:/data/dump.rdb $BACKUP_DIR/$DATE/redis.rdb

# Application data backup
echo "Backing up application data..."
tar -czf $BACKUP_DIR/$DATE/app_data.tar.gz /opt/seo-platform/data/uploads /opt/seo-platform/data/logs

# Encrypt backup
echo "Encrypting backup..."
tar -czf - $BACKUP_DIR/$DATE | gpg --symmetric --cipher-algo AES256 --output $BACKUP_DIR/$DATE.tar.gz.gpg
rm -rf $BACKUP_DIR/$DATE

# Upload to S3 (if configured)
if [ ! -z "$BACKUP_S3_BUCKET" ]; then
  aws s3 cp $BACKUP_DIR/$DATE.tar.gz.gpg s3://$BACKUP_S3_BUCKET/backups/
fi

# Clean old backups
find $BACKUP_DIR -name "*.tar.gz.gpg" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/seo-platform/scripts/backup/backup.sh

# Schedule backups
echo "0 2 * * * /opt/seo-platform/scripts/backup/backup.sh" | crontab -
```

## 🔧 Maintenance Procedures

### Health Checks
```bash
# Create health check script
cat > /opt/seo-platform/scripts/maintenance/health-check.sh << 'EOF'
#!/bin/bash

echo "=== SEO Platform Health Check ==="
echo "Date: $(date)"
echo

# Check Docker containers
echo "Docker Container Status:"
docker-compose ps

# Check database connectivity
echo -e "\nDatabase Status:"
docker exec seo-postgresql pg_isready -U seo_user -d seo_platform

# Check Redis connectivity
echo -e "\nRedis Status:"
docker exec seo-redis redis-cli ping

# Check API health
echo -e "\nAPI Health:"
curl -f http://localhost/health || echo "API health check failed"

# Check disk usage
echo -e "\nDisk Usage:"
df -h /opt/seo-platform

# Check memory usage
echo -e "\nMemory Usage:"
free -h

# Check CPU usage
echo -e "\nCPU Usage:"
top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'

echo -e "\n=== Health Check Complete ==="
EOF

chmod +x /opt/seo-platform/scripts/maintenance/health-check.sh
```

### Update Procedures
```bash
# Create update script
cat > /opt/seo-platform/scripts/maintenance/update.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting SEO Platform update..."

# Backup before update
/opt/seo-platform/scripts/backup/backup.sh

# Pull latest code
cd /opt/seo-platform/app
git fetch origin
git checkout main
git pull origin main

# Update dependencies
npm ci --production

# Run database migrations
claude-code run-migrations --environment=production

# Rebuild and restart containers
docker-compose build --no-cache
docker-compose up -d

# Wait for services to be ready
sleep 30

# Run health checks
/opt/seo-platform/scripts/maintenance/health-check.sh

echo "Update completed successfully!"
EOF

chmod +x /opt/seo-platform/scripts/maintenance/update.sh
```

## 📊 Performance Optimization

### Database Optimization
```bash
# Create database maintenance script
cat > /opt/seo-platform/scripts/maintenance/db-maintenance.sh << 'EOF'
#!/bin/bash

echo "Running database maintenance..."

# Vacuum and analyze
docker exec seo-postgresql psql -U seo_user -d seo_platform -c "VACUUM ANALYZE;"

# Update statistics
docker exec seo-postgresql psql -U seo_user -d seo_platform -c "SELECT pg_stat_reset();"

# Check for unused indexes
docker exec seo-postgresql psql -U seo_user -d seo_platform -c "
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE idx_tup_read = 0 AND idx_tup_fetch = 0
ORDER BY schemaname, tablename, indexname;"

echo "Database maintenance completed."
EOF

chmod +x /opt/seo-platform/scripts/maintenance/db-maintenance.sh

# Schedule database maintenance
echo "0 3 * * 0 /opt/seo-platform/scripts/maintenance/db-maintenance.sh" | crontab -
```

## 🚨 Troubleshooting Guide

### Common Issues and Solutions

#### Container Issues
```bash
# Check container logs
docker-compose logs -f [service_name]

# Restart specific service
docker-compose restart [service_name]

# Rebuild and restart all services
docker-compose down
docker-compose up -d --build
```

#### Database Issues
```bash
# Check database connections
docker exec seo-postgresql psql -U seo_user -d seo_platform -c "SELECT count(*) FROM pg_stat_activity;"

# Check database locks
docker exec seo-postgresql psql -U seo_user -d seo_platform -c "SELECT * FROM pg_locks WHERE NOT granted;"

# Check slow queries
docker exec seo-postgresql psql -U seo_user -d seo_platform -c "SELECT query, calls, total_time, mean_time FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

#### Performance Issues
```bash
# Check resource usage
docker stats

# Check API response times
curl -w "@curl-format.txt" -o /dev/null -s "http://localhost/api/health"

# Monitor real-time metrics
watch -n 1 'docker exec seo-postgresql psql -U seo_user -d seo_platform -c "SELECT count(*) as active_connections FROM pg_stat_activity WHERE state = '\''active'\'';"'
```

## 🎯 Post-Deployment Verification

### Verification Checklist
```bash
# Run comprehensive verification
claude-code verify-production-deployment \
  --database-connectivity=true \
  --api-endpoints=all \
  --websocket-connections=true \
  --scraping-engines=true \
  --ai-services=true \
  --monitoring-stack=true \
  --backup-systems=true \
  --security-configuration=true

# Performance benchmarks
claude-code run-performance-tests \
  --load-test=moderate \
  --duration=300s \
  --concurrent-users=50

# Security scan
claude-code security-scan \
  --vulnerability-assessment=true \
  --penetration-testing=basic \
  --compliance-check=true
```

## 📞 Support and Maintenance

### Maintenance Schedule
- **Daily**: Automated backups, health checks
- **Weekly**: Database maintenance, log rotation
- **Monthly**: Security updates, performance analysis
- **Quarterly**: Full system review, capacity planning

### Emergency Contacts
- **System Administrator**: [contact information]
- **Database Administrator**: [contact information]
- **Security Team**: [contact information]
- **Development Team**: [contact information]

### Documentation Updates
- Keep deployment documentation current
- Update runbooks after system changes
- Maintain incident response procedures
- Document all customizations and configurations

---

*This deployment guide provides comprehensive instructions for setting