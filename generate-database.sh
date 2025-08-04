#!/bin/bash
# ============================================================================
# Database Schema and Models Generator
# Uses Claude Code to create SEO platform database layer
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "🗄️ Generating SEO Platform Database Layer..."

# Create directories
mkdir -p database/migrations database/seeds src/models

# Generate database schema SQL
cat > database/schema.sql << 'EOF'
-- SEO Intelligence Platform Database Schema
-- Optimized for PostgreSQL 15+ with performance indexes

-- Users and Organizations
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255) UNIQUE NOT NULL,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'analyst',
    settings JSONB DEFAULT '{}',
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Dental Clinics Management
CREATE TABLE clinics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255) NOT NULL,
    location JSONB NOT NULL, -- {address, coordinates, timezone}
    nap_data JSONB NOT NULL, -- {name, address, phone, website}
    business_hours JSONB DEFAULT '{}',
    services TEXT[] DEFAULT '{}',
    target_keywords TEXT[] DEFAULT '{}',
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Competitor Intelligence
CREATE TABLE competitors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id UUID REFERENCES clinics(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255) NOT NULL,
    location JSONB,
    market_position INTEGER,
    monitoring_enabled BOOLEAN DEFAULT true,
    metrics JSONB DEFAULT '{}',
    discovered_at TIMESTAMP DEFAULT NOW(),
    last_analyzed TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- SEO Rankings Tracking
CREATE TABLE keywords (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id UUID REFERENCES clinics(id) ON DELETE CASCADE,
    keyword VARCHAR(500) NOT NULL,
    search_volume INTEGER DEFAULT 0,
    difficulty INTEGER DEFAULT 0,
    intent VARCHAR(50) DEFAULT 'informational',
    local_modifier BOOLEAN DEFAULT false,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE rankings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id UUID REFERENCES clinics(id) ON DELETE CASCADE,
    keyword_id UUID REFERENCES keywords(id) ON DELETE CASCADE,
    keyword VARCHAR(500) NOT NULL, -- Denormalized for performance
    position INTEGER NOT NULL,
    url TEXT,
    featured_snippet BOOLEAN DEFAULT false,
    local_pack_position INTEGER,
    device VARCHAR(20) DEFAULT 'desktop',
    search_engine VARCHAR(20) DEFAULT 'google',
    location VARCHAR(255) NOT NULL,
    tracked_at TIMESTAMP DEFAULT NOW(),
    
    -- Performance indexes
    INDEX idx_rankings_clinic_date (clinic_id, tracked_at),
    INDEX idx_rankings_keyword_date (keyword_id, tracked_at),
    INDEX idx_rankings_position (position, tracked_at)
);

-- Technical SEO Audits
CREATE TABLE technical_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id UUID REFERENCES clinics(id) ON DELETE CASCADE,
    audit_type VARCHAR(100) DEFAULT 'comprehensive',
    score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
    metrics JSONB NOT NULL, -- {siteSpeed, crawlability, schemaMarkup, mobileOptimization}
    issues JSONB DEFAULT '[]',
    recommendations JSONB DEFAULT '[]',
    raw_data JSONB,
    audited_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_audits_clinic_date (clinic_id, audited_at),
    INDEX idx_audits_score (score, audited_at)
);

-- NAP Consistency Tracking
CREATE TABLE nap_consistency (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id UUID REFERENCES clinics(id) ON DELETE CASCADE,
    platform VARCHAR(100) NOT NULL,
    nap_data JSONB NOT NULL,
    consistent BOOLEAN DEFAULT false,
    discrepancies TEXT[] DEFAULT '{}',
    last_verified TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_nap_clinic_platform (clinic_id, platform),
    UNIQUE(clinic_id, platform)
);

