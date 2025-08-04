# API.md - SEO Intelligence Platform API Documentation

## API Overview

The SEO Intelligence Platform provides a comprehensive RESTful API with real-time WebSocket capabilities for managing dental clinic SEO data, competitive intelligence, and AI-powered insights.

## 🔗 Base URLs

- **Production**: `https://api.familydentalcentres.com/v1`
- **Staging**: `https://staging-api.familydentalcentres.com/v1`
- **Local Development**: `http://localhost:3000/api/v1`

## 🔐 Authentication

### JWT Authentication
```http
Authorization: Bearer <your_jwt_token>
```

### API Key Authentication
```http
X-API-Key: <your_api_key>
```

### OAuth2 (Enterprise)
```http
Authorization: Bearer <oauth2_access_token>
```

## 📝 Request/Response Format

### Standard Response Format
```json
{
  "success": true,
  "data": {},
  "message": "Request processed successfully",
  "timestamp": "2024-07-01T12:00:00Z",
  "requestId": "req_abc123",
  "pagination": {
    "page": 1,
    "limit": 25,
    "total": 100,
    "hasMore": true
  }
}
```

### Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input parameters",
    "details": [
      {
        "field": "email",
        "message": "Email format is invalid"
      }
    ]
  },
  "timestamp": "2024-07-01T12:00:00Z",
  "requestId": "req_abc123"
}
```

## 🏢 Organization & Clinic Management

### Organizations

#### Get Organizations
```http
GET /organizations
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "org_123",
      "name": "Family Dental Centres",
      "domain": "familydentalcentres.com",
      "settings": {
        "timezone": "America/Vancouver",
        "currency": "CAD",
        "notifications": {
          "email": true,
          "slack": true,
          "webhook": "https://hooks.slack.com/..."
        }
      },
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-06-01T10:30:00Z"
    }
  ]
}
```

#### Create Organization
```http
POST /organizations
Content-Type: application/json

{
  "name": "New Dental Practice",
  "domain": "newdentalpractice.com",
  "settings": {
    "timezone": "America/Vancouver",
    "currency": "CAD"
  }
}
```

### Clinics

#### Get Clinics
```http
GET /clinics?organizationId=org_123&location=vancouver&status=active
```

**Query Parameters:**
- `organizationId` (string): Filter by organization
- `location` (string): Filter by location
- `status` (string): active, inactive, pending
- `page` (number): Page number (default: 1)
- `limit` (number): Items per page (default: 25)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "clinic_456",
      "organizationId": "org_123",
      "name": "Alberni Dental",
      "domain": "albernidental.com",
      "location": {
        "address": "123 Main St, Vancouver, BC V6B 1A1",
        "coordinates": {
          "latitude": 49.2827,
          "longitude": -123.1207
        },
        "timezone": "America/Vancouver"
      },
      "napData": {
        "name": "Alberni Dental Centre",
        "address": "123 Main St, Vancouver, BC V6B 1A1",
        "phone": "+1-604-555-0123",
        "website": "https://albernidental.com"
      },
      "businessHours": {
        "monday": {"open": "08:00", "close": "17:00"},
        "tuesday": {"open": "08:00", "close": "17:00"},
        "wednesday": {"open": "08:00", "close": "17:00"},
        "thursday": {"open": "08:00", "close": "17:00"},
        "friday": {"open": "08:00", "close": "16:00"},
        "saturday": {"open": "09:00", "close": "14:00"},
        "sunday": {"closed": true}
      },
      "services": [
        "general_dentistry",
        "cosmetic_dentistry",
        "orthodontics",
        "dental_implants",
        "emergency_care"
      ],
      "targetKeywords": [
        "dentist vancouver",
        "dental implants vancouver",
        "cosmetic dentist vancouver"
      ],
      "status": "active",
      "createdAt": "2024-01-15T00:00:00Z",
      "updatedAt": "2024-06-15T14:20:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 25,
    "total": 7,
    "hasMore": false
  }
}
```

#### Create Clinic
```http
POST /clinics
Content-Type: application/json

{
  "organizationId": "org_123",
  "name": "New Clinic Location",
  "domain": "newclinic.com",
  "location": {
    "address": "456 Oak St, Surrey, BC V3S 2K1",
    "coordinates": {
      "latitude": 49.1913,
      "longitude": -122.8490
    }
  },
  "napData": {
    "name": "New Clinic Location",
    "address": "456 Oak St, Surrey, BC V3S 2K1",
    "phone": "+1-604-555-0456",
    "website": "https://newclinic.com"
  },
  "services": ["general_dentistry", "orthodontics"],
  "targetKeywords": ["dentist surrey", "orthodontist surrey"]
}
```

