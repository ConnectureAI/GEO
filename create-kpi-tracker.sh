#!/bin/bash
# ============================================================================
# KPI Tracking and Metrics Collection System
# Professional Development Analytics
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METRICS_DIR="$PROJECT_ROOT/metrics"
STATE_DIR="$PROJECT_ROOT/.dev-state"

mkdir -p "$METRICS_DIR"

# Create KPI tracking server
cat > "$METRICS_DIR/kpi-server.js" << 'EOF'
const express = require('express');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const app = express();
app.use(express.json());
app.use(express.static('public'));

const PROJECT_ROOT = path.join(__dirname, '..');
const STATE_FILE = path.join(PROJECT_ROOT, '.dev-state', 'development.json');
const METRICS_FILE = path.join(__dirname, 'kpi-data.json');

// Initialize KPI data structure
const initializeKPIs = () => {
  const defaultKPIs = {
    development: {
      linesOfCode: 0,
      filesGenerated: 0,
      apiEndpoints: 0,
      testsCovered: 0,
      bugsFixed: 0,
      componentsBuilt: 0,
      databaseTables: 0,
      deploymentsRun: 0
    },
    ai: {
      totalTokensUsed: 0,
      successfulGenerations: 0,
      failedGenerations: 0,
      modelsActive: 0,
      optimizationRuns: 0,
      codeReviews: 0,
      automatedFixes: 0
    },
    performance: {
      buildTime: 0,
      testExecutionTime: 0,
      averageResponseTime: 0,
      cpuUtilization: 0,
      memoryEfficiency: 0,
      storageUsed: 0
    },
    productivity: {
      featuresCompleted: 0,
      modulesFinished: 0,
      issuesResolved: 0,
      codeReviewsConducted: 0,
      documentationPages: 0,
      timeToCompletion: 0
    },
    quality: {
      codeQualityScore: 0,
      testCoverage: 0,
      securityScore: 0,
      performanceScore: 0,
      maintainabilityIndex: 0,
      technicalDebt: 0
    },
    business: {
      velocityPoints: 0,
      customerValue: 0,
      riskMitigation: 0,
      innovationIndex: 0,
      competitiveAdvantage: 0,
      marketReadiness: 0
    },
    timeline: {
      plannedCompletion: "16 weeks",
      actualProgress: "0%",
      accelerationFactor: "1.0x",
      timeRemaining: "16 weeks",
      milestonesHit: 0,
      blockersCleard: 0
    },
    history: []
  };
  
  if (!fs.existsSync(METRICS_FILE)) {
    fs.writeFileSync(METRICS_FILE, JSON.stringify(defaultKPIs, null, 2));
  }
  
  return defaultKPIs;
};

// Collect system metrics
const collectSystemMetrics = () => {
  try {
    const metrics = {};
    
    // CPU usage
    try {
      const cpuUsage = execSync("top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1}'").toString().trim();
      metrics.cpuUsage = parseFloat(cpuUsage) || 0;
    } catch (e) { metrics.cpuUsage = 0; }
    
    // Memory usage
    try {
      const memUsage = execSync("free | grep Mem | awk '{printf \"%.1f\", $3/$2 * 100.0}'").toString().trim();
      metrics.memoryUsage = parseFloat(memUsage) || 0;
    } catch (e) { metrics.memoryUsage = 0; }
    
    // Disk usage
    try {
      const diskUsage = execSync("df -h . | tail -1 | awk '{print $5}' | sed 's/%//'").toString().trim();
      metrics.diskUsage = parseFloat(diskUsage) || 0;
    } catch (e) { metrics.diskUsage = 0; }
    
    // Process count
    try {
      const processCount = execSync("ps aux | wc -l").toString().trim();
      metrics.processCount = parseInt(processCount) || 0;
    } catch (e) { metrics.processCount = 0; }
    
    // Network connections
    try {
      const netConnections = execSync("netstat -an | grep ESTABLISHED | wc -l").toString().trim();
      metrics.networkConnections = parseInt(netConnections) || 0;
    } catch (e) { metrics.networkConnections = 0; }
    
    return metrics;
  } catch (error) {
    console.error('Error collecting system metrics:', error);
    return {};
  }
};

