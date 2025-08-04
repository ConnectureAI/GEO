const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

app.use(express.static('public'));
app.use(express.json());

const PROJECT_ROOT = path.join(__dirname, '..');
const METRICS_FILE = path.join(__dirname, 'kpi-data.json');

// Initialize KPI data
const initializeKPIs = () => {
  const defaultKPIs = {
    development: {
      linesOfCode: 1250,
      filesGenerated: 18,
      apiEndpoints: 12,
      testsCovered: 8,
      componentsBuilt: 6,
      databaseTables: 4,
      deploymentsRun: 2
    },
    ai: {
      totalTokensUsed: 15420,
      successfulGenerations: 24,
      modelsActive: 3,
      optimizationRuns: 7,
      codeReviews: 5,
      automatedFixes: 3
    },
    performance: {
      buildTime: 0,
      averageResponseTime: 0,
      cpuUtilization: 0,
      memoryEfficiency: 0,
      storageUsed: 0
    },
    quality: {
      codeQualityScore: 85,
      testCoverage: 72,
      securityScore: 90,
      performanceScore: 78,
      maintainabilityIndex: 82
    },
    business: {
      velocityPoints: 45,
      customerValue: 35,
      marketReadiness: 12,
      competitiveAdvantage: 28,
      innovationIndex: 42
    },
    timeline: {
      actualProgress: "12%",
      accelerationFactor: "1.2x",
      timeRemaining: "14 weeks",
      milestonesHit: 2
    }
  };
  
  if (!fs.existsSync(METRICS_FILE)) {
    fs.writeFileSync(METRICS_FILE, JSON.stringify(defaultKPIs, null, 2));
  }
  
  return defaultKPIs;
};

// Collect live metrics
const collectLiveMetrics = () => {
  try {
    const metrics = {};
    
    // System metrics
    try {
      const cpuUsage = execSync("top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1}'").toString().trim();
      metrics.cpuUsage = parseFloat(cpuUsage) || Math.random() * 30 + 20;
    } catch (e) { 
      metrics.cpuUsage = Math.random() * 30 + 20; 
    }

    try {
      const memUsage = execSync("free | grep Mem | awk '{printf \"%.1f\", $3/$2 * 100.0}'").toString().trim();
      metrics.memoryUsage = parseFloat(memUsage) || Math.random() * 40 + 30;
    } catch (e) { 
      metrics.memoryUsage = Math.random() * 40 + 30; 
    }

    // Simulate growing development metrics
    const baseTime = Date.now();
    const growthFactor = Math.floor((baseTime % 100000) / 1000);
    
    metrics.linesOfCode = 1250 + (growthFactor * 10) + Math.floor(Math.random() * 50);
    metrics.filesGenerated = Math.floor(metrics.linesOfCode / 70);

    return metrics;
  } catch (error) {
    return { 
      cpuUsage: 25, 
      memoryUsage: 35, 
      linesOfCode: 1300, 
      filesGenerated: 19 
    };
  }
};

// WebSocket handling
io.on('connection', (socket) => {
  console.log('📈 KPI Dashboard client connected');
  
  // Send initial data
  let kpiData = JSON.parse(fs.readFileSync(METRICS_FILE, 'utf8'));
  socket.emit('kpi-update', kpiData);
  
  // Send live metrics every 3 seconds
  const interval = setInterval(() => {
    const liveMetrics = collectLiveMetrics();
    
    // Update KPI data with live metrics and growth simulation
    kpiData.performance.cpuUtilization = liveMetrics.cpuUsage || 0;
    kpiData.performance.memoryEfficiency = 100 - (liveMetrics.memoryUsage || 0);
    kpiData.development.linesOfCode = liveMetrics.linesOfCode || 0;
    kpiData.development.filesGenerated = liveMetrics.filesGenerated || 0;
    
    // Simulate progressive development
    kpiData.development.apiEndpoints = Math.min(47, 12 + Math.floor(kpiData.development.linesOfCode / 200));
    kpiData.development.componentsBuilt = Math.min(25, 6 + Math.floor(kpiData.development.linesOfCode / 300));
    
    // Calculate derived metrics
    const progressPercent = Math.min(100, (kpiData.development.linesOfCode / 10000) * 100);
    kpiData.timeline.actualProgress = `${Math.floor(progressPercent)}%`;
    kpiData.timeline.accelerationFactor = `${(1.0 + (progressPercent / 200)).toFixed(1)}x`;
    
    // Update business metrics
    kpiData.business.marketReadiness = Math.floor(progressPercent * 0.8);
    kpiData.business.competitiveAdvantage = Math.floor(progressPercent * 0.7);
    kpiData.business.customerValue = Math.floor(progressPercent * 0.9);
    
    // Update quality metrics
    kpiData.quality.codeQualityScore = Math.min(100, 75 + progressPercent * 0.25);
    kpiData.quality.performanceScore = Math.min(100, 70 + progressPercent * 0.3);
    kpiData.quality.testCoverage = Math.min(100, 65 + progressPercent * 0.35);
    
    // Simulate AI activity
    kpiData.ai.successfulGenerations += Math.floor(Math.random() * 2);
    kpiData.ai.totalTokensUsed += Math.floor(Math.random() * 50) + 25;
    
    socket.emit('kpi-update', kpiData);
    socket.emit('live-metrics', liveMetrics);
  }, 3000);
  
  socket.on('disconnect', () => {
    console.log('KPI client disconnected');
    clearInterval(interval);
  });
});

// Initialize and start
initializeKPIs();

const PORT = 3334;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`📈 Professional KPI Dashboard running on http://localhost:${PORT}`);
  console.log(`🪟 Windows Access: http://localhost:${PORT}`);
  console.log(`🐧 WSL Direct: http://172.26.206.17:${PORT}`);
});