#!/bin/bash
# ============================================================================
# WSL Networking Fix Script
# Attempts to resolve common WSL localhost connection issues
# ============================================================================

echo "🔧 WSL Networking Fix Script"
echo "============================"
echo

# Kill any existing services first
echo "🛑 Stopping existing services..."
pkill -f "node.*dashboard" 2>/dev/null
pkill -f "node.*kpi-server" 2>/dev/null
pkill -f "python.*http.server" 2>/dev/null
sleep 2

# Function to start a simple test server
start_test_server() {
    local port=$1
    echo "🚀 Starting test server on port $port..."
    
    # Create a simple test HTML page
    cat > "/tmp/test-$port.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>WSL Test Server - Port $port</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; background: #1a1a1a; color: #00ff00; }
        .success { font-size: 2em; margin: 20px; }
        .info { background: #333; padding: 20px; border-radius: 10px; margin: 20px; }
    </style>
</head>
<body>
    <div class="success">✅ WSL Connection Working!</div>
    <div class="info">
        <h2>Port $port is accessible from Windows</h2>
        <p>WSL IP: $(hostname -I | awk '{print $1}')</p>
        <p>Time: $(date)</p>
        <p>This confirms WSL networking is working properly.</p>
    </div>
</body>
</html>
EOF

    # Start a simple HTTP server
    cd /tmp
    if command -v python3 &> /dev/null; then
        python3 -m http.server $port --bind 0.0.0.0 > "/tmp/server-$port.log" 2>&1 &
        echo $! > "/tmp/server-$port.pid"
        echo "✅ Test server started on port $port (PID: $!)"
        echo "🌐 Test URL: http://localhost:$port/test-$port.html"
        echo "🌐 Alt URL:  http://$(hostname -I | awk '{print $1}'):$port/test-$port.html"
    else
        echo "❌ Python3 not available for test server"
    fi
}

# Function to start the actual Node.js services with debugging
start_dashboard_with_debug() {
    echo "🚀 Starting Dashboard with debugging..."
    
    cd /home/Projects/SEO/dashboard
    if [[ -f "package.json" ]]; then
        # Install dependencies if needed
        if [[ ! -d "node_modules" ]]; then
            echo "📦 Installing dashboard dependencies..."
            npm install 2>/dev/null || echo "❌ npm install failed"
        fi
        
        # Start with explicit binding
        echo "🔧 Starting dashboard server..."
        cat > server-debug.js << 'EOF'
const express = require('express');
const http = require('http');
const path = require('path');

const app = express();
const server = http.createServer(app);

app.use(express.static('public'));

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>WSL Dashboard Test</title></head>
      <body style="background: #1a1a1a; color: #00ff00; font-family: Arial; text-align: center; padding: 50px;">
        <h1>✅ Dashboard Server Working!</h1>
        <p>Time: ${new Date()}</p>
        <p>WSL networking is functional</p>
        <p><a href="http://localhost:3334" style="color: #00ffff;">KPI Dashboard</a></p>
      </body>
    </html>
  `);
});

const PORT = 3333;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Dashboard server running on http://localhost:${PORT}`);
  console.log(`🪟 Windows access: http://localhost:${PORT}`);
  console.log(`🐧 Direct IP: http://${require('os').networkInterfaces().eth0?.[0]?.address}:${PORT}`);
});

server.on('error', (err) => {
  console.error('❌ Server error:', err.message);
  if (err.code === 'EADDRINUSE') {
    console.log('Port 3333 is already in use. Trying 3335...');
    server.listen(3335, '0.0.0.0');
  }
});
EOF
        
        node server-debug.js > "/tmp/dashboard-debug.log" 2>&1 &
        echo $! > "/tmp/dashboard.pid"
        sleep 2
        
        if ps -p $(cat /tmp/dashboard.pid) > /dev/null 2>&1; then
            echo "✅ Dashboard started successfully"
        else
            echo "❌ Dashboard failed to start"
            cat "/tmp/dashboard-debug.log"
        fi
    else
        echo "❌ Dashboard package.json not found"
    fi
}

# Main execution
echo "1. Starting test servers to verify WSL networking..."
start_test_server 8080
start_test_server 8081

echo
echo "2. Starting dashboard with debugging..."
start_dashboard_with_debug

echo
echo "🧪 Testing connectivity..."
sleep 3

# Test the servers
for port in 8080 8081 3333; do
    if timeout 3 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
        echo "✅ Port $port is accessible"
    else
        echo "❌ Port $port is NOT accessible"
    fi
done

echo
echo "🌐 URLs to test in Windows browser:"
echo "   Simple test:     http://localhost:8080/test-8080.html"
echo "   Alternative:     http://localhost:8081/test-8081.html" 
echo "   Dashboard test:  http://localhost:3333"
echo
echo "🔍 If none work, try these WSL IP URLs:"
WSL_IP=$(hostname -I | awk '{print $1}')
echo "   http://$WSL_IP:8080/test-8080.html"
echo "   http://$WSL_IP:3333"
echo

echo "🛠️  To stop test servers:"
echo "   pkill -f 'python.*http.server'"
echo "   pkill -f 'node.*server-debug'"

echo
echo "⏰ Test servers will run for 60 seconds..."
echo "   Try the URLs above in your Windows browser NOW"
sleep 60

echo "🛑 Stopping test servers..."
pkill -f "python.*http.server" 2>/dev/null
pkill -f "node.*server-debug" 2>/dev/null