#### Update Clinic
```http
PUT /clinics/{clinicId}
Content-Type: application/json

{
  "napData": {
    "phone": "+1-604-555-0789"
  },
  "businessHours": {
    "saturday": {"open": "08:00", "close": "16:00"}
  }
}
```

## 📊 SEO Analytics

### Rankings

#### Get Keyword Rankings
```http
GET /clinics/{clinicId}/rankings?keyword=dentist%20vancouver&period=30d&device=desktop
```

**Query Parameters:**
- `keyword` (string): Specific keyword filter
- `period` (string): 7d, 30d, 90d, 1y
- `device` (string): desktop, mobile, both
- `searchEngine` (string): google, bing, both
- `location` (string): Specific location filter

**Response:**
```json
{
  "success": true,
  "data": {
    "keyword": "dentist vancouver",
    "currentPosition": 8,
    "previousPosition": 12,
    "changePercent": -33.33,
    "trend": "up",
    "history": [
      {
        "date": "2024-07-01",
        "position": 8,
        "url": "https://albernidental.com/services",
        "featuredSnippet": false,
        "localPackPosition": 3,
        "device": "desktop",
        "searchEngine": "google",
        "location": "Vancouver, BC"
      }
    ],
    "competitors": [
      {
        "domain": "vancouvercentredental.com",
        "position": 1,
        "change": 0
      },
      {
        "domain": "westenddentalstudio.com",
        "position": 2,
        "change": 1
      }
    ]
  }
}
```

#### Get Ranking Summary
```http
GET /clinics/{clinicId}/rankings/summary?period=30d
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalKeywords": 45,
    "averagePosition": 18.7,
    "positionChange": -2.3,
    "visibility": 0.78,
    "visibilityChange": 0.12,
    "topTenKeywords": 8,
    "topThreeKeywords": 2,
    "featuredSnippets": 1,
    "localPackPositions": 12,
    "byPosition": {
      "1-3": 2,
      "4-10": 6,
      "11-20": 15,
      "21-50": 18,
      "51-100": 4
    },
    "trending": {
      "up": 12,
      "down": 8,
      "stable": 25
    }
  }
}
```

#### Track New Keywords
```http
POST /clinics/{clinicId}/rankings/track
Content-Type: application/json

{
  "keywords": [
    "emergency dentist vancouver",
    "dental implants burnaby",
    "cosmetic dentistry surrey"
  ],
  "locations": ["Vancouver, BC", "Burnaby, BC"],
  "devices": ["desktop", "mobile"],
  "searchEngines": ["google"]
}
```

### Technical Audits

#### Get Technical Audit Results
```http
GET /clinics/{clinicId}/technical-audit?latest=true
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "audit_789",
    "clinicId": "clinic_456",
    "auditType": "comprehensive",
    "score": 84,
    "auditedAt": "2024-07-01T10:00:00Z",
    "metrics": {
      "siteSpeed": {
        "desktop": {
          "score": 87,
          "loadTime": 2.1,
          "firstContentfulPaint": 1.2,
          "largestContentfulPaint": 2.8,
          "firstInputDelay": 45,
          "cumulativeLayoutShift": 0.08
        },
        "mobile": {
          "score": 78,
          "loadTime": 3.2,
          "firstContentfulPaint": 1.8,
          "largestContentfulPaint": 4.1,
          "firstInputDelay": 120,
          "cumulativeLayoutShift": 0.12
        }
      },
      "crawlability": {
        "score": 92,
        "robotsTxt": true,
        "sitemapValid": true,
        "crawlErrors": 0,
        "indexablePages": 45,
        "blockedPages": 2
      },
      "schemaMarkup": {
        "score": 88,
        "localBusinessSchema": true,
        "dentistSchema": true,
        "faqSchema": false,
        "reviewSchema": true,
        "validationErrors": 2
      },
      "mobileOptimization": {
        "score": 90,
        "responsiveDesign": true,
        "mobileFirstIndex": true,
        "touchTargetSize": true,
        "viewportConfiguration": true
      }
    },
    "issues": [
      {
        "severity": "medium",
        "category": "performance",
        "title": "Large image files affecting load time",
        "description": "Several images are not optimized for web",
        "affectedPages": ["/services", "/about"],
        "recommendation": "Compress and optimize images using WebP format"
      }
    ],
    "recommendations": [
      {
        "priority": "high",
        "category": "schema",
        "title": "Add FAQ schema markup",
        "description": "Implement FAQ schema on service pages",
        "expectedImpact": "Improved rich snippet visibility",
        "effort": "medium"
      }
    ]
  }
}
```

