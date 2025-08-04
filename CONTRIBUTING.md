# CONTRIBUTING.md - Development Guidelines

## Contributing to the SEO Intelligence Platform

Welcome to the Family Dental Centres SEO Intelligence Platform development team! This document provides comprehensive guidelines for contributing to the project, ensuring code quality, security, and maintainability.

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Development Environment Setup](#development-environment-setup)
- [Code Standards](#code-standards)
- [Git Workflow](#git-workflow)
- [Testing Requirements](#testing-requirements)
- [Security Guidelines](#security-guidelines)
- [Documentation Standards](#documentation-standards)
- [Performance Guidelines](#performance-guidelines)
- [Code Review Process](#code-review-process)
- [Release Process](#release-process)

## 🚀 Getting Started

### Prerequisites
- Node.js 18+ LTS
- PostgreSQL 15+
- Redis 7+
- Docker & Docker Compose
- Git
- Claude Code CLI

### Development Skills Required
- **Backend**: TypeScript, Node.js, Express.js, PostgreSQL
- **Frontend**: React, TypeScript, Tailwind CSS
- **AI Integration**: OpenAI API, Google Gemini API
- **DevOps**: Docker, Linux, Nginx, monitoring tools
- **Security**: Authentication, encryption, secure coding practices

## 💻 Development Environment Setup

### 1. Repository Setup
```bash
# Clone the repository
git clone https://github.com/family-dental-centres/seo-intelligence-platform.git
cd seo-intelligence-platform

# Install Claude Code if not already installed
npm install -g @anthropic/claude-code

# Setup development environment
claude-code setup-dev-environment \
  --node-version=18 \
  --postgresql=15 \
  --redis=7 \
  --docker=true
```

### 2. Environment Configuration
```bash
# Copy environment template
cp .env.example .env.development

# Configure development environment
cat > .env.development << 'EOF'
# Development Environment Configuration
NODE_ENV=development
PORT=3000
HOST=localhost

# Database Configuration
DATABASE_URL=postgresql://seo_dev:dev_password@localhost:5432/seo_platform_dev
DATABASE_POOL_MIN=2
DATABASE_POOL_MAX=10

# Redis Configuration
REDIS_URL=redis://localhost:6379
REDIS_TTL_DEFAULT=300
REDIS_TTL_CACHE=600

# AI API Configuration (Development Keys)
OPENAI_API_KEY=sk-dev-your-development-key
GEMINI_API_KEY=your-development-gemini-key

# Security Configuration
JWT_SECRET=dev-jwt-secret-change-in-production
ENCRYPTION_KEY=dev-encryption-key-32-characters

# Development Features
DEBUG_MODE=true
VERBOSE_LOGGING=true
DISABLE_RATE_LIMITING=true
MOCK_AI_RESPONSES=false

# Testing Configuration
TEST_DATABASE_URL=postgresql://seo_test:test_password@localhost:5432/seo_platform_test
TEST_REDIS_URL=redis://localhost:6380

# Development Tools
ENABLE_GRAPHQL_PLAYGROUND=true
ENABLE_DEBUG_ENDPOINTS=true
HOT_RELOAD=true
EOF
```

### 3. Database Setup
```bash
# Setup development databases
claude-code setup-dev-database \
  --create-dev-db=true \
  --create-test-db=true \
  --seed-data=true \
  --sample-clinics=true

# Run migrations
npm run migrate:dev

# Seed development data
npm run seed:dev
```

### 4. Development Services
```bash
# Start development services with Docker Compose
docker-compose -f docker-compose.dev.yml up -d

# Or start individual services
npm run dev:database
npm run dev:redis
npm run dev:api
npm run dev:frontend
npm run dev:scraper
```

## 📝 Code Standards

### TypeScript Configuration
```json
// tsconfig.json for strict TypeScript
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "removeComments": true,
    "strict": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "moduleResolution": "node",
    "baseUrl": "./src",
    "paths": {
      "@/*": ["*"],
      "@/types/*": ["types/*"],
      "@/utils/*": ["utils/*"],
      "@/services/*": ["services/*"]
    },
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
```

### ESLint Configuration
```json
// .eslintrc.json
{
  "extends": [
    "@typescript-eslint/recommended",
    "prettier",
    "plugin:security/recommended"
  ],
  "plugins": [
    "@typescript-eslint",
    "security",
    "import"
  ],
  "rules": {
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/explicit-function-return-type": "error",
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/prefer-readonly": "error",
    "security/detect-sql-injection": "error",
    "security/detect-non-literal-fs-filename": "error",
    "security/detect-unsafe-regex": "error",
    "import/order": ["error", {
      "groups": ["builtin", "external", "internal"],
      "newlines-between": "always"
    }],
    "prefer-const": "error",
    "no-var": "error",
    "no-console": "warn"
  }
}
```

### Code Formatting
```json
// .prettierrc
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "avoid"
}
```

### Naming Conventions
```typescript
// File and Directory Naming
// - Use kebab-case for file names: user-service.ts, clinic-controller.ts
// - Use PascalCase for class names: UserService, ClinicController
// - Use camelCase for functions and variables: getUserById, clinicData
// - Use UPPER_SNAKE_CASE for constants: MAX_RETRY_ATTEMPTS, API_BASE_URL

// Database Naming
// - Use snake_case for table names: user_profiles, clinic_rankings
// - Use snake_case for column names: created_at, user_id
// - Use descriptive names: is_active instead of active

// API Naming
// - Use kebab-case for endpoints: /api/v1/clinic-rankings
// - Use descriptive resource names: /clinics/{id}/rankings
// - Use standard HTTP methods appropriately

// Example: Proper TypeScript class structure
export class ClinicRankingService {
  private readonly CACHE_TTL = 3600; // seconds
  
  constructor(
    private readonly database: DatabaseService,
    private readonly cache: CacheService,
    private readonly logger: Logger
  ) {}
  
  public async getRankings(
    clinicId: string,
    options: RankingOptions
  ): Promise<RankingData[]> {
    // Implementation
  }
  
  private async validateClinicAccess(
    clinicId: string,
    userId: string
  ): Promise<boolean> {
    // Implementation
  }
}
```

## 🔄 Git Workflow

### Branch Strategy
```bash
# Branch naming conventions
feature/SEO-123-add-competitor-tracking
bugfix/SEO-456-fix-ranking-calculation
hotfix/SEO-789-security-vulnerability
release/v1.2.0
```

### Commit Message Format
```
type(scope): brief description

Detailed explanation of what changed and why.

Resolves: #123
Breaking Changes: None
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `security`: Security-related changes

### Development Workflow
```bash
# 1. Create feature branch from main
git checkout main
git pull origin main
git checkout -b feature/SEO-123-add-competitor-tracking

# 2. Make changes and commit frequently
git add .
git commit -m "feat(competitors): add basic competitor tracking API

- Add competitor model and database schema
- Implement CRUD operations for competitors
- Add input validation and error handling

Resolves: #123"

# 3. Keep branch updated with main
git fetch origin
git rebase origin/main

# 4. Push branch and create pull request
git push origin feature/SEO-123-add-competitor-tracking

# 5. Create pull request with proper template
# See .github/pull_request_template.md
```

### Pull Request Template
```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed
- [ ] Security testing completed

## Security Checklist
- [ ] No sensitive data exposed in logs
- [ ] Input validation implemented
- [ ] SQL injection prevention verified
- [ ] Authentication/authorization properly implemented
- [ ] Secrets properly managed

## Performance Impact
- [ ] Database queries optimized
- [ ] Caching strategy implemented
- [ ] Memory usage considered
- [ ] Response time impact minimal

## Documentation
- [ ] API documentation updated
- [ ] Code comments added where necessary
- [ ] README updated if needed
- [ ] Deployment notes provided

## Screenshots (if applicable)
Include screenshots of UI changes.

## Deployment Notes
Any special deployment considerations.

Resolves: #issue-number
```

## 🧪 Testing Requirements

### Test Structure
```
tests/
├── unit/
│   ├── services/
│   ├── controllers/
│   ├── utils/
│   └── models/
├── integration/
│   ├── api/
│   ├── database/
│   └── external-services/
├── e2e/
│   ├── user-workflows/
│   └── api-scenarios/
├── performance/
│   ├── load-tests/
│   └── stress-tests/
└── security/
    ├── auth-tests/
    └── vulnerability-tests/
```

### Unit Testing Standards
```typescript
// Example unit test with Jest
import { ClinicRankingService } from '@/services/clinic-ranking-service';
import { DatabaseService } from '@/services/database-service';
import { CacheService } from '@/services/cache-service';
import { Logger } from '@/utils/logger';

describe('ClinicRankingService', () => {
  let service: ClinicRankingService;
  let mockDatabase: jest.Mocked<DatabaseService>;
  let mockCache: jest.Mocked<CacheService