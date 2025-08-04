#!/bin/bash
# ============================================================================
# API Layer Generator
# Uses Claude Code to create SEO platform API endpoints and controllers
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "🔧 Generating SEO Platform API Layer..."

# Create directories
mkdir -p src/api/routes src/api/controllers src/api/middleware src/api/validators

# Generate main API server
cat > src/api/server.ts << 'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { json, urlencoded } from 'body-parser';
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';

// Import routes
import clinicRoutes from './routes/clinic.routes';
import competitorRoutes from './routes/competitor.routes';
import rankingRoutes from './routes/ranking.routes';
import auditRoutes from './routes/audit.routes';
import insightRoutes from './routes/insight.routes';
import reportRoutes from './routes/report.routes';
import authRoutes from './routes/auth.routes';

// Import middleware
import { errorHandler } from './middleware/error.middleware';
import { authMiddleware } from './middleware/auth.middleware';
import { loggingMiddleware } from './middleware/logging.middleware';

const app = express();
const server = createServer(app);
const io = new SocketIOServer(server, {
  cors: {
    origin: process.env.FRONTEND_URL || "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

app.use(cors({
  origin: process.env.FRONTEND_URL || "http://localhost:3000",
  credentials: true,
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // Limit each IP to 1000 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
  },
});
app.use('/api/', limiter);

// Strict rate limiting for AI endpoints
const aiLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 100, // Limit AI requests
  message: {
    error: 'AI API rate limit exceeded, please try again later.',
  },
});

// Body parsing
app.use(json({ limit: '10mb' }));
app.use(urlencoded({ extended: true, limit: '10mb' }));

// Logging
app.use(loggingMiddleware);

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0',
    uptime: process.uptime(),
  });
});

// API routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/clinics', authMiddleware, clinicRoutes);
app.use('/api/v1/competitors', authMiddleware, competitorRoutes);
app.use('/api/v1/rankings', authMiddleware, rankingRoutes);
app.use('/api/v1/audits', authMiddleware, auditRoutes);
app.use('/api/v1/insights', authMiddleware, aiLimiter, insightRoutes);
app.use('/api/v1/reports', authMiddleware, reportRoutes);

// WebSocket authentication
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  // Verify JWT token here
  next();
});

// WebSocket connections
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  socket.on('join-clinic', (clinicId) => {
    socket.join(`clinic-${clinicId}`);
  });
  
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Error handling
app.use(errorHandler);

// Make io accessible to other modules
app.set('io', io);

export { app, server, io };
EOF

# Generate clinic routes
cat > src/api/routes/clinic.routes.ts << 'EOF'
import { Router } from 'express';
import { ClinicController } from '../controllers/clinic.controller';
import { validateClinic, validateClinicUpdate } from '../validators/clinic.validator';
import { adminOrManagerOnly } from '../middleware/rbac.middleware';

const router = Router();
const clinicController = new ClinicController();

// GET /api/v1/clinics - Get all clinics
router.get('/', clinicController.getAllClinics.bind(clinicController));

// GET /api/v1/clinics/:id - Get specific clinic
router.get('/:id', clinicController.getClinicById.bind(clinicController));

// POST /api/v1/clinics - Create new clinic
router.post('/', 
  adminOrManagerOnly,
  validateClinic,
  clinicController.createClinic.bind(clinicController)
);

// PUT /api/v1/clinics/:id - Update clinic
router.put('/:id',
  adminOrManagerOnly,
  validateClinicUpdate,
  clinicController.updateClinic.bind(clinicController)
);

// DELETE /api/v1/clinics/:id - Delete clinic
router.delete('/:id',
  adminOrManagerOnly,
  clinicController.deleteClinic.bind(clinicController)
);

// GET /api/v1/clinics/:id/dashboard - Get clinic dashboard data
router.get('/:id/dashboard',
  clinicController.getClinicDashboard.bind(clinicController)
);

// GET /api/v1/clinics/:id/rankings - Get clinic rankings
router.get('/:id/rankings',
  clinicController.getClinicRankings.bind(clinicController)
);

// GET /api/v1/clinics/:id/competitors - Get clinic competitors
router.get('/:id/competitors',
  clinicController.getClinicCompetitors.bind(clinicController)
);

// GET /api/v1/clinics/:id/technical-audit - Get latest technical audit
router.get('/:id/technical-audit',
  clinicController.getLatestTechnicalAudit.bind(clinicController)
);

// POST /api/v1/clinics/:id/technical-audit - Trigger new technical audit
router.post('/:id/technical-audit',
  clinicController.triggerTechnicalAudit.bind(clinicController)
);

// GET /api/v1/clinics/:id/nap-consistency - Get NAP consistency report
router.get('/:id/nap-consistency',
  clinicController.getNAPConsistency.bind(clinicController)
);