#### Trigger Technical Audit
```http
POST /clinics/{clinicId}/technical-audit
Content-Type: application/json

{
  "auditType": "comprehensive",
  "pages": [
    "https://albernidental.com/",
    "https://albernidental.com/services",
    "https://albernidental.com/about"
  ],
  "includeCompetitorComparison": true
}
```

### NAP Consistency

#### Get NAP Consistency Report
```http
GET /clinics/{clinicId}/nap-consistency
```

**Response:**
```json
{
  "success": true,
  "data": {
    "consistencyScore": 87,
    "platforms": {
      "googleBusinessProfile": {
        "name": "Alberni Dental Centre",
        "address": "123 Main St, Vancouver, BC V6B 1A1",
        "phone": "+1-604-555-0123",
        "website": "https://albernidental.com",
        "lastVerified": "2024-06-30T15:30:00Z",
        "consistent": true
      },
      "facebook": {
        "name": "Alberni Dental Centre",
        "address": "123 Main Street, Vancouver, BC V6B 1A1",
        "phone": "(604) 555-0123",
        "website": "https://albernidental.com",
        "lastVerified": "2024-06-25T09:15:00Z",
        "consistent": false,
        "discrepancies": ["address_format", "phone_format"]
      },
      "yelp": {
        "name": "Alberni Dental",
        "address": "123 Main St, Vancouver, BC V6B 1A1",
        "phone": "+1-604-555-0123",
        "website": "https://albernidental.com",
        "lastVerified": "2024-06-28T14:20:00Z",
        "consistent": false,
        "discrepancies": ["business_name"]
      }
    },
    "discrepancies": [
      {
        "platform": "facebook",
        "field": "address",
        "expected": "123 Main St, Vancouver, BC V6B 1A1",
        "found": "123 Main Street, Vancouver, BC V6B 1A1",
        "severity": "low"
      },
      {
        "platform": "yelp",
        "field": "name",
        "expected": "Alberni Dental Centre",
        "found": "Alberni Dental",
        "severity": "medium"
      }
    ],
    "recommendations": [
      "Standardize business name across all platforms",
      "Use consistent address format",
      "Update Facebook page with standard phone number format"
    ]
  }
}
```

#### Update NAP Data
```http
PUT /clinics/{clinicId}/nap-data
Content-Type: application/json

{
  "name": "Alberni Dental Centre",
  "address": "123 Main St, Vancouver, BC V6B 1A1",
  "phone": "+1-604-555-0123",
  "website": "https://albernidental.com",
  "hours": {
    "monday": "8:00 AM - 5:00 PM",
    "tuesday": "8:00 AM - 5:00 PM",
    "wednesday": "8:00 AM - 5:00 PM",
    "thursday": "8:00 AM - 5:00 PM",
    "friday": "8:00 AM - 4:00 PM",
    "saturday": "9:00 AM - 2:00 PM",
    "sunday": "Closed"
  }
}
```

## 🏆 Competitive Intelligence

### Competitors

#### Get Competitors
```http
GET /clinics/{clinicId}/competitors?monitoring=true
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "comp_123",
      "clinicId": "clinic_456",
      "name": "Vancouver Centre Dental",
      "domain": "vancouvercentredental.com",
      "location": {
        "address": "789 Granville St, Vancouver, BC V6Z 1G3",
        "coordinates": {
          "latitude": 49.2845,
          "longitude": -123.1234
        },
        "distance": 2.3
      },
      "marketPosition": 1,
      "monitoringEnabled": true,
      "metrics": {
        "visibility": 0.85,
        "estimatedTraffic": 15000,
        "backlinks": 1250,
        "domainAuthority": 65,
        "socialFollowers": {
          "facebook": 3200,
          "instagram": 2800,
          "linkedin": 450
        }
      },
      "discoveredAt": "2024-01-01T00:00:00Z",
      "lastAnalyzed": "2024-07-01T08:00:00Z"
    }
  ]
}
```

