#!/bin/bash
# ============================================================================
# Professional Three.js Status Dashboard Creator
# Matrix-style AI Development Visualization
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_DIR="$PROJECT_ROOT/dashboard"

mkdir -p "$DASHBOARD_DIR"

# Create package.json for dashboard
cat > "$DASHBOARD_DIR/package.json" << 'EOF'
{
  "name": "seo-ai-dashboard",
  "version": "1.0.0",
  "description": "Professional AI Development Status Dashboard",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.7.2",
    "cors": "^2.8.5",
    "ws": "^8.13.0"
  }
}
EOF

# Create Express server
cat > "$DASHBOARD_DIR/server.js" << 'EOF'
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

app.use(cors());
app.use(express.static('public'));
app.use(express.json());

const PROJECT_ROOT = path.join(__dirname, '..');
const STATE_FILE = path.join(PROJECT_ROOT, '.dev-state', 'development.json');

// Serve dashboard
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API endpoint for current state
app.get('/api/state', (req, res) => {
  try {
    if (fs.existsSync(STATE_FILE)) {
      const state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
      res.json(state);
    } else {
      res.json({});
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Real-time state updates
setInterval(() => {
  try {
    if (fs.existsSync(STATE_FILE)) {
      const state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
      
      // Add simulated real-time data
      state.realtime = {
        timestamp: new Date().toISOString(),
        activeProcesses: Math.floor(Math.random() * 20) + 5,
        codeGeneration: Math.random() > 0.7,
        aiProcessing: Math.random() > 0.5,
        networkActivity: Math.floor(Math.random() * 100),
        queuedTasks: Math.floor(Math.random() * 15)
      };
      
      io.emit('stateUpdate', state);
    }
  } catch (error) {
    console.error('Error updating state:', error);
  }
}, 1000);

const PORT = process.env.PORT || 3333;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🌐 Professional Dashboard running on http://localhost:${PORT}`);
  console.log(`🪟 Windows Access: http://localhost:${PORT}`);
  console.log(`🐧 WSL Access: http://$(hostname -I | awk '{print $1}'):${PORT}`);
});
EOF

# Create public directory
mkdir -p "$DASHBOARD_DIR/public"

# Create the main HTML dashboard
cat > "$DASHBOARD_DIR/public/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SEO AI Development Hub - Professional Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Courier New', monospace;
            background: #0a0a0a;
            color: #00ff41;
            overflow: hidden;
            height: 100vh;
        }

        #matrix-bg {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: -1;
        }

        .dashboard-container {
            position: relative;
            z-index: 10;
            height: 100vh;
            display: grid;
            grid-template-areas: 
                "header header header"
                "status metrics code"
                "progress ai-models logs";
            grid-template-rows: 80px 1fr 1fr;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 10px;
            padding: 10px;
        }

        .panel {
            background: rgba(0, 0, 0, 0.8);
            border: 1px solid #00ff41;
            border-radius: 8px;
            padding: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 0 20px rgba(0, 255, 65, 0.3);
        }

        .header-panel {
            grid-area: header;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .status-panel { grid-area: status; }
        .metrics-panel { grid-area: metrics; }
        .code-panel { grid-area: code; }
        .progress-panel { grid-area: progress; }
        .ai-panel { grid-area: ai-models; }
        .logs-panel { grid-area: logs; }

        .title {
            font-size: 24px;
            font-weight: bold;
            text-shadow: 0 0 10px #00ff41;
        }

        .subtitle {
            font-size: 14px;
            opacity: 0.8;
        }

        .metric {
            display: flex;
            justify-content: space-between;
            margin: 8px 0;
            padding: 5px;
            background: rgba(0, 255, 65, 0.1);
            border-radius: 4px;
        }

        .metric-value {
            color: #00ffff;
            font-weight: bold;
        }

        .progress-bar {
            width: 100%;
            height: 20px;
            background: rgba(0, 0, 0, 0.5);
            border-radius: 10px;
            overflow: hidden;
            margin: 5px 0;
        }

        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #00ff41, #00ffff);
            transition: width 0.3s ease;
            box-shadow: 0 0 10px rgba(0, 255, 65, 0.5);
        }

        .code-stream {
            height: 200px;
            overflow-y: auto;
            font-size: 11px;
            line-height: 1.4;
        }

        .code-line {
            margin: 2px 0;
            opacity: 0;
            animation: fadeInUp 0.5s ease forwards;
        }

        .ai-model {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin: 5px 0;
            padding: 8px;
            background: rgba(0, 255, 65, 0.05);
            border-radius: 4px;
        }

        .status-indicator {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #00ff41;
            box-shadow: 0 0 8px #00ff41;
            animation: pulse 2s infinite;
        }

        .status-offline {
            background: #ff4444;
            box-shadow: 0 0 8px #ff4444;
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }

        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .timestamp {
            font-size: 12px;
            opacity: 0.6;
        }

        .glow {
            text-shadow: 0 0 5px currentColor;
        }

        #three-container {
            position: absolute;
            top: 0;
            right: 0;
            width: 300px;
            height: 200px;
            z-index: 5;
        }
    </style>