// PUT /api/v1/clinics/:id/nap-data - Update NAP data
router.put('/:id/nap-data',
  adminOrManagerOnly,
  clinicController.updateNAPData.bind(clinicController)
);

export default router;
EOF

# Generate clinic controller
cat > src/api/controllers/clinic.controller.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { Clinic } from '../../models/clinic.model';
import { Competitor } from '../../models/competitor.model';
import { Ranking } from '../../models/ranking.model';
import { TechnicalAudit } from '../../models/technical-audit.model';
import { NAPConsistency } from '../../models/nap-consistency.model';
import { TechnicalAuditService } from '../../services/technical-audit.service';
import { NAPConsistencyService } from '../../services/nap-consistency.service';
import { NotFoundError, ValidationError } from '../middleware/error.middleware';

export class ClinicController {
  private technicalAuditService = new TechnicalAuditService();
  private napConsistencyService = new NAPConsistencyService();

  /**
   * Get all clinics for the organization
   */
  public async getAllClinics(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { organizationId } = req.user; // Set by auth middleware
      const { page = 1, limit = 25, location, status } = req.query;

      const offset = (Number(page) - 1) * Number(limit);
      const where: any = { organizationId };

      if (location) {
        where['location.address'] = { $iLike: `%${location}%` };
      }
      if (status) {
        where.status = status;
      }

      const { rows: clinics, count: total } = await Clinic.findAndCountAll({
        where,
        limit: Number(limit),
        offset,
        order: [['createdAt', 'DESC']],
      });

      res.json({
        success: true,
        data: clinics,
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total,
          hasMore: offset + clinics.length < total,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get clinic by ID with related data
   */
  public async getClinicById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { organizationId } = req.user;

      const clinic = await Clinic.findOne({
        where: { id, organizationId },
        include: [
          {
            model: Competitor,
            as: 'competitors',
            limit: 5,
            order: [['marketPosition', 'ASC']],
          },
        ],
      });

      if (!clinic) {
        throw new NotFoundError('Clinic not found');
      }

      res.json({
        success: true,
        data: clinic,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create new clinic
   */
  public async createClinic(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { organizationId } = req.user;
      const clinicData = {
        ...req.body,
        organizationId,
      };

      // Validate domain uniqueness
      const existingClinic = await Clinic.findOne({
        where: { domain: clinicData.domain },
      });

      if (existingClinic) {
        throw new ValidationError('Domain already exists');
      }

      const clinic = await Clinic.create(clinicData);

      // Trigger initial competitor discovery
      // This would be handled by a background job
      
      res.status(201).json({
        success: true,
        data: clinic,
        message: 'Clinic created successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update clinic
   */
  public async updateClinic(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { organizationId } = req.user;

      const clinic = await Clinic.findOne({
        where: { id, organizationId },
      });

      if (!clinic) {
        throw new NotFoundError('Clinic not found');
      }

      await clinic.update(req.body);

      res.json({
        success: true,
        data: clinic,
        message: 'Clinic updated successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete clinic
   */
  public async deleteClinic(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { organizationId } = req.user;

      const clinic = await Clinic.findOne({
        where: { id, organizationId },
      });

      if (!clinic) {
        throw new NotFoundError('Clinic not found');
      }

      await clinic.destroy();

      res.json({
        success: true,
        message: 'Clinic deleted successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get clinic dashboard data
   */
  public async getClinicDashboard(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { organizationId } = req.user;
      const { period = '30d' } = req.query;

      const clinic = await Clinic.findOne({
        where: { id, organizationId },
      });

      if (!clinic) {
        throw new NotFoundError('Clinic not found');
      }

      // Get dashboard metrics
      const [
        currentRankings,
        competitorsCount,
        latestAudit,
        recentInsights
      ] = await Promise.all([
        clinic.getCurrentRankings(),
        Competitor.count({ where: { clinicId: id } }),
        clinic.getLatestTechnicalAudit(),
        // Would get insights from insights service
      ]);

      const dashboardData = {
        clinic: clinic.toSafeJSON(),
        metrics: {
          averageRanking: this.calculateAverageRanking(currentRankings),
          organicVisibility: clinic.calculateVisibilityScore(),
          technicalScore: latestAudit?.score || 0,
          competitorsTracked: competitorsCount,
        },
        recentActivity: {
          rankingUpdates: currentRankings.slice(0, 10),
          insights: recentInsights?.slice(0, 5) || [],
        },
      };

      res.json({
        success: true,
        data: dashboardData,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get clinic rankings
   */
  public async getClinicRankings(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { organizationId } = req.user;
      const { 
        keyword, 
        period = '30d', 
        device = 'desktop',
        searchEngine = 'google',
        location 
      } = req.query;

      const clinic = await Clinic.findOne({
        where: { id, organizationId },
      });

      if (!clinic) {
        throw new NotFoundError('Clinic not found');
      }

      const where: any = { clinicId: id };
      
      if (keyword) where.keyword = { $iLike: `%${keyword}%` };
      if (device !== 'both') where.device = device;
      if (searchEngine !== 'both') where.searchEngine = searchEngine;
      if (location) where.location = location;

      // Date filtering based on period
      const dateFilter = this.getPeriodDateFilter(period as string);
      if (dateFilter) where.trackedAt = dateFilter;

      const rankings = await Ranking.findAll({
        where,
        order: [['trackedAt', 'DESC']],
        limit: 1000,
      });

      // Group and analyze rankings
      const analysis = this.analyzeRankings(rankings);

      res.json({
        success: true,
        data: {
          rankings,
          analysis,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get clinic competitors
   */
  public async getClinicCompetitors(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { organizationId } = req.user;
      const { monitoring } = req.query;

      const clinic = await Clinic.findOne({
        where: { id, organizationId },
      });

      if (!clinic) {
        throw new NotFoundError('Clinic not found');
      }

      const where: any = { clinicId: id };
      if (monitoring === 'true') where.monitoringEnabled = true;

      const competitors = await Competitor.findAll({
        where,
        order: [['marketPosition', 'ASC']],
      });

      res.json({
        success: true,
        data: competitors,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get latest technical audit
   */
  public async getLatestTechnicalAudit(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { organizationId } = req.user;

      const clinic = await Clinic.findOne({
        where: { id, organizationId },
      });

      if (!clinic) {
        throw new NotFoundError('Clinic not found');
      }

      const audit = await clinic.getLatestTechnicalAudit();

      res.json({
        success: true,
        data: audit,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Trigger new technical audit
   */
  public async triggerTechnicalAudit(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { organizationId } = req.user;
      const { auditType = 'comprehensive', pages = [] } = req.body;

      const clinic = await Clinic.findOne({
        where: { id, organizationId },
      });

      if (!clinic) {
        throw new NotFoundError('Clinic not found');
      }

      // Queue technical audit job
      const auditJob = await this.technicalAuditService.queueAudit({
        clinicId: id,
        auditType,
        pages: pages.length > 0 ? pages : [`https://${clinic.domain}`],
      });

      res.json({
        success: true,
        data: {
          jobId: auditJob.id,
          status: 'queued',
          estimatedCompletion: new Date(Date.now() + 5 * 60 * 1000), // 5 minutes
        },
        message: 'Technical audit started',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get NAP consistency report
   */
  public async getNAPConsistency(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { organizationId } = req.user;

      const clinic = await Clinic.findOne({
        where: { id, organizationId },
      });

      if (!clinic) {
        throw new NotFoundError('Clinic not found');
      }

      const napReport = await this.napConsistencyService.generateReport(id);

      res.json({
        success: true,
        data: napReport,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update NAP data
   */
  public async updateNAPData(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { organizationId } = req.user;

      const clinic = await Clinic.findOne({
        where: { id, organizationId },
      });

      if (!clinic) {
        throw new NotFoundError('Clinic not found');
      }

      await clinic.update({
        napData: req.body,
      });

      // Trigger NAP consistency check
      await this.napConsistencyService.checkConsistency(id);

      res.json({
        success: true,
        data: clinic,
        message: 'NAP data updated successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  // Helper methods
  private calculateAverageRanking(rankings: any[]): number {
    if (rankings.length === 0) return 0;
    const sum = rankings.reduce((acc, ranking) => acc + ranking.position, 0);
    return Math.round(sum / rankings.length);
  }

  private getPeriodDateFilter(period: string): any {
    const now = new Date();
    const periodMap: { [key: string]: number } = {
      '7d': 7,
      '30d': 30,
      '90d': 90,
      '1y': 365,
    };

    const days = periodMap[period];
    if (!days) return null;

    const startDate = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
    return { $gte: startDate };
  }

  private analyzeRankings(rankings: any[]) {
    // Implement ranking analysis logic
    return {
      totalKeywords: rankings.length,
      averagePosition: this.calculateAverageRanking(rankings),
      topTenKeywords: rankings.filter(r => r.position <= 10).length,
      featuredSnippets: rankings.filter(r => r.featuredSnippet).length,
      localPackPositions: rankings.filter(r => r.localPackPosition).length,
    };
  }
}
EOF

echo "✅ API layer generated"
echo "📁 API components created:"
echo "   • src/api/server.ts - Express server with security"
echo "   • src/api/routes/ - RESTful route definitions"
echo "   • src/api/controllers/ - Business logic controllers"
echo "🔄 Ready for service layer generation"