#### Add Competitor
```http
POST /clinics/{clinicId}/competitors
Content-Type: application/json

{
  "name": "New Competitor Dental",
  "domain": "newcompetitor.com",
  "location": {
    "address": "456 Oak Street, Vancouver, BC V6H 2L2"
  },
  "monitoringEnabled": true
}
```

#### Get Competitor Analysis
```http
GET /competitors/{competitorId}/analysis?period=30d
```

**Response:**
```json
{
  "success": true,
  "data": {
    "competitorId": "comp_123",
    "period": "30d",
    "rankingComparison": {
      "sharedKeywords": 25,
      "competitorWinning": 15,
      "clientWinning": 10,
      "gapOpportunities": [
        {
          "keyword": "dental emergency vancouver",
          "competitorPosition": 3,
          "clientPosition": null,
          "searchVolume": 1200,
          "difficulty": 45
        }
      ]
    },
    "contentAnalysis": {
      "totalPages": 45,
      "newContent": 3,
      "updatedContent": 8,
      "contentGaps": [
        {
          "topic": "Invisalign treatment",
          "competitorPages": 3,
          "clientPages": 1,
          "opportunity": "high"
        }
      ]
    },
    "technicalMetrics": {
      "siteSpeedDifference": -0.8,
      "mobileScoreDifference": 5,
      "schemaImplementation": "better"
    },
    "socialMetrics": {
      "engagementRate": 0.068,
      "postFrequency": 4.2,
      "followerGrowth": 0.12
    }
  }
}
```

### Market Intelligence

#### Get Market Overview
```http
GET /clinics/{clinicId}/market-intelligence?location=vancouver&period=30d
```

**Response:**
```json
{
  "success": true,
  "data": {
    "location": "Vancouver, BC",
    "period": "30d",
    "marketShare": {
      "visibility": 0.12,
      "rank": 5,
      "totalCompetitors": 15
    },
    "keywordOpportunities": [
      {
        "keyword": "pediatric dentist vancouver",
        "searchVolume": 800,
        "difficulty": 35,
        "currentRank": null,
        "topCompetitor": "kidsdentalvancouver.com",
        "opportunity": "high"
      }
    ],
    "trendingTopics": [
      {
        "topic": "dental implants",
        "searchVolumeIncrease": 15,
        "competitionLevel": "medium"
      },
      {
        "topic": "teeth whitening",
        "searchVolumeIncrease": 8,
        "competitionLevel": "high"
      }
    ],
    "localPackAnalysis": {
      "averagePosition": 4.2,
      "appearsIn": 8,
      "totalQueries": 20,
      "missingFrom": [
        "emergency dentist vancouver",
        "dental implants vancouver"
      ]
    }
  }
}
```

## 🤖 AI Insights

### Content Analysis

#### Get Content Recommendations
```http
GET /clinics/{clinicId}/ai/content-recommendations?page=/services
```

**Response:**
```json
{
  "success": true,
  "data": {
    "pageUrl": "https://albernidental.com/services",
    "analysisDate": "2024-07-01T12:00:00Z",
    "aiModel": "gpt-4-turbo",
    "contentScore": 78,
    "recommendations": [
      {
        "type": "keyword_optimization",
        "priority": "high",
        "title": "Include target keywords in headings",
        "description": "Add 'dental implants vancouver' to H2 heading",
        "expectedImpact": "15% improvement in keyword relevance",
        "implementation": "easy"
      },
      {
        "type": "content_expansion",
        "priority": "medium",
        "title": "Expand emergency dentistry section",
        "description": "Add 200-300 words about emergency procedures",
        "expectedImpact": "Better coverage of emergency dental queries",
        "implementation": "medium"
      }
    ],
    "competitorGaps": [
      {
        "topic": "same-day dental crowns",
        "explanation": "Competitors rank well for this service but it's not prominently featured",
        "suggestedAction": "Create dedicated page or section"
      }
    ],
    "technicalSuggestions": [
      {
        "type": "schema_markup",
        "suggestion": "Add FAQ schema for common dental questions",
        "implementation": "Add JSON-LD script to page"
      }
    ]
  }
}
```

#### Generate AI Insights
```http
POST /clinics/{clinicId}/ai/generate-insights
Content-Type: application/json

{
  "analysisType": "comprehensive",
  "includeCompetitors": true,
  "focusAreas": ["content", "technical", "local_seo"],
  "aiModels": ["openai", "gemini"]
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "jobId": "job_abc123",
    "status": "processing",
    "estimatedCompletion": "2024-07-01T12:05:00Z",
    "progressUrl": "/ai/jobs/job_abc123/status"
  }
}
```

