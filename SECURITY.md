# SECURITY.md - Security Guidelines

## Security Overview

This document outlines comprehensive security guidelines for the Family Dental Centres SEO Intelligence Platform, covering data protection, access controls, infrastructure security, and compliance requirements.

## 🔐 Authentication & Authorization

### Multi-Factor Authentication (MFA)
```bash
# Enable MFA for all user accounts
claude-code setup-mfa \
  --methods=totp,sms,email \
  --backup-codes=true \
  --enforcement=mandatory

# Configure MFA settings
cat > /opt/seo-platform/config/mfa.json << 'EOF'
{
  "enabled": true,
  "methods": {
    "totp": {
      "enabled": true,
      "issuer": "Family Dental Centres SEO",
      "window": 30,
      "recovery_codes": 10
    },
    "sms": {
      "enabled": true,
      "provider": "twilio",
      "rate_limit": "5_per_hour"
    },
    "email": {
      "enabled": true,
      "rate_limit": "3_per_hour"
    }
  },
  "enforcement": {
    "admin_users": "mandatory",
    "regular_users": "optional",
    "api_access": "recommended"
  }
}
EOF
```

### Role-Based Access Control (RBAC)
```typescript
interface SecurityRoles {
  superAdmin: {
    permissions: [
      'system:manage',
      'users:create,read,update,delete',
      'clinics:create,read,update,delete',
      'data:export,import,delete',
      'security:configure,audit'
    ];
    restrictions: [];
  };
  orgAdmin: {
    permissions: [
      'org:manage',
      'clinics:create,read,update',
      'users:create,read,update',
      'reports:generate,schedule',
      'data:export'
    ];
    restrictions: ['own_organization_only'];
  };
  clinicManager: {
    permissions: [
      'clinic:read,update',
      'rankings:read',
      'competitors:read,create',
      'reports:generate',
      'alerts:configure'
    ];
    restrictions: ['assigned_clinics_only'];
  };
  analyst: {
    permissions: [
      'clinic:read',
      'rankings:read',
      'competitors:read',
      'reports:read',
      'insights:read'
    ];
    restrictions: ['read_only', 'assigned_clinics_only'];
  };
  viewer: {
    permissions: [
      'dashboard:read',
      'reports:read'
    ];
    restrictions: ['read_only', 'summary_data_only'];
  };
}
```

### API Key Management
```bash
# Generate secure API keys
claude-code generate-api-keys \
  --algorithm=sha256 \
  --length=64 \
  --rotation=90d \
  --scoping=clinic-specific

# API key configuration
cat > /opt/seo-platform/config/api-keys.json << 'EOF'
{
  "key_format": "sk_live_[64_random_chars]",
  "expiration": {
    "default": "1y",
    "high_privilege": "90d",
    "read_only": "2y"
  },
  "rotation": {
    "automatic": true,
    "warning_days": 30,
    "grace_period": 7
  },
  "restrictions": {
    "ip_whitelist": true,
    "rate_limiting": true,
    "scope_limiting": true
  },
  "monitoring": {
    "usage_tracking": true,
    "anomaly_detection": true,
    "breach_detection": true
  }
}
EOF
```

## 🛡️ Data Protection

### Encryption Standards

#### Data at Rest
```bash
# Setup database encryption
claude-code setup-database-encryption \
  --algorithm=AES-256 \
  --key-management=vault \
  --field-level=pii \
  --backup-encryption=true

# Configure PostgreSQL encryption
cat > /etc/postgresql/15/main/conf.d/encryption.conf << 'EOF'
# Transparent Data Encryption
ssl = on
ssl_cert_file = '/etc/ssl/certs/server.crt'
ssl_key_file = '/etc/ssl/private/server.key'
ssl_ca_file = '/etc/ssl/certs/ca.crt'

# Password encryption
password_encryption = scram-sha-256

# Log encryption
log_statement = 'none'
log_min_duration_statement = -1

# Data encryption at rest
shared_preload_libraries = 'pg_tde'
EOF
```