// Analyze code metrics
const analyzeCodeMetrics = () => {
  try {
    const metrics = {};
    const srcDir = path.join(PROJECT_ROOT, 'src');
    
    if (fs.existsSync(srcDir)) {
      // Count lines of code
      try {
        const loc = execSync(`find ${srcDir} -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" | xargs wc -l | tail -1 | awk '{print $1}'`).toString().trim();
        metrics.linesOfCode = parseInt(loc) || 0;
      } catch (e) { metrics.linesOfCode = 0; }
      
      // Count files
      try {
        const fileCount = execSync(`find ${srcDir} -type f \\( -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" \\) | wc -l`).toString().trim();
        metrics.filesGenerated = parseInt(fileCount) || 0;
      } catch (e) { metrics.filesGenerated = 0; }
      
      // Count API endpoints (rough estimate)
      try {
        const endpoints = execSync(`grep -r "app\\." ${srcDir} | grep -E "(get|post|put|delete)" | wc -l`).toString().trim();
        metrics.apiEndpoints = parseInt(endpoints) || 0;
      } catch (e) { metrics.apiEndpoints = 0; }
    }
    
    return metrics;
  } catch (error) {
    console.error('Error analyzing code metrics:', error);
    return {};
  }
};

// Calculate business metrics
const calculateBusinessMetrics = (kpiData) => {
  const totalFeatures = 25; // Estimated total features for SEO platform
  const targetCompletion = 16; // weeks
  
  const businessMetrics = {
    velocityPoints: Math.floor((kpiData.development.filesGenerated / 10) * 10),
    customerValue: Math.floor((kpiData.development.apiEndpoints / 50) * 100),
    riskMitigation: Math.min(100, kpiData.quality.testCoverage + kpiData.quality.securityScore),
    innovationIndex: Math.floor((kpiData.ai.successfulGenerations / 100) * 100),
    competitiveAdvantage: Math.floor(((kpiData.development.linesOfCode / 10000) * 50) + ((kpiData.ai.modelsActive / 3) * 50)),
    marketReadiness: Math.floor((kpiData.productivity.featuresCompleted / totalFeatures) * 100)
  };
  
  return businessMetrics;
};

