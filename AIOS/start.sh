#!/bin/bash
cd "$(dirname "$0")"

echo "🚀 Starting AI OS for WSL..."

# Load environment if it exists
[[ -f .env ]] && source .env

# Start Ollama if available and not running
if command -v ollama >/dev/null 2>&1; then
    if ! pgrep -f "ollama serve" >/dev/null; then
        echo "🤖 Starting local AI..."
        nohup ollama serve > ollama.log 2>&1 &
        sleep 2
        
        # Install model if needed
        if ! ollama list 2>/dev/null | grep -q "llama3.2:1b"; then
            echo "📥 Installing AI model (background)..."
            nohup ollama pull llama3.2:1b > model_download.log 2>&1 &
        fi
    fi
else
    echo "⚠️ Ollama not installed. Install with: curl -fsSL https://ollama.ai/install.sh | sh"
fi

# Run initial categorization if needed
if [[ ! -f file_categories.json ]]; then
    echo "📊 Initial file analysis..."
    node markdown_agent.js .
fi

# Start the AI shell
node ai_shell.js
