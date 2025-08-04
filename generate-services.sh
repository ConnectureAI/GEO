#!/bin/bash
# ============================================================================
# Business Services Generator
# Creates SEO platform business logic and service layer
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "🎯 Generating SEO Platform Business Services..."

# Create directories
mkdir -p src/services src/services/ai src/services/scraping src/services/analytics

# Generate base service class
cat > src/services/base.service.ts << 'EOF'
import { EventEmitter } from 'events';
import { Redis } from 'ioredis';
import { Logger } from '../utils/logger';

export abstract class BaseService extends EventEmitter {
  protected logger: Logger;
  protected redis: Redis;

  constructor(serviceName: string) {
    super();
    this.logger = new Logger(serviceName);
    this.redis = new Redis(process.env.REDIS_URL);
  }

  // Cache utilities
  protected async getFromCache<T>(key: string): Promise<T | null> {
    try {
      const cached = await this.redis.get(key);
      return cached ? JSON.parse(cached) : null;
    } catch (error) {
      this.logger.warn('Cache read error', { key, error: error.message });
      return null;
    }
  }

  protected async setCache(key: string, value: any, ttl: number = 3600): Promise<void> {
    try {
      await this.redis.setex(key, ttl, JSON.stringify(value));
    } catch (error) {
      this.logger.warn('Cache write error', { key, error: error.message });
    }
  }

  protected async invalidateCache(pattern: string): Promise<void> {
    try {
      const keys = await this.redis.keys(pattern);
      if (keys.length > 0) {
        await this.redis.del(...keys);
      }
    } catch (error) {
      this.logger.warn('Cache invalidation error', { pattern, error: error.message });
    }
  }

  // Rate limiting utilities
  protected async checkRateLimit(key: string, limit: number, window: number): Promise<boolean> {
    const current = await this.redis.incr(key);
    if (current === 1) {
      await this.redis.expire(key, window);
    }
    return current <= limit;
  }

  // Cleanup on service shutdown
  public async cleanup(): Promise<void> {
    await this.redis.disconnect();
    this.removeAllListeners();
  }
}
EOF

# Generate competitor analysis service
cat > src/services/competitor-analysis.service.ts << 'EOF'
import { BaseService } from './base.service';
import { Competitor } from '../models/competitor.model';
import { Clinic } from '../models/clinic.model';
import { SerpApiService } from './scraping/serpapi.service';
import { AhrefsApiService } from './scraping/ahrefs.service';
import { AIInsightsService } from './ai/ai-insights.service';
import { JobQueue } from '../utils/job-queue';

export interface CompetitorDiscoveryOptions {
  clinicId: string;
  location: string;
  keywords: string[];
  maxCompetitors?: number;
  includeLocal?: boolean;
  includePaid?: boolean;
}

export interface CompetitorAnalysisResult {
  competitor: Competitor;
  analysis: {
    sharedKeywords: string[];
    keywordGaps: Array<{
      keyword: string;
      competitorPosition: number;
      clientPosition: number | null;
      searchVolume: number;
      difficulty: number;
    }>;
    contentGaps: Array<{
      topic: string;
      competitorPages: number;
      clientPages: number;
      opportunity: 'high' | 'medium' | 'low';
    }>;
    technicalAdvantages: Array<{
      metric: string;
      competitorValue: number;
      clientValue: number;
      advantage: 'competitor' | 'client';
    }>;
  };
}

export class CompetitorAnalysisService extends BaseService {
  private serpApi: SerpApiService;
  private ahrefsApi: AhrefsApiService;
  private aiInsights: AIInsightsService;
  private jobQueue: JobQueue;

  constructor() {
    super('CompetitorAnalysisService');
    this.serpApi = new SerpApiService();
    this.ahrefsApi = new AhrefsApiService();
    this.aiInsights = new AIInsightsService();
    this.jobQueue = new JobQueue('competitor-analysis');
  }