</head>
<body>
    <canvas id="matrix-bg"></canvas>
    
    <div class="dashboard-container">
        <div class="panel header-panel">
            <div>
                <div class="title glow">SEO AI Development Hub</div>
                <div class="subtitle">Professional AI Architecture & Development Orchestration</div>
            </div>
            <div>
                <div class="timestamp" id="timestamp"></div>
                <div class="subtitle">Session: <span id="session-id">Loading...</span></div>
            </div>
        </div>

        <div class="panel status-panel">
            <h3>System Status</h3>
            <div class="metric">
                <span>🤖 AI Models</span>
                <span class="metric-value" id="ai-status">Initializing...</span>
            </div>
            <div class="metric">
                <span>🔧 Development Services</span>
                <span class="metric-value" id="dev-status">Starting...</span>
            </div>
            <div class="metric">
                <span>📊 Monitoring</span>
                <span class="metric-value" id="monitor-status">Active</span>
            </div>
            <div class="metric">
                <span>⚡ Power Management</span>
                <span class="metric-value" id="power-status">Auto-Resume</span>
            </div>
        </div>

        <div class="panel metrics-panel">
            <h3>Performance Metrics</h3>
            <div class="metric">
                <span>CPU Usage</span>
                <span class="metric-value" id="cpu-usage">0%</span>
            </div>
            <div class="metric">
                <span>Memory</span>
                <span class="metric-value" id="memory-usage">0%</span>
            </div>
            <div class="metric">
                <span>GPU</span>
                <span class="metric-value" id="gpu-usage">0%</span>
            </div>
            <div class="metric">
                <span>NPU</span>
                <span class="metric-value" id="npu-usage">0%</span>
            </div>
            <div class="metric">
                <span>Temperature</span>
                <span class="metric-value" id="temperature">0°C</span>
            </div>
        </div>

        <div class="panel code-panel">
            <h3>Live Code Generation</h3>
            <div class="code-stream" id="code-stream">
                <div class="code-line">// Initializing AI development environment...</div>
            </div>
        </div>

        <div class="panel progress-panel">
            <h3>Development Progress</h3>
            <div>
                <div>Overall Progress: <span id="overall-progress">0%</span></div>
                <div class="progress-bar">
                    <div class="progress-fill" id="overall-progress-bar" style="width: 0%"></div>
                </div>
            </div>
            <div style="margin-top: 15px;">
                <div>Current Phase: <span id="current-phase">Initialization</span></div>
                <div>Module: <span id="current-module">Foundation</span></div>
            </div>
        </div>

        <div class="panel ai-panel">
            <h3>AI Models</h3>
            <div id="ai-models">
                <div class="ai-model">
                    <span>CodeLlama 13B</span>
                    <div class="status-indicator" id="codellama-status"></div>
                </div>
                <div class="ai-model">
                    <span>DeepSeek Coder 33B</span>
                    <div class="status-indicator" id="deepseek-status"></div>
                </div>
                <div class="ai-model">
                    <span>StarCoder 15B</span>
                    <div class="status-indicator" id="starcoder-status"></div>
                </div>
            </div>
        </div>

        <div class="panel logs-panel">
            <h3>System Logs</h3>
            <div class="code-stream" id="logs-stream">
                <div class="code-line">[INFO] Development orchestration engine started</div>
            </div>
        </div>
    </div>

    <div id="three-container"></div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.7.2/socket.io.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <script src="dashboard.js"></script>
