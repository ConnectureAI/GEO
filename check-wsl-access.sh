#!/bin/bash
# ============================================================================
# WSL Windows Access Helper
# Ensures dashboards are accessible from Windows browser
# ============================================================================

echo "🪟 WSL Windows Access Configuration"
echo "=================================="

# Get WSL IP address
WSL_IP=$(hostname -I | awk '{print $1}')
echo "🐧 WSL IP Address: $WSL_IP"

# Check if Windows can access WSL
echo "🔍 Testing Windows accessibility..."

# Check if ports are open
netstat -ln | grep -E ':(3333|3334|3000)' && echo "✅ Ports are bound correctly" || echo "❌ Ports may not be accessible"

# Windows firewall note
echo ""
echo "🛡️  Windows Firewall Configuration:"
echo "If dashboards don't load in Windows browser:"
echo ""
echo "1. Run as Administrator in Windows PowerShell:"
echo "   New-NetFirewallRule -DisplayName 'WSL Dashboard' -Direction Inbound -LocalPort 3333,3334,3000 -Protocol TCP -Action Allow"
echo ""
echo "2. Or temporarily disable Windows Firewall for testing"
echo ""

echo "🌐 Dashboard URLs for Windows:"
echo "   Matrix Dashboard: http://localhost:3333"
echo "   KPI Dashboard:    http://localhost:3334"
echo "   SEO Platform:     http://localhost:3000 (after npm run dev)"
echo ""

echo "🔄 Alternative access if localhost doesn't work:"
echo "   Matrix Dashboard: http://$WSL_IP:3333"
echo "   KPI Dashboard:    http://$WSL_IP:3334"
echo "   SEO Platform:     http://$WSL_IP:3000"
echo ""

echo "💡 Pro Tip: WSL2 automatically forwards localhost ports to Windows!"
echo "   Just use http://localhost:3333 in your Windows browser"