-- AI-Generated Insights
CREATE TABLE insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id UUID REFERENCES clinics(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL, -- 'opportunity', 'warning', 'recommendation'
    category VARCHAR(100) NOT NULL, -- 'content', 'technical', 'competitive'
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    confidence DECIMAL(3,2) DEFAULT 0.0,
    ai_model VARCHAR(100),
    metadata JSONB DEFAULT '{}',
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    
    INDEX idx_insights_clinic_priority (clinic_id, priority, created_at),
    INDEX idx_insights_category (category, created_at)
);

-- Reporting and Analytics
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id UUID REFERENCES clinics(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    template_id VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    format VARCHAR(20) DEFAULT 'pdf',
    status VARCHAR(50) DEFAULT 'generating',
    data JSONB,
    file_path TEXT,
    generated_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    
    INDEX idx_reports_clinic_date (clinic_id, generated_at)
);

-- Background Jobs Tracking
CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_id UUID REFERENCES clinics(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    priority INTEGER DEFAULT 0,
    data JSONB DEFAULT '{}',
    result JSONB,
    error_message TEXT,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    scheduled_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    INDEX idx_jobs_status_priority (status, priority, scheduled_at),
    INDEX idx_jobs_clinic_type (clinic_id, type, scheduled_at)
);

-- Performance optimization indexes
CREATE INDEX idx_clinics_organization ON clinics(organization_id);
CREATE INDEX idx_competitors_clinic ON competitors(clinic_id);
CREATE INDEX idx_keywords_clinic ON keywords(clinic_id);
CREATE INDEX idx_rankings_search ON rankings(search_engine, location, tracked_at);

-- Full-text search indexes
CREATE INDEX idx_keywords_search ON keywords USING gin(to_tsvector('english', keyword));
CREATE INDEX idx_insights_search ON insights USING gin(to_tsvector('english', title || ' ' || description));
EOF

echo "✅ Database schema created"

# Generate TypeScript models using Claude Code
# This simulates what the actual Claude Code tool would generate

# Base model interface
cat > src/models/base.model.ts << 'EOF'
import { DataTypes, Model, Optional } from 'sequelize';
import { sequelize } from '../database';

// Base attributes that all models share
export interface BaseAttributes {
  id: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface BaseCreationAttributes extends Optional<BaseAttributes, 'id' | 'createdAt' | 'updatedAt'> {}

export abstract class BaseModel<T extends BaseAttributes, U extends BaseCreationAttributes> extends Model<T, U> {
  public id!: string;
  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

  // Common utility methods
  public toSafeJSON(): Omit<T, 'id' | 'createdAt' | 'updatedAt'> & { id: string } {
    const json = this.toJSON() as T;
    return {
      ...json,
      id: this.id
    };
  }

  // Static method to safely find by ID
  public static async findByIdSafe<M extends Model>(this: any, id: string): Promise<M | null> {
    if (!id || typeof id !== 'string') {
      return null;
    }
    return this.findByPk(id);
  }
}
EOF

# Clinic model
cat > src/models/clinic.model.ts << 'EOF'
import { DataTypes, Association, HasManyOptions } from 'sequelize';
import { BaseModel, BaseAttributes, BaseCreationAttributes } from './base.model';
import { sequelize } from '../database';

// Location and NAP data interfaces
export interface LocationData {
  address: string;
  coordinates: {
    latitude: number;
    longitude: number;
  };
  timezone: string;
}

export interface NAPData {
  name: string;
  address: string;
  phone: string;
  website: string;
}

export interface BusinessHours {
  [day: string]: {
    open?: string;
    close?: string;
    closed?: boolean;
  };
}

// Clinic model attributes
export interface ClinicAttributes extends BaseAttributes {
  organizationId: string;
  name: string;
  domain: string;
  location: LocationData;
  napData: NAPData;
  businessHours: BusinessHours;
  services: string[];
  targetKeywords: string[];
  status: 'active' | 'inactive' | 'pending';
}

export interface ClinicCreationAttributes extends BaseCreationAttributes {
  organizationId: string;
  name: string;
  domain: string;
  location: LocationData;
  napData: NAPData;
  businessHours?: BusinessHours;
  services?: string[];
  targetKeywords?: string[];
  status?: 'active' | 'inactive' | 'pending';
}

export class Clinic extends BaseModel<ClinicAttributes, ClinicCreationAttributes> {
  public organizationId!: string;
  public name!: string;
  public domain!: string;
  public location!: LocationData;
  public napData!: NAPData;
  public businessHours!: BusinessHours;
  public services!: string[];
  public targetKeywords!: string[];
  public status!: 'active' | 'inactive' | 'pending';