#### Get AI Job Status
```http
GET /ai/jobs/{jobId}/status
```

**Response:**
```json
{
  "success": true,
  "data": {
    "jobId": "job_abc123",
    "status": "completed",
    "progress": 100,
    "startedAt": "2024-07-01T12:00:00Z",
    "completedAt": "2024-07-01T12:04:30Z",
    "result": {
      "insightId": "insight_456",
      "insights": [
        {
          "type": "opportunity",
          "priority": "high",
          "title": "Local Pack Optimization Opportunity",
          "description": "Analysis shows potential to improve local pack rankings by 2-3 positions",
          "aiModel": "gemini-pro",
          "confidence": 0.87,
          "recommendations": [
            "Increase Google Business Profile post frequency to 3x per week",
            "Encourage more customer reviews with specific keywords",
            "Add location-specific landing pages for Surrey and Burnaby"
          ]
        }
      ]
    }
  }
}
```

### Predictive Analytics

#### Get Ranking Predictions
```http
GET /clinics/{clinicId}/ai/predictions/rankings?period=90d&keywords=top10
```

**Response:**
```json
{
  "success": true,
  "data": {
    "predictionPeriod": "90d",
    "modelAccuracy": 0.82,
    "lastTraining": "2024-06-15T00:00:00Z",
    "predictions": [
      {
        "keyword": "dentist vancouver",
        "currentPosition": 8,
        "predictedPosition": 5,
        "confidence": 0.75,
        "factors": [
          "Increasing backlink velocity",
          "Improving content depth",
          "Competitor content stagnation"
        ],
        "recommendations": [
          "Continue current link building strategy",
          "Add 500+ words to main service page"
        ]
      }
    ],
    "overallTrend": "improving",
    "expectedVisibilityIncrease": 0.15
  }
}
```

## 📊 Analytics & Reporting

### Reports

#### Get Report Templates
```http
GET /reports/templates
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "template_executive",
      "name": "Executive Summary",
      "description": "High-level KPIs and insights for leadership",
      "frequency": ["monthly", "quarterly"],
      "sections": [
        "ranking_summary",
        "traffic_overview",
        "competitive_position",
        "ai_insights"
      ]
    },
    {
      "id": "template_technical",
      "name": "Technical SEO Audit",
      "description": "Detailed technical analysis and recommendations",
      "frequency": ["weekly", "monthly"],
      "sections": [
        "site_health",
        "technical_issues",
        "performance_metrics",
        "recommendations"
      ]
    }
  ]
}
```

#### Generate Report
```http
POST /clinics/{clinicId}/reports/generate
Content-Type: application/json

{
  "templateId": "template_executive",
  "period": "30d",
  "format": "pdf",
  "includeCompetitors": true,
  "email": {
    "recipients": ["manager@familydentalcentres.com"],
    "subject": "Monthly SEO Performance Report"
  }
}
```

#### Get Report Status
```http
GET /reports/{reportId}/status
```

**Response:**
```json
{
  "success": true,
  "data": {
    "reportId": "report_789",
    "status": "completed",
    "progress": 100,
    "downloadUrl": "https://api.familydentalcentres.com/reports/report_789/download",
    "expiresAt": "2024-07-08T12:00:00Z",
    "generatedAt": "2024-07-01T12:15:00Z"
  }
}
```

### Dashboard Data

#### Get Dashboard Overview
```http
GET /clinics/{clinicId}/dashboard?period=30d
```

**Response:**
```json
{
  "success": true,
  "data": {
    "period": "30d",
    "kpis": {
      "averageRanking": {
        "current": 18.7,
        "previous": 21.0,
        "change": -10.95,
        "trend": "improving"
      },
      "organicVisibility": {
        "current": 0.78,
        "previous": 0.66,
        "change": 18.18,
        "trend": "improving"
      },
      "technicalScore": {
        "current": 84,
        "previous": 79,
        "change": 6.33,
        "trend": "improving"
      },
      "napConsistency": {
        "current": 87,
        "previous": 82,
        "change": 6.10,
        "trend": "improving"
      }
    },
    "alerts": {
      "critical": 0,
      "warning": 2,
      "info": 5
    },
    "recentInsights": [
      {
        "id": "insight_123",
        "type": "opportunity",
        "title": "Local pack ranking opportunity",
        "priority": "high",
        "createdAt": "2024-07-01T10:30:00Z"
      }
    ],
    "competitorMovement": [
      {
        "competitor": "Vancouver Centre Dental",
        "change": "up",
        "positions": 2
      }
    ]
  }
}
```