  /**
   * Discover competitors for a clinic based on keywords and location
   */
  public async discoverCompetitors(options: CompetitorDiscoveryOptions): Promise<Competitor[]> {
    const cacheKey = `competitors:discovery:${options.clinicId}:${JSON.stringify(options)}`;
    const cached = await this.getFromCache<Competitor[]>(cacheKey);
    if (cached) return cached;

    try {
      this.logger.info('Starting competitor discovery', { clinicId: options.clinicId });

      const clinic = await Clinic.findByPk(options.clinicId);
      if (!clinic) {
        throw new Error('Clinic not found');
      }

      // Discover organic competitors
      const organicCompetitors = await this.discoverOrganicCompetitors(options);
      
      // Discover local competitors (if enabled)
      const localCompetitors = options.includeLocal 
        ? await this.discoverLocalCompetitors(options)
        : [];

      // Discover paid competitors (if enabled)
      const paidCompetitors = options.includePaid
        ? await this.discoverPaidCompetitors(options)
        : [];

      // Merge and deduplicate
      const allCompetitors = this.deduplicateCompetitors([
        ...organicCompetitors,
        ...localCompetitors,
        ...paidCompetitors
      ]);

      // Limit results
      const limitedCompetitors = allCompetitors.slice(0, options.maxCompetitors || 20);

      // Save discovered competitors
      const savedCompetitors = await this.saveDiscoveredCompetitors(
        options.clinicId,
        limitedCompetitors
      );

      // Cache results
      await this.setCache(cacheKey, savedCompetitors, 24 * 3600); // 24 hours

      this.logger.info('Competitor discovery completed', {
        clinicId: options.clinicId,
        competitorsFound: savedCompetitors.length
      });

      return savedCompetitors;

    } catch (error) {
      this.logger.error('Competitor discovery failed', {
        clinicId: options.clinicId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Analyze a specific competitor against the clinic
   */
  public async analyzeCompetitor(competitorId: string): Promise<CompetitorAnalysisResult> {
    const cacheKey = `competitor:analysis:${competitorId}`;
    const cached = await this.getFromCache<CompetitorAnalysisResult>(cacheKey);
    if (cached) return cached;

    try {
      const competitor = await Competitor.findByPk(competitorId);
      if (!competitor) {
        throw new Error('Competitor not found');
      }

      const clinic = await Clinic.findByPk(competitor.clinicId);
      if (!clinic) {
        throw new Error('Clinic not found');
      }

      this.logger.info('Starting competitor analysis', {
        competitorId,
        competitorDomain: competitor.domain
      });

      // Parallel analysis
      const [
        sharedKeywords,
        keywordGaps,
        contentAnalysis,
        technicalComparison
      ] = await Promise.all([
        this.analyzeSharedKeywords(clinic, competitor),
        this.analyzeKeywordGaps(clinic, competitor),
        this.analyzeContentGaps(clinic, competitor),
        this.analyzeTechnicalMetrics(clinic, competitor)
      ]);

      const analysis: CompetitorAnalysisResult = {
        competitor,
        analysis: {
          sharedKeywords,
          keywordGaps,
          contentGaps: contentAnalysis,
          technicalAdvantages: technicalComparison
        }
      };

      // Cache results
      await this.setCache(cacheKey, analysis, 6 * 3600); // 6 hours

      // Generate AI insights
      await this.generateCompetitorInsights(analysis);

      return analysis;

    } catch (error) {
      this.logger.error('Competitor analysis failed', {
        competitorId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Update competitor metrics
   */
  public async updateCompetitorMetrics(competitorId: string): Promise<void> {
    try {
      const competitor = await Competitor.findByPk(competitorId);
      if (!competitor) {
        throw new Error('Competitor not found');
      }

      // Check rate limits
      const rateLimitKey = `rate_limit:competitor_update:${competitor.domain}`;
      const canUpdate = await this.checkRateLimit(rateLimitKey, 10, 3600); // 10 updates per hour
      if (!canUpdate) {
        this.logger.warn('Rate limit exceeded for competitor update', { competitorId });
        return;
      }

      this.logger.info('Updating competitor metrics', {
        competitorId,
        domain: competitor.domain
      });

      // Fetch updated metrics from various sources
      const [serpMetrics, ahrefsMetrics, socialMetrics] = await Promise.all([
        this.serpApi.getDomainMetrics(competitor.domain),
        this.ahrefsApi.getDomainMetrics(competitor.domain),
        this.getSocialMetrics(competitor.domain)
      ]);

      // Merge metrics
      const updatedMetrics = {
        ...competitor.metrics,
        visibility: serpMetrics.visibility || competitor.metrics.visibility,
        estimatedTraffic: ahrefsMetrics.organicTraffic || competitor.metrics.estimatedTraffic,
        backlinks: ahrefsMetrics.backlinks || competitor.metrics.backlinks,
        domainAuthority: ahrefsMetrics.domainRating || competitor.metrics.domainAuthority,
        socialFollowers: socialMetrics || competitor.metrics.socialFollowers,
        lastUpdated: new Date().toISOString()
      };

      await competitor.updateMetrics(updatedMetrics);

      // Invalidate related caches
      await this.invalidateCache(`competitor:*:${competitorId}`);
      await this.invalidateCache(`clinic:dashboard:${competitor.clinicId}`);

      this.logger.info('Competitor metrics updated successfully', { competitorId });

    } catch (error) {
      this.logger.error('Failed to update competitor metrics', {
        competitorId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Queue competitor analysis job
   */
  public async queueCompetitorAnalysis(clinicId: string, competitorId?: string): Promise<void> {
    const jobData = {
      type: competitorId ? 'analyze_competitor' : 'analyze_all_competitors',
      clinicId,
      competitorId,
      priority: competitorId ? 'high' : 'medium'
    };

    await this.jobQueue.add('competitor-analysis', jobData, {
      attempts: 3,
      backoff: 'exponential',
      delay: competitorId ? 0 : 60000, // Immediate for single, 1 min delay for all
    });

    this.logger.info('Competitor analysis job queued', jobData);
  }

  // Private helper methods
  private async discoverOrganicCompetitors(options: CompetitorDiscoveryOptions): Promise<any[]> {
    const competitors = [];
    
    for (const keyword of options.keywords) {
      try {
        const serpResults = await this.serpApi.searchKeyword(keyword, options.location);
        const organicResults = serpResults.organic_results || [];
        
        organicResults.slice(0, 10).forEach((result: any) => {
          if (result.domain && !this.isOwnDomain(result.domain, options.clinicId)) {
            competitors.push({
              domain: result.domain,
              name: result.title || result.domain,
              source: 'organic',
              position: result.position,
              keyword,
              url: result.link
            });
          }
        });
      } catch (error) {
        this.logger.warn('Failed to get SERP results for keyword', { keyword, error: error.message });
      }
    }

    return competitors;
  }

  private async discoverLocalCompetitors(options: CompetitorDiscoveryOptions): Promise<any[]> {
    const competitors = [];
    
    try {
      const localResults = await this.serpApi.searchLocal(
        `dental clinic ${options.location}`,
        options.location
      );

      if (localResults.local_results) {
        localResults.local_results.forEach((result: any) => {
          if (result.website && !this.isOwnDomain(result.website, options.clinicId)) {
            competitors.push({
              domain: result.website,
              name: result.title,
              source: 'local',
              address: result.address,
              rating: result.rating,
              reviews: result.reviews
            });
          }
        });
      }
    } catch (error) {
      this.logger.warn('Failed to get local results', { error: error.message });
    }

    return competitors;
  }

  private async discoverPaidCompetitors(options: CompetitorDiscoveryOptions): Promise<any[]> {
    const competitors = [];

    for (const keyword of options.keywords) {
      try {
        const serpResults = await this.serpApi.searchKeyword(keyword, options.location);
        const adResults = serpResults.ads || [];

        adResults.forEach((ad: any) => {
          if (ad.domain && !this.isOwnDomain(ad.domain, options.clinicId)) {
            competitors.push({
              domain: ad.domain,
              name: ad.headline || ad.domain,
              source: 'paid',
              keyword,
              adText: ad.description
            });
          }
        });
      } catch (error) {
        this.logger.warn('Failed to get ad results for keyword', { keyword, error: error.message });
      }
    }

    return competitors;
  }

  private deduplicateCompetitors(competitors: any[]): any[] {
    const seen = new Set();
    return competitors.filter(competitor => {
      if (seen.has(competitor.domain)) {
        return false;
      }
      seen.add(competitor.domain);
      return true;
    });
  }

  private async saveDiscoveredCompetitors(clinicId: string, competitors: any[]): Promise<Competitor[]> {
    const savedCompetitors = [];

    for (const [index, comp] of competitors.entries()) {
      try {
        // Check if competitor already exists
        let competitor = await Competitor.findOne({
          where: { clinicId, domain: comp.domain }
        });

        if (!competitor) {
          // Create new competitor
          competitor = await Competitor.create({
            clinicId,
            name: comp.name,
            domain: comp.domain,
            marketPosition: index + 1,
            monitoringEnabled: true,
            metrics: {
              visibility: 0,
              estimatedTraffic: 0,
              backlinks: 0,
              domainAuthority: 0,
              socialFollowers: {}
            }
          });
        }

        savedCompetitors.push(competitor);
      } catch (error) {
        this.logger.warn('Failed to save competitor', {
          domain: comp.domain,
          error: error.message
        });
      }
    }

    return savedCompetitors;
  }

  private async isOwnDomain(domain: string, clinicId: string): Promise<boolean> {
    const clinic = await Clinic.findByPk(clinicId);
    return clinic ? clinic.domain === domain : false;
  }

  private async analyzeSharedKeywords(clinic: Clinic, competitor: Competitor): Promise<string[]> {
    // Implementation would analyze keywords both clinic and competitor rank for
    // This is a simplified version
    return clinic.targetKeywords.filter(keyword => 
      Math.random() > 0.5 // Simulate shared keywords
    );
  }

  private async analyzeKeywordGaps(clinic: Clinic, competitor: Competitor): Promise<any[]> {
    // Implementation would identify keywords competitor ranks for but clinic doesn't
    // This is a simplified version
    return [
      {
        keyword: "emergency dentist " + clinic.location.address.split(',')[1],
        competitorPosition: Math.floor(Math.random() * 10) + 1,
        clientPosition: null,
        searchVolume: Math.floor(Math.random() * 1000) + 100,
        difficulty: Math.floor(Math.random() * 100)
      }
    ];
  }

  private async analyzeContentGaps(clinic: Clinic, competitor: Competitor): Promise<any[]> {
    // AI-powered content gap analysis would go here
    return await this.aiInsights.analyzeContentGaps(clinic.domain, competitor.domain);
  }

  private async analyzeTechnicalMetrics(clinic: Clinic, competitor: Competitor): Promise<any[]> {
    // Technical comparison would go here
    return [
      {
        metric: 'Page Speed',
        competitorValue: Math.random() * 5 + 1,
        clientValue: Math.random() * 5 + 1,
        advantage: Math.random() > 0.5 ? 'competitor' : 'client'
      }
    ];
  }

  private async getSocialMetrics(domain: string): Promise<any> {
    // Social media metrics fetching would go here
    return {
      facebook: Math.floor(Math.random() * 5000),
      instagram: Math.floor(Math.random() * 3000),
      linkedin: Math.floor(Math.random() * 1000)
    };
  }

  private async generateCompetitorInsights(analysis: CompetitorAnalysisResult): Promise<void> {
    // Generate AI insights based on competitor analysis
    await this.aiInsights.generateCompetitorInsights(analysis);
  }
}
EOF

# Generate technical audit service
cat > src/services/technical-audit.service.ts << 'EOF'
import { BaseService } from './base.service';
import { TechnicalAudit } from '../models/technical-audit.model';
import { Clinic } from '../models/clinic.model';
import { JobQueue } from '../utils/job-queue';
import lighthouse from 'lighthouse';
import puppeteer from 'puppeteer-extra';
import StealthPlugin from 'puppeteer-extra-plugin-stealth';

puppeteer.use(StealthPlugin());

export interface TechnicalAuditOptions {
  clinicId: string;
  auditType: 'basic' | 'comprehensive' | 'performance' | 'seo';
  pages: string[];
  includeCompetitorComparison?: boolean;
}

export interface AuditMetrics {
  siteSpeed: {
    desktop: {
      score: number;
      loadTime: number;
      firstContentfulPaint: number;
      largestContentfulPaint: number;
      firstInputDelay: number;
      cumulativeLayoutShift: number;
    };
    mobile: {
      score: number;
      loadTime: number;
      firstContentfulPaint: number;
      largestContentfulPaint: number;
      firstInputDelay: number;
      cumulativeLayoutShift: number;
    };
  };
  crawlability: {
    score: number;
    robotsTxt: boolean;
    sitemapValid: boolean;
    crawlErrors: number;
    indexablePages: number;
    blockedPages: number;
  };
  schemaMarkup: {
    score: number;
    localBusinessSchema: boolean;
    dentistSchema: boolean;
    faqSchema: boolean;
    reviewSchema: boolean;
    validationErrors: number;
  };
  mobileOptimization: {
    score: number;
    responsiveDesign: boolean;
    mobileFirstIndex: boolean;
    touchTargetSize: boolean;
    viewportConfiguration: boolean;
  };
}

export class TechnicalAuditService extends BaseService {
  private jobQueue: JobQueue;

  constructor() {
    super('TechnicalAuditService');
    this.jobQueue = new JobQueue('technical-audits');
  }

  /**
   * Queue a technical audit job
   */
  public async queueAudit(options: TechnicalAuditOptions): Promise<any> {
    const jobData = {
      ...options,
      priority: options.auditType === 'comprehensive' ? 'high' : 'medium'
    };

    const job = await this.jobQueue.add('technical-audit', jobData, {
      attempts: 2,
      backoff: 'exponential',
      timeout: 10 * 60 * 1000, // 10 minutes
    });

    this.logger.info('Technical audit job queued', {
      jobId: job.id,
      clinicId: options.clinicId,
      auditType: options.auditType
    });

    return job;
  }

  /**
   * Perform comprehensive technical audit
   */
  public async performAudit(options: TechnicalAuditOptions): Promise<TechnicalAudit> {
    try {
      this.logger.info('Starting technical audit', {
        clinicId: options.clinicId,
        auditType: options.auditType,
        pages: options.pages.length
      });

      const clinic = await Clinic.findByPk(options.clinicId);
      if (!clinic) {
        throw new Error('Clinic not found');
      }

      // Perform audits for each page
      const pageAudits = await Promise.all(
        options.pages.map(url => this.auditPage(url, options.auditType))
      );

      // Aggregate results
      const aggregatedMetrics = this.aggregateAuditResults(pageAudits);
      const overallScore = this.calculateOverallScore(aggregatedMetrics);
      const issues = this.identifyIssues(aggregatedMetrics);
      const recommendations = this.generateRecommendations(aggregatedMetrics, issues);

      // Save audit results
      const audit = await TechnicalAudit.create({
        clinicId: options.clinicId,
        auditType: options.auditType,
        score: overallScore,
        metrics: aggregatedMetrics,
        issues,
        recommendations,
        rawData: pageAudits
      });

      // Invalidate cache
      await this.invalidateCache(`clinic:dashboard:${options.clinicId}`);
      await this.invalidateCache(`clinic:audit:${options.clinicId}`);

      this.logger.info('Technical audit completed', {
        auditId: audit.id,
        clinicId: options.clinicId,
        score: overallScore
      });

      return audit;

    } catch (error) {
      this.logger.error('Technical audit failed', {
        clinicId: options.clinicId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Audit a single page
   */
  private async auditPage(url: string, auditType: string): Promise<any> {
    const browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    try {
      const page = await browser.newPage();
      
      // Set viewport and user agent
      await page.setViewport({ width: 1200, height: 800 });
      await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');

      this.logger.info('Auditing page', { url, auditType });

      // Parallel audits based on type
      const auditPromises = [];

      if (auditType === 'comprehensive' || auditType === 'performance') {
        auditPromises.push(this.auditPageSpeed(page, url));
      }

      if (auditType === 'comprehensive' || auditType === 'seo') {
        auditPromises.push(this.auditSEOElements(page, url));
        auditPromises.push(this.auditSchemaMarkup(page, url));
      }

      if (auditType === 'comprehensive') {
        auditPromises.push(this.auditCrawlability(page, url));
        auditPromises.push(this.auditMobileOptimization(page, url));
      }

      const results = await Promise.all(auditPromises);
      
      return {
        url,
        timestamp: new Date().toISOString(),
        results: results.reduce((acc, result) => ({ ...acc, ...result }), {})
      };

    } finally {
      await browser.close();
    }
  }

  /**
   * Audit page speed using Lighthouse
   */
  private async auditPageSpeed(page: any, url: string): Promise<any> {
    try {
      // Desktop audit
      const desktopResult = await lighthouse(url, {
        port: 9222,
        output: 'json',
        logLevel: 'error',
        emulatedFormFactor: 'desktop',
        throttling: {
          rttMs: 40,
          throughputKbps: 10240,
          cpuSlowdownMultiplier: 1
        }
      });

      // Mobile audit
      const mobileResult = await lighthouse(url, {
        port: 9222,
        output: 'json',
        logLevel: 'error',
        emulatedFormFactor: 'mobile',
        throttling: {
          rttMs: 150,
          throughputKbps: 1638.4,
          cpuSlowdownMultiplier: 4
        }
      });

      return {
        siteSpeed: {
          desktop: {
            score: desktopResult.lhr.categories.performance.score * 100,
            loadTime: desktopResult.lhr.audits['speed-index'].numericValue,
            firstContentfulPaint: desktopResult.lhr.audits['first-contentful-paint'].numericValue,
            largestContentfulPaint: desktopResult.lhr.audits['largest-contentful-paint'].numericValue,
            firstInputDelay: desktopResult.lhr.audits['max-potential-fid'].numericValue,
            cumulativeLayoutShift: desktopResult.lhr.audits['cumulative-layout-shift'].numericValue
          },
          mobile: {
            score: mobileResult.lhr.categories.performance.score * 100,
            loadTime: mobileResult.lhr.audits['speed-index'].numericValue,
            firstContentfulPaint: mobileResult.lhr.audits['first-contentful-paint'].numericValue,
            largestContentfulPaint: mobileResult.lhr.audits['largest-contentful-paint'].numericValue,
            firstInputDelay: mobileResult.lhr.audits['max-potential-fid'].numericValue,
            cumulativeLayoutShift: mobileResult.lhr.audits['cumulative-layout-shift'].numericValue
          }
        }
      };
    } catch (error) {
      this.logger.warn('Page speed audit failed', { url, error: error.message });
      return { siteSpeed: null };
    }
  }

  /**
   * Audit SEO elements
   */
  private async auditSEOElements(page: any, url: string): Promise<any> {
    await page.goto(url, { waitUntil: 'networkidle0' });

    const seoData = await page.evaluate(() => {
      return {
        title: document.title,
        metaDescription: document.querySelector('meta[name="description"]')?.getAttribute('content'),
        h1Count: document.querySelectorAll('h1').length,
        h2Count: document.querySelectorAll('h2').length,
        imgCount: document.querySelectorAll('img').length,
        imgAltMissing: document.querySelectorAll('img:not([alt])').length,
        internalLinks: document.querySelectorAll('a[href^="/"], a[href*="' + location.hostname + '"]').length,
        externalLinks: document.querySelectorAll('a[href^="http"]:not([href*="' + location.hostname + '"])').length,
        canonicalUrl: document.querySelector('link[rel="canonical"]')?.getAttribute('href'),
        robots: document.querySelector('meta[name="robots"]')?.getAttribute('content')
      };
    });

    return { seoElements: seoData };
  }

  /**
   * Audit schema markup
   */
  private async auditSchemaMarkup(page: any, url: string): Promise<any> {
    await page.goto(url, { waitUntil: 'networkidle0' });

    const schemaData = await page.evaluate(() => {
      const jsonLdScripts = Array.from(document.querySelectorAll('script[type="application/ld+json"]'));
      const schemas = jsonLdScripts.map(script => {
        try {
          return JSON.parse(script.textContent || '');
        } catch {
          return null;
        }
      }).filter(Boolean);

      return {
        localBusinessSchema: schemas.some(s => s['@type'] === 'LocalBusiness' || s['@type'] === 'DentalClinic'),
        dentistSchema: schemas.some(s => s['@type'] === 'Dentist' || s['@type'] === 'DentalClinic'),
        faqSchema: schemas.some(s => s['@type'] === 'FAQPage'),
        reviewSchema: schemas.some(s => s.review || s.aggregateRating),
        organizationSchema: schemas.some(s => s['@type'] === 'Organization'),
        schemas: schemas
      };
    });

    const score = this.calculateSchemaScore(schemaData);

    return {
      schemaMarkup: {
        ...schemaData,
        score,
        validationErrors: 0 // Would implement schema validation
      }
    };
  }

  /**
   * Audit crawlability
   */
  private async auditCrawlability(page: any, url: string): Promise<any> {
    const domain = new URL(url).origin;
    
    try {
      // Check robots.txt
      const robotsResponse = await page.goto(`${domain}/robots.txt`);
      const robotsTxt = robotsResponse.status() === 200;

      // Check sitemap
      const sitemapResponse = await page.goto(`${domain}/sitemap.xml`);
      const sitemapValid = sitemapResponse.status() === 200;

      return {
        crawlability: {
          score: 85 + (robotsTxt ? 10 : 0) + (sitemapValid ? 5 : 0),
          robotsTxt,
          sitemapValid,
          crawlErrors: 0, // Would implement crawl error detection
          indexablePages: 0, // Would implement page counting
          blockedPages: 0
        }
      };
    } catch (error) {
      return {
        crawlability: {
          score: 60,
          robotsTxt: false,
          sitemapValid: false,
          crawlErrors: 1,
          indexablePages: 0,
          blockedPages: 0
        }
      };
    }
  }

  /**
   * Audit mobile optimization
   */
  private async auditMobileOptimization(page: any, url: string): Promise<any> {
    await page.setViewport({ width: 375, height: 667 }); // iPhone viewport
    await page.goto(url, { waitUntil: 'networkidle0' });

    const mobileData = await page.evaluate(() => {
      const viewport = document.querySelector('meta[name="viewport"]');
      const viewportContent = viewport?.getAttribute('content') || '';
      
      return {
        viewportConfiguration: viewportContent.includes('width=device-width'),
        responsiveDesign: window.innerWidth <= 768,
        touchTargetSize: true, // Would implement touch target size check
        mobileFirstIndex: true // Would check for mobile-first indexing signals
      };
    });

    const score = Object.values(mobileData).filter(Boolean).length * 25;

    return {
      mobileOptimization: {
        ...mobileData,
        score
      }
    };
  }

  // Helper methods
  private aggregateAuditResults(pageAudits: any[]): AuditMetrics {
    // Aggregate metrics from multiple pages
    // This is a simplified version - would implement proper aggregation
    const firstPage = pageAudits[0]?.results || {};
    
    return {
      siteSpeed: firstPage.siteSpeed || { desktop: {}, mobile: {} },
      crawlability: firstPage.crawlability || {},
      schemaMarkup: firstPage.schemaMarkup || {},
      mobileOptimization: firstPage.mobileOptimization || {}
    } as AuditMetrics;
  }

  private calculateOverallScore(metrics: AuditMetrics): number {
    const scores = [
      metrics.siteSpeed?.desktop?.score || 0,
      metrics.siteSpeed?.mobile?.score || 0,
      metrics.crawlability?.score || 0,
      metrics.schemaMarkup?.score || 0,
      metrics.mobileOptimization?.score || 0
    ];

    return Math.round(scores.reduce((sum, score) => sum + score, 0) / scores.length);
  }

  private calculateSchemaScore(schemaData: any): number {
    let score = 0;
    if (schemaData.localBusinessSchema) score += 30;
    if (schemaData.dentistSchema) score += 25;
    if (schemaData.faqSchema) score += 20;
    if (schemaData.reviewSchema) score += 15;
    if (schemaData.organizationSchema) score += 10;
    return score;
  }

  private identifyIssues(metrics: AuditMetrics): any[] {
    const issues = [];

    // Performance issues
    if (metrics.siteSpeed?.desktop?.score < 70) {
      issues.push({
        severity: 'high',
        category: 'performance',
        title: 'Poor desktop performance',
        description: 'Desktop page speed score is below recommended threshold',
        affectedPages: ['All pages'],
        recommendation: 'Optimize images, minify CSS/JS, enable compression'
      });
    }

    // Schema issues
    if (!metrics.schemaMarkup?.localBusinessSchema) {
      issues.push({
        severity: 'medium',
        category: 'schema',
        title: 'Missing LocalBusiness schema',
        description: 'LocalBusiness schema markup not detected',
        affectedPages: ['Homepage'],
        recommendation: 'Add LocalBusiness schema markup'
      });
    }

    return issues;
  }

  private generateRecommendations(metrics: AuditMetrics, issues: any[]): any[] {
    const recommendations = [];

    // High priority recommendations
    if (metrics.siteSpeed?.mobile?.score < 60) {
      recommendations.push({
        priority: 'high',
        category: 'performance',
        title: 'Improve mobile page speed',
        description: 'Mobile page speed significantly impacts rankings',
        expectedImpact: 'Potential 10-15% ranking improvement',
        effort: 'medium'
      });
    }

    // Schema recommendations
    if (metrics.schemaMarkup?.score < 80) {
      recommendations.push({
        priority: 'medium',
        category: 'schema',
        title: 'Enhance schema markup',
        description: 'Add missing schema types for better rich snippets',
        expectedImpact: 'Improved SERP appearance',
        effort: 'low'
      });
    }

    return recommendations;
  }
}
EOF

echo "✅ Business services generated"
echo "📁 Services created:"
echo "   • src/services/base.service.ts - Base service class"
echo "   • src/services/competitor-analysis.service.ts - Competitor intelligence"
echo "   • src/services/technical-audit.service.ts - Technical SEO audits"
echo "🔄 Ready for AI services and workers generation"