// API Routes
app.get('/api/kpis', (req, res) => {
  try {
    const kpiData = JSON.parse(fs.readFileSync(METRICS_FILE, 'utf8'));
    res.json(kpiData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/metrics/live', (req, res) => {
  try {
    const systemMetrics = collectSystemMetrics();
    const codeMetrics = analyzeCodeMetrics();
    
    res.json({
      system: systemMetrics,
      code: codeMetrics,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/kpis/update', (req, res) => {
  try {
    const updates = req.body;
    const kpiData = JSON.parse(fs.readFileSync(METRICS_FILE, 'utf8'));
    
    // Update KPIs with new data
    Object.keys(updates).forEach(category => {
      if (kpiData[category]) {
        Object.assign(kpiData[category], updates[category]);
      }
    });
    
    // Add timestamp to history
    kpiData.history.push({
      timestamp: new Date().toISOString(),
      snapshot: JSON.parse(JSON.stringify(kpiData))
    });
    
    // Keep only last 100 history entries
    if (kpiData.history.length > 100) {
      kpiData.history = kpiData.history.slice(-100);
    }
    
    fs.writeFileSync(METRICS_FILE, JSON.stringify(kpiData, null, 2));
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Automated KPI collection
setInterval(() => {
  try {
    const kpiData = JSON.parse(fs.readFileSync(METRICS_FILE, 'utf8'));
    const systemMetrics = collectSystemMetrics();
    const codeMetrics = analyzeCodeMetrics();
    
    // Update performance metrics
    kpiData.performance.cpuUtilization = systemMetrics.cpuUsage || 0;
    kpiData.performance.memoryEfficiency = 100 - (systemMetrics.memoryUsage || 0);
    kpiData.performance.storageUsed = systemMetrics.diskUsage || 0;
    
    // Update development metrics
    kpiData.development.linesOfCode = codeMetrics.linesOfCode || 0;
    kpiData.development.filesGenerated = codeMetrics.filesGenerated || 0;
    kpiData.development.apiEndpoints = codeMetrics.apiEndpoints || 0;
    
    // Calculate derived metrics
    kpiData.quality.codeQualityScore = Math.min(100, 
      (kpiData.development.linesOfCode / 100) + 
      (kpiData.development.testsCovered * 2) + 
      30 // Base quality score
    );
    
    kpiData.productivity.timeToCompletion = Math.max(0, 16 - (
      (kpiData.development.linesOfCode / 10000) * 16
    ));
    
    // Update timeline metrics
    const progressPercent = Math.min(100, (kpiData.development.linesOfCode / 10000) * 100);
    kpiData.timeline.actualProgress = `${Math.floor(progressPercent)}%`;
    kpiData.timeline.accelerationFactor = `${(1 + (progressPercent / 100)).toFixed(1)}x`;
    
    // Calculate business metrics
    const businessMetrics = calculateBusinessMetrics(kpiData);
    Object.assign(kpiData.business, businessMetrics);
    
    fs.writeFileSync(METRICS_FILE, JSON.stringify(kpiData, null, 2));
  } catch (error) {
    console.error('Error updating KPIs:', error);
  }
}, 30000); // Update every 30 seconds

// Initialize and start server
initializeKPIs();

const PORT = process.env.KPI_PORT || 3334;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`📈 KPI Tracking Server running on http://localhost:${PORT}`);
  console.log(`🪟 Windows Access: http://localhost:${PORT}`);
  console.log(`🐧 WSL Access: http://$(hostname -I | awk '{print $1}'):${PORT}`);
});
EOF

# Create package.json for KPI server
cat > "$METRICS_DIR/package.json" << 'EOF'
{
  "name": "seo-kpi-tracker",
  "version": "1.0.0",
  "description": "Professional KPI Tracking and Metrics Collection",
  "main": "kpi-server.js",
  "scripts": {
    "start": "node kpi-server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF

# Create KPI visualization dashboard
mkdir -p "$METRICS_DIR/public"

cat > "$METRICS_DIR/public/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SEO Platform - KPI Analytics Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: white;
            min-height: 100vh;
        }

        .header {
            background: rgba(0, 0, 0, 0.3);
            padding: 20px;
            text-align: center;
            border-bottom: 2px solid rgba(255, 255, 255, 0.1);
        }

        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
        }

        .header p {
            font-size: 1.2em;
            opacity: 0.9;
        }

        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            padding: 20px;
            max-width: 1400px;
            margin: 0 auto;
        }

        .kpi-card {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 20px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }

        .kpi-card h3 {
            margin-bottom: 15px;
            color: #ffd700;
            font-size: 1.4em;
            text-align: center;
        }

        .metric-row {
            display: flex;
            justify-content: space-between;
            margin: 10px 0;
            padding: 8px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 8px;
        }

        .metric-value {
            font-weight: bold;
            color: #00ff88;
        }

        .chart-container {
            position: relative;
            height: 200px;
            margin-top: 15px;
        }

        .big-metric {
            text-align: center;
            font-size: 3em;
            font-weight: bold;
            color: #00ff88;
            text-shadow: 0 0 20px rgba(0, 255, 136, 0.5);
        }

        .progress-ring {
            width: 120px;
            height: 120px;
            margin: 0 auto;
            position: relative;
        }

        .progress-ring svg {
            width: 100%;
            height: 100%;
            transform: rotate(-90deg);
        }

        .progress-ring circle {
            fill: none;
            stroke-width: 8;
        }

        .progress-ring .background {
            stroke: rgba(255, 255, 255, 0.2);
        }

        .progress-ring .progress {
            stroke: #00ff88;
            stroke-linecap: round;
            transition: stroke-dasharray 0.5s ease;
        }

        .ring-text {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            font-size: 1.2em;
            font-weight: bold;
        }

        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 8px;
        }

        .status-excellent { background: #00ff88; }
        .status-good { background: #ffd700; }
        .status-warning { background: #ff8800; }
        .status-critical { background: #ff4444; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🎯 SEO Intelligence Platform</h1>
        <p>AI-Powered Development Analytics & KPI Dashboard</p>
    </div>

    <div class="kpi-grid">
        <!-- Executive Summary -->
        <div class="kpi-card">
            <h3>📊 Executive Summary</h3>
            <div class="progress-ring">
                <svg>
                    <circle class="background" cx="60" cy="60" r="50"></circle>
                    <circle class="progress" cx="60" cy="60" r="50" id="overall-progress-ring"></circle>
                </svg>
                <div class="ring-text" id="overall-progress-text">0%</div>
            </div>
            <div style="text-align: center; margin-top: 10px;">
                <div>Overall Project Progress</div>
            </div>
        </div>

        <!-- Development Metrics -->
        <div class="kpi-card">
            <h3>💻 Development Metrics</h3>
            <div class="metric-row">
                <span><span class="status-indicator status-excellent"></span>Lines of Code</span>
                <span class="metric-value" id="lines-of-code">0</span>
            </div>
            <div class="metric-row">
                <span><span class="status-indicator status-good"></span>Files Generated</span>
                <span class="metric-value" id="files-generated">0</span>
            </div>
            <div class="metric-row">
                <span><span class="status-indicator status-excellent"></span>API Endpoints</span>
                <span class="metric-value" id="api-endpoints">0</span>
            </div>
            <div class="metric-row">
                <span><span class="status-indicator status-good"></span>Components Built</span>
                <span class="metric-value" id="components-built">0</span>
            </div>
        </div>

        <!-- AI Performance -->
        <div class="kpi-card">
            <h3>🤖 AI Performance</h3>
            <div class="metric-row">
                <span>Successful Generations</span>
                <span class="metric-value" id="ai-success">0</span>
            </div>
            <div class="metric-row">
                <span>Models Active</span>
                <span class="metric-value" id="ai-models">0</span>
            </div>
            <div class="metric-row">
                <span>Optimization Runs</span>
                <span class="metric-value" id="ai-optimizations">0</span>
            </div>
            <div class="metric-row">
                <span>Code Reviews</span>
                <span class="metric-value" id="ai-reviews">0</span>
            </div>
        </div>

        <!-- Timeline & Velocity -->
        <div class="kpi-card">
            <h3>⏱️ Timeline & Velocity</h3>
            <div class="big-metric" id="acceleration-factor">1.0x</div>
            <div style="text-align: center; margin: 10px 0;">Acceleration Factor</div>
            <div class="metric-row">
                <span>Time Remaining</span>
                <span class="metric-value" id="time-remaining">16 weeks</span>
            </div>
            <div class="metric-row">
                <span>Milestones Hit</span>
                <span class="metric-value" id="milestones">0/8</span>
            </div>
        </div>

        <!-- Quality Metrics -->
        <div class="kpi-card">
            <h3>🎯 Quality Metrics</h3>
            <div class="chart-container">
                <canvas id="quality-chart"></canvas>
            </div>
        </div>

        <!-- Business Impact -->
        <div class="kpi-card">
            <h3>📈 Business Impact</h3>
            <div class="metric-row">
                <span>Customer Value</span>
                <span class="metric-value" id="customer-value">0%</span>
            </div>
            <div class="metric-row">
                <span>Market Readiness</span>
                <span class="metric-value" id="market-readiness">0%</span>
            </div>
            <div class="metric-row">
                <span>Competitive Advantage</span>
                <span class="metric-value" id="competitive-advantage">0%</span>
            </div>
            <div class="metric-row">
                <span>Innovation Index</span>
                <span class="metric-value" id="innovation-index">0</span>
            </div>
        </div>
    </div>

    <script>
        // Initialize quality chart
        const qualityCtx = document.getElementById('quality-chart').getContext('2d');
        const qualityChart = new Chart(qualityCtx, {
            type: 'radar',
            data: {
                labels: ['Code Quality', 'Test Coverage', 'Security', 'Performance', 'Maintainability'],
                datasets: [{
                    label: 'Quality Metrics',
                    data: [0, 0, 0, 0, 0],
                    fill: true,
                    backgroundColor: 'rgba(0, 255, 136, 0.2)',
                    borderColor: '#00ff88',
                    pointBackgroundColor: '#00ff88',
                    pointBorderColor: '#fff',
                    pointHoverBackgroundColor: '#fff',
                    pointHoverBorderColor: '#00ff88'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    r: {
                        angleLines: { color: 'rgba(255, 255, 255, 0.2)' },
                        grid: { color: 'rgba(255, 255, 255, 0.2)' },
                        pointLabels: { color: 'white' },
                        ticks: { 
                            color: 'white',
                            backdropColor: 'transparent'
                        },
                        min: 0,
                        max: 100
                    }
                },
                plugins: {
                    legend: { labels: { color: 'white' } }
                }
            }
        });

        // Update progress ring
        function updateProgressRing(percentage) {
            const circle = document.getElementById('overall-progress-ring');
            const radius = 50;
            const circumference = 2 * Math.PI * radius;
            const offset = circumference - (percentage / 100) * circumference;
            
            circle.style.strokeDasharray = circumference;
            circle.style.strokeDashoffset = offset;
            
            document.getElementById('overall-progress-text').textContent = `${Math.round(percentage)}%`;
        }

        // Fetch and update KPIs
        async function updateKPIs() {
            try {
                const response = await fetch('/api/kpis');
                const kpis = await response.json();
                
                // Update development metrics
                document.getElementById('lines-of-code').textContent = kpis.development.linesOfCode.toLocaleString();
                document.getElementById('files-generated').textContent = kpis.development.filesGenerated;
                document.getElementById('api-endpoints').textContent = kpis.development.apiEndpoints;
                document.getElementById('components-built').textContent = kpis.development.componentsBuilt;
                
                // Update AI metrics
                document.getElementById('ai-success').textContent = kpis.ai.successfulGenerations;
                document.getElementById('ai-models').textContent = kpis.ai.modelsActive;
                document.getElementById('ai-optimizations').textContent = kpis.ai.optimizationRuns;
                document.getElementById('ai-reviews').textContent = kpis.ai.codeReviews;
                
                // Update timeline
                document.getElementById('acceleration-factor').textContent = kpis.timeline.accelerationFactor;
                document.getElementById('time-remaining').textContent = kpis.timeline.timeRemaining;
                document.getElementById('milestones').textContent = `${kpis.timeline.milestonesHit}/8`;
                
                // Update business metrics
                document.getElementById('customer-value').textContent = `${kpis.business.customerValue}%`;
                document.getElementById('market-readiness').textContent = `${kpis.business.marketReadiness}%`;
                document.getElementById('competitive-advantage').textContent = `${kpis.business.competitiveAdvantage}%`;
                document.getElementById('innovation-index').textContent = kpis.business.innovationIndex;
                
                // Update progress ring
                const progressPercent = parseInt(kpis.timeline.actualProgress.replace('%', ''));
                updateProgressRing(progressPercent);
                
                // Update quality chart
                qualityChart.data.datasets[0].data = [
                    kpis.quality.codeQualityScore,
                    kpis.quality.testCoverage,
                    kpis.quality.securityScore,
                    kpis.quality.performanceScore,
                    kpis.quality.maintainabilityIndex
                ];
                qualityChart.update();
                
            } catch (error) {
                console.error('Error updating KPIs:', error);
            }
        }

        // Initial load and periodic updates
        updateKPIs();
        setInterval(updateKPIs, 30000); // Update every 30 seconds

        console.log('📈 Professional KPI Dashboard Initialized');
    </script>
</body>
</html>
EOF

echo "✅ KPI Tracking System created at $METRICS_DIR"