## 🔔 Alerts & Notifications

### Alert Configuration

#### Get Alert Rules
```http
GET /clinics/{clinicId}/alerts/rules
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "rule_123",
      "name": "Ranking Drop Alert",
      "type": "ranking_change",
      "enabled": true,
      "conditions": {
        "positionDrop": 5,
        "keywordImportance": "high",
        "timeframe": "24h"
      },
      "actions": {
        "email": ["seo@familydentalcentres.com"],
        "slack": "#seo-alerts",
        "webhook": "https://hooks.slack.com/..."
      },
      "createdAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### Create Alert Rule
```http
POST /clinics/{clinicId}/alerts/rules
Content-Type: application/json

{
  "name": "Competitor New Content Alert",
  "type": "competitor_activity",
  "enabled": true,
  "conditions": {
    "activityType": "new_content",
    "competitors": ["comp_123", "comp_456"],
    "frequency": "daily"
  },
  "actions": {
    "email": ["marketing@familydentalcentres.com"],
    "inApp": true
  }
}
```

#### Get Recent Alerts
```http
GET /clinics/{clinicId}/alerts?period=7d&severity=warning,critical
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "alert_789",
      "clinicId": "clinic_456",
      "type": "ranking_drop",
      "severity": "warning",
      "title": "Significant ranking drop detected",
      "message": "Keyword 'dentist vancouver' dropped from position 8 to 15",
      "metadata": {
        "keyword": "dentist vancouver",
        "previousPosition": 8,
        "currentPosition": 15,
        "url": "https://albernidental.com/services"
      },
      "triggeredAt": "2024-07-01T09:30:00Z",
      "acknowledgedAt": null,
      "resolvedAt": null
    }
  ]
}
```

## 🔌 WebSocket Events

### Connection
```javascript
const socket = io('wss://api.familydentalcentres.com', {
  auth: {
    token: 'your_jwt_token'
  }
});

// Join clinic-specific room
socket.emit('join', { clinicId: 'clinic_456' });
```

### Event Types

#### Ranking Updates
```javascript
socket.on('ranking_update', (data) => {
  /*
  {
    "type": "ranking_update",
    "clinicId": "clinic_456",
    "keyword": "dentist vancouver",
    "previousPosition": 8,
    "currentPosition": 5,
    "change": -3,
    "url": "https://albernidental.com/services",
    "timestamp": "2024-07-01T12:00:00Z"
  }
  */
  console.log('Ranking updated:', data);
});
```

#### Competitor Activity
```javascript
socket.on('competitor_activity', (data) => {
  /*
  {
    "type": "competitor_activity",
    "clinicId": "clinic_456",
    "competitorId": "comp_123",
    "competitorName": "Vancouver Centre Dental",
    "activityType": "new_content",
    "details": {
      "url": "https://vancouvercentredental.com/blog/new-post",
      "title": "Advanced Dental Implant Procedures",
      "contentType": "blog_post"
    },
    "timestamp": "2024-07-01T11:45:00Z"
  }
  */
  console.log('Competitor activity detected:', data);
});
```

#### Technical Issues
```javascript
socket.on('technical_issue', (data) => {
  /*
  {
    "type": "technical_issue",
    "clinicId": "clinic_456",
    "severity": "warning",
    "category": "performance",
    "title": "Site speed degradation detected",
    "affectedPages": ["/services", "/about"],
    "metrics": {
      "loadTime": 4.2,
      "previousLoadTime": 2.1
    },
    "timestamp": "2024-07-01T12:30:00Z"
  }
  */
  console.log('Technical issue detected:', data);
});
```

#### AI Insights Ready
```javascript
socket.on('ai_insight_ready', (data) => {
  /*
  {
    "type": "ai_insight_ready",
    "clinicId": "clinic_456",
    "insightId": "insight_789",
    "priority": "high",
    "category": "opportunity",
    "title": "Local SEO optimization opportunity",
    "processingTime": 120,
    "timestamp": "2024-07-01T12:05:00Z"
  }
  */
  console.log('New AI insight available:', data);
});
```

## 🔧 Utility Endpoints

### System Health

#### Health Check
```http
GET /health
```

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2024-07-01T12:00:00Z",
    "version": "1.2.3",
    "services": {
      "database": "healthy",
      "redis": "healthy",
      "ai_services": "healthy",
      "scraping_engine": "healthy"
    },
    "uptime": 2592000,
    "responseTime": 45
  }
}
```

