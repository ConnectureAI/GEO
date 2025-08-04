#!/bin/bash
echo "📊 AI OS Status:"
echo "Directory: $(pwd)"
echo "Node.js: $(node --version 2>/dev/null || echo 'Not found')"
echo "Ollama: $(command -v ollama >/dev/null && echo 'Installed' || echo 'Not installed')"
echo "AI Service: $(pgrep -f 'ollama serve' >/dev/null && echo 'Running' || echo 'Stopped')"
echo "Categories: $(test -f file_categories.json && cat file_categories.json | jq 'keys | length' 2>/dev/null || echo '0') found"
echo ""
echo "🚀 Start with: ./start.sh"