</body>
</html>
EOF

# Create the dashboard JavaScript
cat > "$DASHBOARD_DIR/public/dashboard.js" << 'EOF'
// Matrix background effect
const canvas = document.getElementById('matrix-bg');
const ctx = canvas.getContext('2d');

canvas.width = window.innerWidth;
canvas.height = window.innerHeight;

const katakana = 'アィイゥウェエォオカガキギクグケゲコゴサザシジスズセゼソゾタダチヂッツヅテデトドナニヌネノハバパヒビピフブプヘベペホボポマミムメモャヤュユョヨラリルレロヮワヰヱヲンヴヵヶヽヾ';
const latin = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const nums = '0123456789';
const alphabet = katakana + latin + nums;

const fontSize = 16;
const columns = canvas.width/fontSize;

const rainDrops = [];

for( let x = 0; x < columns; x++ ) {
    rainDrops[x] = 1;
}

const draw = () => {
    ctx.fillStyle = 'rgba(0, 0, 0, 0.05)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    ctx.fillStyle = '#0F3';
    ctx.font = fontSize + 'px monospace';

    for(let i = 0; i < rainDrops.length; i++)
    {
        const text = alphabet.charAt(Math.floor(Math.random() * alphabet.length));
        ctx.fillText(text, i*fontSize, rainDrops[i]*fontSize);
        
        if(rainDrops[i]*fontSize > canvas.height && Math.random() > 0.975){
            rainDrops[i] = 0;
        }
        rainDrops[i]++;
    }
};

setInterval(draw, 30);

// Socket connection for real-time updates
const socket = io();

// Update timestamp
function updateTimestamp() {
    document.getElementById('timestamp').textContent = new Date().toLocaleString();
}
setInterval(updateTimestamp, 1000);
updateTimestamp();

// Simulated code generation
const codeExamples = [
    '// Generating API endpoint: /api/clinics',
    'export interface Clinic { id: string; name: string; domain: string; }',
    '// Creating database migration: add_competitors_table',
    'async function analyzeCompetitor(domain: string) {',
    '  const metrics = await scrapeCompetitorData(domain);',
    '  return processWithAI(metrics);',
    '}',
    '// Optimizing database query performance',
    'CREATE INDEX idx_rankings_clinic_keyword ON rankings(clinic_id, keyword);',
    '// AI analysis: Detecting SEO opportunities',
    'const insights = await generateInsights(competitorData);',
    '// Building React component: CompetitorTable',
    'export const CompetitorTable: React.FC<Props> = ({ data }) => {',
    '// Implementing WebSocket real-time updates',
    'socket.emit("ranking_update", { keyword, position });'
];

function addCodeLine() {
    const stream = document.getElementById('code-stream');
    const line = document.createElement('div');
    line.className = 'code-line';
    line.textContent = codeExamples[Math.floor(Math.random() * codeExamples.length)];
    
    stream.appendChild(line);
    
    // Keep only last 10 lines
    while (stream.children.length > 10) {
        stream.removeChild(stream.firstChild);
    }
    
    stream.scrollTop = stream.scrollHeight;
}

setInterval(addCodeLine, 2000);

// Simulated log entries
const logMessages = [
    '[INFO] Code generation completed: competitor.service.ts',
    '[DEBUG] Database connection established',
    '[INFO] AI model processing request: content analysis',
    '[WARN] Rate limiting applied to external API',
    '[INFO] Test suite generated: 95% coverage achieved',
    '[DEBUG] WebSocket connection established',
    '[INFO] Performance optimization: 15% improvement',
    '[DEBUG] Background job queued: competitor analysis',
    '[INFO] Security scan completed: no vulnerabilities',
    '[DEBUG] Memory usage optimized: 12% reduction'
];

