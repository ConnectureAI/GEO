#!/bin/bash
# ============================================================================
# WSL Connection Debugger
# Diagnoses and fixes localhost connection issues
# ============================================================================

echo "🔍 WSL Connection Debugger"
echo "=========================="
echo

# Check WSL version
echo "📋 WSL Version Information:"
wsl --status 2>/dev/null || echo "WSL command not available from Linux side"
cat /proc/version | grep -i microsoft
echo

# Get network information
echo "🌐 Network Configuration:"
echo "WSL IP Address: $(hostname -I | awk '{print $1}')"
echo "WSL Hostname: $(hostname)"
echo

# Check if services are actually running
echo "🔍 Checking Running Services:"
if pgrep -f "node.*dashboard" > /dev/null; then
    echo "✅ Dashboard service is running"
    echo "   PID: $(pgrep -f 'node.*dashboard')"
else
    echo "❌ Dashboard service not running"
fi

if pgrep -f "node.*kpi-server" > /dev/null; then
    echo "✅ KPI service is running"
    echo "   PID: $(pgrep -f 'node.*kpi-server')"
else
    echo "❌ KPI service not running"
fi
echo

# Check port bindings
echo "🔌 Port Binding Status:"
netstat_output=$(netstat -tlnp 2>/dev/null | grep -E ':(3333|3334)')
if [[ -n "$netstat_output" ]]; then
    echo "✅ Ports are bound:"
    echo "$netstat_output"
else
    echo "❌ No services bound to ports 3333/3334"
    echo "   Checking if anything is listening on these ports:"
    ss -tlnp | grep -E ':(3333|3334)' || echo "   Nothing found"
fi
echo

# Check if ports are accessible locally within WSL
echo "🧪 Testing Local Connectivity:"
for port in 3333 3334; do
    if timeout 3 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
        echo "✅ Port $port accessible from within WSL"
    else
        echo "❌ Port $port NOT accessible from within WSL"
    fi
done
echo

# Test with curl if available
echo "🌐 HTTP Response Test:"
for port in 3333 3334; do
    if command -v curl &> /dev/null; then
        echo "Testing port $port:"
        curl_result=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "http://localhost:$port" 2>/dev/null || echo "000")
        if [[ "$curl_result" != "000" ]]; then
            echo "✅ Port $port returns HTTP $curl_result"
        else
            echo "❌ Port $port connection failed"
        fi
    else
        echo "⚠️  curl not available for HTTP testing"
    fi
done
echo

# Check Windows-specific WSL issues
echo "🪟 Windows WSL Diagnostics:"
echo "1. Check if WSL2 networking is working:"
echo "   - Windows localhost forwarding should be automatic"
echo "   - If not working, WSL2 may need restart"
echo

echo "2. WSL IP that Windows should use:"
echo "   http://$(hostname -I | awk '{print $1}'):3333"
echo "   http://$(hostname -I | awk '{print $1}'):3334"
echo

echo "3. Windows PowerShell commands to try:"
echo "   # Test WSL connectivity from Windows"
echo "   Test-NetConnection $(hostname -I | awk '{print $1}') -Port 3333"
echo "   Test-NetConnection $(hostname -I | awk '{print $1}') -Port 3334"
echo

echo "🔧 Potential Fixes:"
echo "1. Restart WSL from Windows PowerShell (as Admin):"
echo "   wsl --shutdown"
echo "   wsl"
echo

echo "2. Check Windows Firewall:"
echo "   New-NetFirewallRule -DisplayName 'WSL-Dashboards' -Direction Inbound -LocalPort 3333,3334 -Protocol TCP -Action Allow"
echo

echo "3. Use WSL IP directly in Windows browser:"
echo "   http://$(hostname -I | awk '{print $1}'):3333"
echo

echo "4. Check WSL2 localhost forwarding:"
echo "   netsh interface portproxy show all"
echo

# Generate a simple test server
echo "🚀 Quick Test Server:"
echo "If the main services aren't working, test with:"
echo "python3 -m http.server 8080"
echo "Then try: http://localhost:8080 in Windows browser"
echo

# Check if we can create a simple test
if command -v python3 &> /dev/null; then
    echo "Starting test server on port 8080 for 10 seconds..."
    echo "Try http://localhost:8080 in Windows browser NOW:"
    timeout 10s python3 -m http.server 8080 2>/dev/null &
    sleep 10
    echo "Test server stopped."
fi