#### Data in Transit
```nginx
# Nginx SSL Configuration
server {
    listen 443 ssl http2;
    
    # SSL Certificate Configuration
    ssl_certificate /etc/ssl/certs/fullchain.pem;
    ssl_certificate_key /etc/ssl/private/privkey.pem;
    
    # SSL Security Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # SSL Session Configuration
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/ssl/certs/chain.pem;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    
    # Perfect Forward Secrecy
    ssl_dhparam /etc/ssl/certs/dhparam.pem;
}
```

### Field-Level Encryption
```typescript
// Sensitive data encryption
class DataEncryption {
  private encryptionKey: string;
  private algorithm = 'aes-256-gcm';
  
  constructor(key: string) {
    this.encryptionKey = key;
  }
  
  encryptField(data: string): EncryptedField {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipher(this.algorithm, this.encryptionKey);
    cipher.setAAD(Buffer.from('seo-platform'));
    
    let encrypted = cipher.update(data, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const authTag = cipher.getAuthTag();
    
    return {
      value: encrypted,
      iv: iv.toString('hex'),
      authTag: authTag.toString('hex'),
      algorithm: this.algorithm
    };
  }
  
  decryptField(encryptedData: EncryptedField): string {
    const decipher = crypto.createDecipher(
      encryptedData.algorithm,
      this.encryptionKey
    );
    
    decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'hex'));
    decipher.setAAD(Buffer.from('seo-platform'));
    
    let decrypted = decipher.update(encryptedData.value, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  }
}

// Usage for PII data
const encryption = new DataEncryption(process.env.ENCRYPTION_KEY);

const encryptedPhone = encryption.encryptField('+1-604-555-0123');
const encryptedEmail = encryption.encryptField('patient@example.com');
```

### Data Masking
```sql
-- Create data masking functions
CREATE OR REPLACE FUNCTION mask_phone(phone_number TEXT)
RETURNS TEXT AS $$
BEGIN
  IF phone_number IS NULL THEN
    RETURN NULL;
  END IF;
  
  RETURN REGEXP_REPLACE(phone_number, '\d(?=\d{4})', '*', 'g');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mask_email(email TEXT)
RETURNS TEXT AS $$
BEGIN
  IF email IS NULL THEN
    RETURN NULL;
  END IF;
  
  RETURN REGEXP_REPLACE(email, '(?<=.{2}).(?=.*@)', '*', 'g');
END;
$$ LANGUAGE plpgsql;

-- Create secure views for non-admin users
CREATE VIEW clinics_secure AS
SELECT 
  id,
  organization_id,
  name,
  domain,
  location,
  CASE 
    WHEN current_user_role() IN ('admin', 'superadmin') THEN nap_data
    ELSE jsonb_set(
      jsonb_set(nap_data, '{phone}', to_jsonb(mask_phone(nap_data->>'phone'))),
      '{email}', to_jsonb(mask_email(nap_data->>'email'))
    )
  END AS nap_data,
  services,
  status,
  created_at,
  updated_at
FROM clinics;
```

## 🔒 Infrastructure Security

### Network Security
```bash
# Configure advanced firewall rules
claude-code setup-advanced-firewall \
  --provider=ufw \
  --default-deny=true \
  --geo-blocking=true \
  --ddos-protection=true

# Detailed firewall configuration
cat > /opt/seo-platform/scripts/security/firewall-config.sh << 'EOF'
#!/bin/bash

# Reset UFW
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# SSH access (restrict to management network)
ufw allow from 192.168.1.0/24 to any port 22

# HTTP/HTTPS (with rate limiting)
ufw allow 80/tcp
ufw allow 443/tcp

# Database access (local only)
ufw allow from 127.0.0.1 to any port 5432
ufw allow from 172.16.0.0/16 to any port 5432

# Redis access (local only)
ufw allow from 127.0.0.1 to any port 6379
ufw allow from 172.16.0.0/16 to any port 6379

# Monitoring ports (local only)
ufw allow from 127.0.0.1 to any port 9090  # Prometheus
ufw allow from 127.0.0.1 to any port 3001  # Grafana

# Block common attack ports
ufw deny 135,139,445,1433,3389

# Geographic restrictions (block high-risk countries)
# This requires GeoIP database
for country in CN RU KP IR; do
  ufw deny from geoip:$country
done

# Enable UFW
ufw --force enable

# Configure fail2ban for additional protection
systemctl enable fail2ban
systemctl start fail2ban
EOF

chmod +x /opt/seo-platform/scripts/security/firewall-config.sh
```