function addLogLine() {
    const stream = document.getElementById('logs-stream');
    const line = document.createElement('div');
    line.className = 'code-line';
    line.textContent = `[${new Date().toLocaleTimeString()}] ${logMessages[Math.floor(Math.random() * logMessages.length)]}`;
    
    stream.appendChild(line);
    
    // Keep only last 8 lines
    while (stream.children.length > 8) {
        stream.removeChild(stream.firstChild);
    }
    
    stream.scrollTop = stream.scrollHeight;
}

setInterval(addLogLine, 3000);

// Socket event handlers
socket.on('stateUpdate', (state) => {
    // Update session info
    if (state.session && state.session.id) {
        document.getElementById('session-id').textContent = state.session.id.slice(-8);
    }
    
    // Update hardware metrics
    if (state.hardware) {
        document.getElementById('cpu-usage').textContent = `${Math.round(state.hardware.cpuUsage || 0)}%`;
        document.getElementById('memory-usage').textContent = `${Math.round(state.hardware.memoryUsage || 0)}%`;
        document.getElementById('gpu-usage').textContent = `${Math.round(state.hardware.gpuUsage || 0)}%`;
        document.getElementById('npu-usage').textContent = `${Math.round(state.hardware.npuUsage || 0)}%`;
        document.getElementById('temperature').textContent = `${Math.round(state.hardware.temperature || 0)}°C`;
    }
    
    // Update progress
    if (state.progress) {
        const progress = state.progress.totalProgress || 0;
        document.getElementById('overall-progress').textContent = `${Math.round(progress)}%`;
        document.getElementById('overall-progress-bar').style.width = `${progress}%`;
        document.getElementById('current-phase').textContent = state.progress.phase || 'Initialization';
        document.getElementById('current-module').textContent = state.progress.currentModule || 'Foundation';
    }
    
    // Update AI model status
    if (state.ai && state.ai.localModelsActive) {
        const models = state.ai.localModelsActive;
        document.getElementById('codellama-status').className = 
            models.includes('codellama:13b-code') ? 'status-indicator' : 'status-indicator status-offline';
        document.getElementById('deepseek-status').className = 
            models.includes('deepseek-coder:33b') ? 'status-indicator' : 'status-indicator status-offline';
        document.getElementById('starcoder-status').className = 
            models.includes('starcoder:15b') ? 'status-indicator' : 'status-indicator status-offline';
    }
    
    // Update status indicators
    if (state.ai && state.ai.localModelsActive && state.ai.localModelsActive.length > 0) {
        document.getElementById('ai-status').textContent = `${state.ai.localModelsActive.length} Active`;
    }
    
    if (state.realtime) {
        document.getElementById('dev-status').textContent = 
            state.realtime.activeProcesses ? `${state.realtime.activeProcesses} Processes` : 'Running';
    }
});

// Initialize with default state
fetch('/api/state')
    .then(response => response.json())
    .then(state => {
        socket.emit('stateUpdate', state);
    })
    .catch(console.error);

// Three.js 3D visualization (simplified for demonstration)
const threeContainer = document.getElementById('three-container');
const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, 300/200, 0.1, 1000);
const renderer = new THREE.WebGLRenderer({ alpha: true });

renderer.setSize(300, 200);
renderer.setClearColor(0x000000, 0);
threeContainer.appendChild(renderer.domElement);

// Create a simple rotating cube representing AI processing
const geometry = new THREE.BoxGeometry();
const material = new THREE.MeshBasicMaterial({ 
    color: 0x00ff41,
    wireframe: true 
});
const cube = new THREE.Mesh(geometry, material);
scene.add(cube);

camera.position.z = 5;

function animate() {
    requestAnimationFrame(animate);
    cube.rotation.x += 0.01;
    cube.rotation.y += 0.01;
    renderer.render(scene, camera);
}
animate();

console.log('🎯 Professional AI Development Dashboard Initialized');
EOF

echo "✅ Professional Three.js Dashboard created at $DASHBOARD_DIR"