#### System Metrics
```http
GET /metrics
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "requests": {
      "total": 1500000,
      "last24h": 45000,
      "averageResponseTime": 120
    },
    "database": {
      "connections": 15,
      "queriesPerSecond": 250,
      "slowQueries": 2
    },
    "ai": {
      "tokensUsed": 2500000,
      "requestsToday": 1200,
      "averageProcessingTime": 2300
    },
    "scraping": {
      "jobsCompleted": 85000,
      "successRate": 0.967,
      "averageJobTime": 8500
    }
  }
}
```

### Data Export

#### Export Data
```http
POST /clinics/{clinicId}/export
Content-Type: application/json

{
  "dataTypes": ["rankings", "audits", "competitors"],
  "period": "90d",
  "format": "csv",
  "email": "admin@familydentalcentres.com"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "exportId": "export_123",
    "status": "processing",
    "estimatedCompletion": "2024-07-01T12:10:00Z",
    "downloadUrl": null
  }
}
```

#### Get Export Status
```http
GET /exports/{exportId}/status
```

**Response:**
```json
{
  "success": true,
  "data": {
    "exportId": "export_123",
    "status": "completed",
    "downloadUrl": "https://api.familydentalcentres.com/exports/export_123/download",
    "expiresAt": "2024-07-08T12:00:00Z",
    "fileSize": "2.5MB",
    "recordCount": 15000
  }
}
```

## 📋 Rate Limits

### Standard Rate Limits
- **Authentication**: 100 requests per minute
- **General API**: 1000 requests per hour per API key
- **AI Endpoints**: 100 requests per hour per clinic
- **Bulk Operations**: 10 requests per hour
- **WebSocket Connections**: 5 concurrent connections per user

### Enterprise Rate Limits
- **General API**: 10,000 requests per hour per API key
- **AI Endpoints**: 1000 requests per hour per clinic
- **Bulk Operations**: 100 requests per hour
- **WebSocket Connections**: 50 concurrent connections per user

### Rate Limit Headers
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1625140800
X-RateLimit-Window: 3600
```

## ❌ Error Codes

### HTTP Status Codes
- `200` - Success
- `201` - Created
- `204` - No Content
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `409` - Conflict
- `422` - Unprocessable Entity
- `429` - Too Many Requests
- `500` - Internal Server Error
- `502` - Bad Gateway
- `503` - Service Unavailable

### Application Error Codes
```json
{
  "VALIDATION_ERROR": "Input validation failed",
  "CLINIC_NOT_FOUND": "Clinic not found",
  "COMPETITOR_EXISTS": "Competitor already exists",
  "INSUFFICIENT_PERMISSIONS": "User lacks required permissions",
  "AI_SERVICE_UNAVAILABLE": "AI service temporarily unavailable",
  "SCRAPING_BLOCKED": "Website blocking scraping attempts",
  "RATE_LIMIT_EXCEEDED": "API rate limit exceeded",
  "INVALID_API_KEY": "API key is invalid or expired",
  "MAINTENANCE_MODE": "System is in maintenance mode"
}
```

## 🔐 Security Best Practices

### API Key Management
```bash
# Rotate API keys regularly
curl -X POST https://api.familydentalcentres.com/v1/auth/rotate-key \
  -H "Authorization: Bearer <current_token>" \
  -H "Content-Type: application/json"
```

### Request Signing (Enterprise)
```javascript
const crypto = require('crypto');

function signRequest(method, path, body, timestamp, secret) {
  const payload = `${method}\n${path}\n${body}\n${timestamp}`;
  return crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
}

// Usage
const timestamp = Date.now();
const signature = signRequest('POST', '/clinics', JSON.stringify(data), timestamp, apiSecret);

fetch('https://api.familydentalcentres.com/v1/clinics', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': apiKey,
    'X-Timestamp': timestamp,
    'X-Signature': signature
  },
  body: JSON.stringify(data)
});
```

## 📚 SDK Examples

### JavaScript/Node.js
```javascript
const SEOPlatform = require('@family-dental/seo-platform-sdk');

const client = new SEOPlatform({
  apiKey: 'your_api_key',
  baseUrl: 'https://api.familydentalcentres.com/v1'
});

// Get clinic rankings
const rankings = await client.clinics('clinic_456').rankings.get({
  period: '30d',
  keywords: ['dentist vancouver', 'dental implants']
});