### Container Security
```dockerfile
# Secure Dockerfile example
FROM node:18-alpine AS builder

# Create non-root user
RUN addgroup -g 1001 -S seouser && \
    adduser -S seouser -u 1001

# Security updates
RUN apk update && apk upgrade && \
    apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

# Build application
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Production stage
FROM node:18-alpine AS production

# Install security updates
RUN apk update && apk upgrade && \
    apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S seouser && \
    adduser -S seouser -u 1001

# Set up application directory
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=seouser:seouser . .

# Remove unnecessary files
RUN rm -rf tests/ docs/ .git/

# Security configurations
USER seouser
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]
```

### Secret Management
```bash
# Setup HashiCorp Vault for secret management
claude-code setup-vault \
  --mode=dev \
  --seal=auto \
  --storage=consul \
  --auth-methods=userpass,aws,github

# Vault configuration
cat > /opt/seo-platform/config/vault.hcl << 'EOF'
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = 0
  tls_cert_file = "/etc/ssl/certs/vault.crt"
  tls_key_file = "/etc/ssl/private/vault.key"
}

api_addr = "https://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"
ui = true

# Enable auto-unseal with cloud KMS
seal "awskms" {
  region     = "us-west-2"
  kms_key_id = "alias/vault-unseal-key"
}
EOF

# Initialize Vault secrets
vault auth enable userpass
vault policy write seo-platform - <<EOF
path "secret/data/seo-platform/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "database/creds/seo-readonly" {
  capabilities = ["read"]
}
path "database/creds/seo-readwrite" {
  capabilities = ["read"]
}
EOF

# Store secrets
vault kv put secret/seo-platform/database \
  username="seo_user" \
  password="$(openssl rand -base64 32)"

vault kv put secret/seo-platform/api-keys \
  openai="$(openssl rand -base64 32)" \
  gemini="$(openssl rand -base64 32)"

vault kv put secret/seo-platform/encryption \
  key="$(openssl rand -base64 32)" \
  jwt_secret="$(openssl rand -base64 32)"
```

## 🔍 Security Monitoring

### Intrusion Detection System (IDS)
```bash
# Install and configure OSSEC
claude-code setup-ids ossec \
  --mode=local \
  --log-analysis=true \
  --rootkit-detection=true \
  --active-response=true

# OSSEC configuration
cat > /var/ossec/etc/ossec.conf << 'EOF'
<ossec_config>
  <global>
    <email_notification>yes</email_notification>
    <email_to>security@familydentalcentres.com</email_to>
    <smtp_server>localhost</smtp_server>
    <email_from>ossec@familydentalcentres.com</email_from>
  </global>

  <rules>
    <include>rules_config.xml</include>
    <include>pam_rules.xml</include>
    <include>sshd_rules.xml</include>
    <include>telnetd_rules.xml</include>
    <include>syslog_rules.xml</include>
    <include>arpwatch_rules.xml</include>
    <include>symantec-av_rules.xml</include>
    <include>symantec-ws_rules.xml</include>
    <include>pix_rules.xml</include>
    <include>named_rules.xml</include>
    <include>smbd_rules.xml</include>
    <include>vsftpd_rules.xml</include>
    <include>pure-ftpd_rules.xml</include>
    <include>proftpd_rules.xml</include>
    <include>ms_ftpd_rules.xml</include>
    <include>ftpd_rules.xml</include>
    <include>hordeimp_rules.xml</include>
    <include>roundcube_rules.xml</include>
    <include>wordpress_rules.xml</include>
    <include>cimserver_rules.xml</include>
    <include>vpopmail_rules.xml</include>
    <include>vmpop3d_rules.xml</include>
    <include>courier_rules.xml</include>
    <include>web_rules.xml</include>
    <include>web_appsec_rules.xml</include>
    <include