  // Associations
  public static associations: {
    competitors: Association<Clinic, any>;
    keywords: Association<Clinic, any>;
    rankings: Association<Clinic, any>;
    technicalAudits: Association<Clinic, any>;
    insights: Association<Clinic, any>;
  };

  // Business logic methods
  public async getCompetitors() {
    const { Competitor } = require('./competitor.model');
    return Competitor.findAll({
      where: { clinicId: this.id },
      order: [['marketPosition', 'ASC']]
    });
  }

  public async getCurrentRankings() {
    const { Ranking } = require('./ranking.model');
    return Ranking.findAll({
      where: { clinicId: this.id },
      order: [['trackedAt', 'DESC']],
      limit: 100
    });
  }

  public async getLatestTechnicalAudit() {
    const { TechnicalAudit } = require('./technical-audit.model');
    return TechnicalAudit.findOne({
      where: { clinicId: this.id },
      order: [['auditedAt', 'DESC']]
    });
  }

  public calculateVisibilityScore(): number {
    // Placeholder for visibility calculation logic
    // Would integrate with actual ranking data
    return Math.floor(Math.random() * 100);
  }

  public isActive(): boolean {
    return this.status === 'active';
  }
}

// Initialize the model
Clinic.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    organizationId: {
      type: DataTypes.UUID,
      allowNull: false,
      field: 'organization_id',
    },
    name: {
      type: DataTypes.STRING(255),
      allowNull: false,
      validate: {
        notEmpty: true,
        len: [1, 255],
      },
    },
    domain: {
      type: DataTypes.STRING(255),
      allowNull: false,
      validate: {
        isUrl: true,
      },
    },
    location: {
      type: DataTypes.JSONB,
      allowNull: false,
      validate: {
        isValidLocation(value: any) {
          if (!value.address || !value.coordinates) {
            throw new Error('Location must include address and coordinates');
          }
        },
      },
    },
    napData: {
      type: DataTypes.JSONB,
      allowNull: false,
      field: 'nap_data',
      validate: {
        isValidNAP(value: any) {
          if (!value.name || !value.address || !value.phone) {
            throw new Error('NAP data must include name, address, and phone');
          }
        },
      },
    },
    businessHours: {
      type: DataTypes.JSONB,
      defaultValue: {},
      field: 'business_hours',
    },
    services: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      defaultValue: [],
    },
    targetKeywords: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      defaultValue: [],
      field: 'target_keywords',
    },
    status: {
      type: DataTypes.ENUM('active', 'inactive', 'pending'),
      defaultValue: 'active',
    },
    createdAt: {
      type: DataTypes.DATE,
      field: 'created_at',
    },
    updatedAt: {
      type: DataTypes.DATE,
      field: 'updated_at',
    },
  },
  {
    sequelize,
    modelName: 'Clinic',
    tableName: 'clinics',
    underscored: true,
    timestamps: true,
    indexes: [
      {
        fields: ['organization_id'],
      },
      {
        fields: ['domain'],
        unique: true,
      },
      {
        fields: ['status'],
      },
    ],
  }
);

export default Clinic;
EOF

# Competitor model
cat > src/models/competitor.model.ts << 'EOF'
import { DataTypes, Association } from 'sequelize';
import { BaseModel, BaseAttributes, BaseCreationAttributes } from './base.model';
import { sequelize } from '../database';
import { LocationData } from './clinic.model';