// Track new keywords
await client.clinics('clinic_456').rankings.track([
  'emergency dentist vancouver',
  'cosmetic dentistry burnaby'
]);

// Get AI insights
const insights = await client.clinics('clinic_456').ai.insights.generate({
  analysisType: 'comprehensive',
  includeCompetitors: true
});
```

### Python
```python
from seo_platform import Client

client = Client(
    api_key='your_api_key',
    base_url='https://api.familydentalcentres.com/v1'
)

# Get clinic data
clinic = client.clinics.get('clinic_456')

# Get rankings
rankings = client.clinics('clinic_456').rankings.get(
    period='30d',
    keywords=['dentist vancouver', 'dental implants']
)

# Generate AI insights
insights = client.clinics('clinic_456').ai.insights.generate(
    analysis_type='comprehensive',
    include_competitors=True
)
```

### cURL Examples

#### Get Rankings
```bash
curl -X GET "https://api.familydentalcentres.com/v1/clinics/clinic_456/rankings?period=30d" \
  -H "Authorization: Bearer your_jwt_token" \
  -H "Content-Type: application/json"
```

#### Track Keywords
```bash
curl -X POST "https://api.familydentalcentres.com/v1/clinics/clinic_456/rankings/track" \
  -H "Authorization: Bearer your_jwt_token" \
  -H "Content-Type: application/json" \
  -d '{
    "keywords": ["emergency dentist vancouver", "dental implants burnaby"],
    "locations": ["Vancouver, BC", "Burnaby, BC"],
    "devices": ["desktop", "mobile"]
  }'
```

#### Generate AI Insights
```bash
curl -X POST "https://api.familydentalcentres.com/v1/clinics/clinic_456/ai/generate-insights" \
  -H "Authorization: Bearer your_jwt_token" \
  -H "Content-Type: application/json" \
  -d '{
    "analysisType": "comprehensive",
    "includeCompetitors": true,
    "focusAreas": ["content", "technical", "local_seo"]
  }'
```

## 🔄 Webhooks

### Webhook Configuration
```http
POST /webhooks
Content-Type: application/json

{
  "url": "https://your-domain.com/webhook/seo-platform",
  "events": [
    "ranking.updated",
    "competitor.activity",
    "technical.issue",
    "ai.insight.ready"
  ],
  "secret": "your_webhook_secret",
  "active": true
}
```

### Webhook Payload Example
```json
{
  "id": "webhook_evt_123",
  "object": "event",
  "type": "ranking.updated",
  "created": 1625140800,
  "data": {
    "clinicId": "clinic_456",
    "keyword": "dentist vancouver",
    "previousPosition": 8,
    "currentPosition": 5,
    "change": -3,
    "url": "https://albernidental.com/services"
  }
}
```

### Webhook Verification
```javascript
const crypto = require('crypto');

function verifyWebhook(payload, signature, secret) {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  
  return crypto.timingSafeEqual(
    Buffer.from(signature, 'hex'),
    Buffer.from(expectedSignature, 'hex')
  );
}

// Express.js example
app.post('/webhook/seo-platform', (req, res) => {
  const signature = req.headers['x-seo-platform-signature'];
  const payload = JSON.stringify(req.body);
  
  if (!verifyWebhook(payload, signature, webhookSecret)) {
    return res.status(401).send('Unauthorized');
  }
  
  // Process webhook event
  console.log('Webhook event:', req.body);
  res.status(200).send('OK');
});
```

## 📖 Changelog

### Version 1.2.3 (2024-07-01)
- Added predictive analytics endpoints
- Enhanced AI insight generation with dual model support
- Improved WebSocket event handling
- Added bulk operations for keyword tracking

### Version 1.2.2 (2024-06-15)
- Added competitor activity monitoring
- Enhanced NAP consistency reporting
- Improved error handling and response formats
- Added webhook support for real-time notifications

### Version 1.2.1 (2024-06-01)
- Initial public API release
- Core SEO monitoring endpoints
- AI-powered content recommendations
- Basic competitive intelligence features

## 🎯 Roadmap

### Q3 2024
- Advanced attribution modeling
- Custom report builder API
- Enhanced local SEO features
- Mobile app API endpoints

### Q4 2024
- Voice search optimization tracking
- Video content analysis
- Advanced competitor intelligence
- Multi-language support

---

*For additional support or questions about the API, please contact our development team or consult the interactive API documentation at https://api.familydentalcentres.com/docs*