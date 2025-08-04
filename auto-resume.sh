#!/bin/bash
# ============================================================================
# Auto-Resume Development Environment on System Boot
# Power Management Integration
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create systemd service for auto-resume
cat > /tmp/seo-dev-auto-resume.service << EOF
[Unit]
Description=SEO Development Environment Auto-Resume
After=network.target docker.service
Wants=network.target
Requires=docker.service

[Service]
Type=forking
User=$USER
WorkingDirectory=$PROJECT_ROOT
ExecStart=$PROJECT_ROOT/start
ExecStop=$PROJECT_ROOT/stop
Restart=on-failure
RestartSec=10
Environment=HOME=$HOME
Environment=PATH=$PATH

[Install]
WantedBy=multi-user.target
EOF

# Install systemd service
sudo cp /tmp/seo-dev-auto-resume.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable seo-dev-auto-resume.service

echo "✅ Auto-resume service installed"
echo "🔄 Development environment will start automatically on boot"
echo "🛑 To disable: sudo systemctl disable seo-dev-auto-resume.service"

# Create power management hooks
mkdir -p "$PROJECT_ROOT/.power-hooks"

# Suspend hook - save state before sleep
cat > "$PROJECT_ROOT/.power-hooks/suspend.sh" << 'EOF'
#!/bin/bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$PROJECT_ROOT/.dev-state"

# Save pre-suspend state
if [[ -f "$STATE_DIR/development.json" ]]; then
    jq --arg time "$(date -Iseconds)" \
       '.session.lastSuspend = $time | .session.suspendCount += 1' \
       "$STATE_DIR/development.json" > "$STATE_DIR/development.tmp" && \
       mv "$STATE_DIR/development.tmp" "$STATE_DIR/development.json"
fi

# Graceful shutdown
"$PROJECT_ROOT/stop"
EOF

# Resume hook - restart after wake
cat > "$PROJECT_ROOT/.power-hooks/resume.sh" << 'EOF'
#!/bin/bash
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$PROJECT_ROOT/.dev-state"

# Wait for network
sleep 5

# Update resume state
if [[ -f "$STATE_DIR/development.json" ]]; then
    jq --arg time "$(date -Iseconds)" \
       '.session.lastResume = $time | .session.resumeCount += 1' \
       "$STATE_DIR/development.json" > "$STATE_DIR/development.tmp" && \
       mv "$STATE_DIR/development.tmp" "$STATE_DIR/development.json"
fi

# Restart development environment
"$PROJECT_ROOT/start" &
EOF

chmod +x "$PROJECT_ROOT/.power-hooks/"*.sh

# Install power hooks (requires sudo)
if command -v systemctl &> /dev/null; then
    echo "Installing power management hooks..."
    
    # Create systemd sleep hooks
    sudo mkdir -p /lib/systemd/system-sleep/
    
    cat > /tmp/seo-dev-sleep-hook << EOF
#!/bin/bash
case \$1/\$2 in
  pre/suspend|pre/hibernate)
    $PROJECT_ROOT/.power-hooks/suspend.sh
    ;;
  post/suspend|post/hibernate)
    $PROJECT_ROOT/.power-hooks/resume.sh
    ;;
esac
EOF
    
    sudo cp /tmp/seo-dev-sleep-hook /lib/systemd/system-sleep/seo-dev-hook
    sudo chmod +x /lib/systemd/system-sleep/seo-dev-hook
    
    echo "✅ Power management hooks installed"
fi

echo
echo "🎯 Auto-resume configuration complete!"
echo "📱 Your development environment will now:"
echo "   • Start automatically on boot"
echo "   • Save state before suspend/hibernate"  
echo "   • Resume automatically after wake"
echo "   • Preserve all progress across power cycles"