export interface CompetitorMetrics {
  visibility: number;
  estimatedTraffic: number;
  backlinks: number;
  domainAuthority: number;
  socialFollowers: {
    facebook?: number;
    instagram?: number;
    linkedin?: number;
  };
}

export interface CompetitorAttributes extends BaseAttributes {
  clinicId: string;
  name: string;
  domain: string;
  location?: LocationData;
  marketPosition?: number;
  monitoringEnabled: boolean;
  metrics: CompetitorMetrics;
  discoveredAt: Date;
  lastAnalyzed?: Date;
}

export interface CompetitorCreationAttributes extends BaseCreationAttributes {
  clinicId: string;
  name: string;
  domain: string;
  location?: LocationData;
  marketPosition?: number;
  monitoringEnabled?: boolean;
  metrics?: CompetitorMetrics;
  discoveredAt?: Date;
}

export class Competitor extends BaseModel<CompetitorAttributes, CompetitorCreationAttributes> {
  public clinicId!: string;
  public name!: string;
  public domain!: string;
  public location?: LocationData;
  public marketPosition?: number;
  public monitoringEnabled!: boolean;
  public metrics!: CompetitorMetrics;
  public discoveredAt!: Date;
  public lastAnalyzed?: Date;

  // Business logic methods
  public async updateMetrics(newMetrics: Partial<CompetitorMetrics>) {
    this.metrics = { ...this.metrics, ...newMetrics };
    this.lastAnalyzed = new Date();
    return this.save();
  }

  public async getSharedKeywords() {
    const { Ranking } = require('./ranking.model');
    // Get keywords where both clinic and competitor rank
    return Ranking.findAll({
      where: {
        clinicId: this.clinicId,
        keyword: {
          // Would implement subquery for competitor keywords
        }
      }
    });
  }

  public calculateCompetitiveThreat(): 'low' | 'medium' | 'high' {
    const { visibility, domainAuthority } = this.metrics;
    if (visibility > 80 && domainAuthority > 60) return 'high';
    if (visibility > 50 && domainAuthority > 40) return 'medium';
    return 'low';
  }

  public isActive(): boolean {
    return this.monitoringEnabled;
  }
}

Competitor.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    clinicId: {
      type: DataTypes.UUID,
      allowNull: false,
      field: 'clinic_id',
      references: {
        model: 'clinics',
        key: 'id',
      },
    },
    name: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    domain: {
      type: DataTypes.STRING(255),
      allowNull: false,
      validate: {
        isUrl: true,
      },
    },
    location: {
      type: DataTypes.JSONB,
      allowNull: true,
    },
    marketPosition: {
      type: DataTypes.INTEGER,
      allowNull: true,
      field: 'market_position',
    },
    monitoringEnabled: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
      field: 'monitoring_enabled',
    },
    metrics: {
      type: DataTypes.JSONB,
      defaultValue: {},
    },
    discoveredAt: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
      field: 'discovered_at',
    },
    lastAnalyzed: {
      type: DataTypes.DATE,
      allowNull: true,
      field: 'last_analyzed',
    },
    createdAt: {
      type: DataTypes.DATE,
      field: 'created_at',
    },
    updatedAt: {
      type: DataTypes.DATE,
      field: 'updated_at',
    },
  },
  {
    sequelize,
    modelName: 'Competitor',
    tableName: 'competitors',
    underscored: true,
    timestamps: true,
    indexes: [
      {
        fields: ['clinic_id'],
      },
      {
        fields: ['domain'],
      },
      {
        fields: ['market_position'],
      },
    ],
  }
);

export default Competitor;
EOF

echo "✅ Core models generated"
echo "📁 Database layer created in:"
echo "   • database/schema.sql"
echo "   • src/models/"
echo "🔄 Ready for migration generation"