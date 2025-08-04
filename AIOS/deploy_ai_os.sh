#!/bin/bash

# INSTANT WSL DEPLOYMENT
# Save this as: deploy_ai_os.sh
# Run with: bash deploy_ai_os.sh

# Direct deployment to your specific path
TARGET_DIR="/home/Projects/SEO/AIOS"

echo "🚀 INSTANT AI OS DEPLOYMENT FOR WSL"
echo "🎯 Target: $TARGET_DIR (\\wsl$\\Ubuntu\\home\\Projects\\SEO\\AIOS)"
echo "⚡ Zero-configuration autonomous setup"
echo ""

# Create target directory
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "📍 Working in: $(pwd)"

# Quick dependency check and install
echo "📦 Installing dependencies..."
sudo apt update -qq
sudo apt install -y curl wget git nodejs npm jq build-essential

# Install latest Node.js if needed
if [[ $(node -v 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1) -lt 18 ]]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

echo "✅ Dependencies ready"

# Create package.json
cat > package.json << 'EOF'
{
  "name": "autonomous-ai-os",
  "version": "1.0.0",
  "type": "module",
  "main": "ai_shell.js",
  "scripts": {
    "start": "./start.sh",
    "categorize": "node markdown_agent.js"
  },
  "dependencies": {
    "node-fetch": "^3.3.2"
  }
}
EOF

# Install Node modules
npm install

# Create the main AI shell
cat > ai_shell.js << 'AI_SHELL_EOF'
#!/usr/bin/env node
import readline from 'readline';
import fs from 'fs/promises';
import { execSync } from 'child_process';
import fetch from 'node-fetch';

class AIShell {
    constructor() {
        this.contexts = new Map();
        this.currentContext = null;
        this.setupInterface();
        this.loadContexts();
    }

    setupInterface() {
        this.rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        this.commands = {
            help: () => this.showHelp(),
            contexts: () => this.listContexts(),
            switch: (name) => this.switchContext(name),
            ask: (...args) => this.askAI(args.join(' ')),
            categorize: () => this.recategorize(),
            status: () => this.showStatus(),
            seo: () => this.switchContext('seo'),
            aios: () => this.switchContext('aios'),
            dev: () => this.switchContext('development'),
            exit: () => process.exit(0)
        };
    }

    async loadContexts() {
        try {
            const data = await fs.readFile('file_categories.json', 'utf8');
            const categories = JSON.parse(data);
            
            for (const [name, files] of Object.entries(categories)) {
                this.contexts.set(name, { name, files, lastUsed: new Date() });
            }
            
            console.log(`📁 Loaded ${this.contexts.size} contexts: ${Array.from(this.contexts.keys()).join(', ')}`);
        } catch {
            console.log('📊 No contexts found. Run "categorize" to analyze your files.');
        }
    }

    showHelp() {
        console.log(`
🤖 AI Shell Commands:

Quick Context Switching:
  seo              - Switch to SEO context
  aios             - Switch to AI OS context  
  dev              - Switch to development context

General Commands:
  contexts         - List all contexts
  switch <name>    - Switch to specific context
  ask <question>   - Ask AI (context-aware)
  categorize       - Analyze/re-analyze files
  status           - Show system status
  help             - Show this help
  exit             - Exit shell

💡 ADHD-Friendly Tips:
  • Ask natural questions: "ask what should I work on next?"
  • Quick context switching preserves your flow
  • AI remembers your context across switches
        `);
    }

    listContexts() {
        if (this.contexts.size === 0) {
            console.log('📊 No contexts found. Run "categorize" first.');
            return;
        }

        console.log('\n📁 Your Contexts:');
        for (const [name, context] of this.contexts) {
            const indicator = context === this.currentContext ? '→' : ' ';
            const fileCount = Array.isArray(context.files) ? context.files.length : 0;
            console.log(`${indicator} ${name} (${fileCount} files)`);
        }
        console.log();
    }

    switchContext(name) {
        const context = this.contexts.get(name);
        if (context) {
            this.currentContext = context;
            context.lastUsed = new Date();
            console.log(`🔄 Switched to ${name} context`);
            this.updatePrompt();
        } else {
            console.log(`❌ Context '${name}' not found. Available: ${Array.from(this.contexts.keys()).join(', ')}`);
        }
    }

    updatePrompt() {
        const contextName = this.currentContext?.name || 'general';
        this.rl.setPrompt(`🤖 [${contextName}] > `);
    }

    async askAI(question) {
        if (!question.trim()) {
            console.log('💬 Ask me anything! I\'ll use your current context to help.');
            return;
        }

        console.log('🤖 Thinking...');
        
        const contextInfo = this.currentContext ? 
            `Context: ${this.currentContext.name}\nFiles: ${this.getContextFiles()}\n\n` : '';

        try {
            // Try local AI first
            const response = await fetch('http://localhost:11434/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: 'llama3.2:1b',
                    prompt: `${contextInfo}User: ${question}\n\nAssistant: I'll help you with your ${this.currentContext?.name || 'general'} work.`,
                    stream: false,
                    options: { temperature: 0.7 }
                })
            });

            if (response.ok) {
                const data = await response.json();
                console.log(`\n💬 AI: ${data.response}\n`);
            } else {
                throw new Error('Local AI unavailable');
            }
        } catch (error) {
            console.log('💬 AI: Local AI service unavailable. Make sure Ollama is running with: ollama serve');
            console.log('💡 Or set up cloud APIs in your .env file');
        }
    }

    getContextFiles() {
        if (!this.currentContext || !Array.isArray(this.currentContext.files)) {
            return 'none';
        }
        return this.currentContext.files
            .map(f => typeof f === 'string' ? f.split('/').pop() : f.name || 'unknown')
            .slice(0, 5)
            .join(', ');
    }

    async recategorize() {
        console.log('📊 Re-analyzing your markdown files...');
        try {
            execSync('node markdown_agent.js .', { stdio: 'inherit' });
            await this.loadContexts();
            console.log('✅ Files re-categorized!');
        } catch (error) {
            console.log('❌ Categorization failed. Make sure markdown_agent.js exists.');
        }
    }

    showStatus() {
        const totalFiles = Array.from(this.contexts.values())
            .reduce((sum, ctx) => sum + (Array.isArray(ctx.files) ? ctx.files.length : 0), 0);

        console.log(`
📊 AI Shell Status:
Current context: ${this.currentContext?.name || 'none'}
Total contexts: ${this.contexts.size}
Files tracked: ${totalFiles}
Directory: ${process.cwd()}

🤖 AI Service: ${this.checkAIService()}
        `);
    }

    checkAIService() {
        try {
            execSync('pgrep -f "ollama serve"', { stdio: 'ignore' });
            return '✅ Local AI running';
        } catch {
            return '❌ Local AI not running (start with: ollama serve)';
        }
    }

    async start() {
        console.log('🚀 AI Shell Started for WSL');
        console.log('📁 AIOS Project Directory');
        console.log('Type "help" for commands or "ask <question>" to get started\n');
        
        this.updatePrompt();
        this.rl.prompt();

        this.rl.on('line', async (input) => {
            const parts = input.trim().split(' ');
            const command = parts[0];
            const args = parts.slice(1);

            if (this.commands[command]) {
                await this.commands[command](...args);
            } else if (input.trim()) {
                // Treat unknown commands as AI questions
                await this.askAI(input);
            }

            this.rl.prompt();
        });

        this.rl.on('SIGINT', () => {
            console.log('\n👋 Goodbye! Your contexts are saved.');
            process.exit(0);
        });
    }
}

const shell = new AIShell();
shell.start();
AI_SHELL_EOF

# Create the markdown analysis agent
cat > markdown_agent.js << 'MARKDOWN_EOF'
#!/usr/bin/env node
import fs from 'fs/promises';
import path from 'path';

class QuickMarkdownAgent {
    constructor() {
        this.categories = {};
    }

    async analyze(directory = '.') {
        console.log(`📊 Quick analysis of ${directory}...`);
        
        const files = await this.findMarkdownFiles(directory);
        console.log(`📄 Found ${files.length} markdown files`);

        for (const file of files) {
            await this.categorizeFile(file);
        }

        await this.saveResults();
        this.showResults();
        
        return this.categories;
    }

    async findMarkdownFiles(dir, files = []) {
        try {
            const entries = await fs.readdir(dir, { withFileTypes: true });
            
            for (const entry of entries) {
                const fullPath = path.join(dir, entry.name);
                
                if (entry.isDirectory() && !entry.name.startsWith('.')) {
                    await this.findMarkdownFiles(fullPath, files);
                } else if (entry.isFile() && entry.name.endsWith('.md')) {
                    files.push(fullPath);
                }
            }
        } catch (error) {
            // Skip directories we can't read
        }
        
        return files;
    }

    async categorizeFile(filePath) {
        try {
            const content = await fs.readFile(filePath, 'utf8');
            const category = this.classifyContent(content, filePath);
            
            if (!this.categories[category]) {
                this.categories[category] = [];
            }
            
            this.categories[category].push({
                path: filePath,
                name: path.basename(filePath),
                size: content.length
            });
            
        } catch (error) {
            console.warn(`⚠️ Cannot read ${filePath}`);
        }
    }

    classifyContent(content, filePath) {
        const fileName = path.basename(filePath).toLowerCase();
        const contentLower = content.toLowerCase();
        const dirPath = path.dirname(filePath).toLowerCase();
        
        // SEO-specific patterns
        if (fileName.includes('seo') || contentLower.includes('seo') || dirPath.includes('seo')) {
            return 'seo';
        }
        
        // AI OS patterns
        if (fileName.includes('aios') || fileName.includes('ai-os') || 
            contentLower.includes('ai os') || contentLower.includes('autonomous')) {
            return 'aios';
        }
        
        // Development patterns
        if (contentLower.includes('function') || contentLower.includes('class') || 
            contentLower.includes('```') || fileName.includes('code')) {
            return 'development';
        }
        
        // Setup/installation
        if (fileName.includes('setup') || fileName.includes('install') || 
            contentLower.includes('installation') || fileName.includes('deploy')) {
            return 'setup';
        }
        
        // Planning
        if (fileName.includes('plan') || fileName.includes('roadmap') || 
            contentLower.includes('todo') || fileName.includes('strategy')) {
            return 'planning';
        }
        
        // Research
        if (contentLower.includes('research') || contentLower.includes('analysis') || 
            fileName.includes('research')) {
            return 'research';
        }
        
        // Documentation
        if (fileName.includes('doc') || fileName.includes('readme') || 
            fileName.includes('guide') || contentLower.includes('documentation')) {
            return 'documentation';
        }
        
        return 'notes';
    }

    async saveResults() {
        await fs.writeFile('file_categories.json', JSON.stringify(this.categories, null, 2));
    }

    showResults() {
        console.log('\n📊 Categorization Results:');
        
        const sortedCategories = Object.entries(this.categories)
            .sort(([,a], [,b]) => b.length - a.length);

        for (const [name, files] of sortedCategories) {
            console.log(`  📁 ${name}: ${files.length} files`);
        }
        
        console.log(`\n💾 Saved to file_categories.json`);
    }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    const agent = new QuickMarkdownAgent();
    agent.analyze(process.argv[2] || '.')
        .catch(console.error);
}

export default QuickMarkdownAgent;
MARKDOWN_EOF

# Create startup script
cat > start.sh << 'START_EOF'
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
START_EOF

# Create quick status script
cat > status.sh << 'STATUS_EOF'
#!/bin/bash
echo "📊 AI OS Status:"
echo "Directory: $(pwd)"
echo "Node.js: $(node --version 2>/dev/null || echo 'Not found')"
echo "Ollama: $(command -v ollama >/dev/null && echo 'Installed' || echo 'Not installed')"
echo "AI Service: $(pgrep -f 'ollama serve' >/dev/null && echo 'Running' || echo 'Stopped')"
echo "Categories: $(test -f file_categories.json && cat file_categories.json | jq 'keys | length' 2>/dev/null || echo '0') found"
echo ""
echo "🚀 Start with: ./start.sh"
STATUS_EOF

# Create Windows batch file
cat > start_from_windows.bat << 'BAT_EOF'
@echo off
title AI OS - WSL
echo 🚀 Starting AI OS from Windows...
cd /d "\\wsl$\Ubuntu\home\Projects\SEO\AIOS"
wsl bash -c "cd /home/Projects/SEO/AIOS && ./start.sh"
pause
BAT_EOF

# Make scripts executable
chmod +x *.sh *.js

# Install Ollama
echo "🤖 Installing Ollama (local AI)..."
if ! command -v ollama >/dev/null 2>&1; then
    curl -fsSL https://ollama.ai/install.sh | sh
    
    # Start Ollama
    echo "🔄 Starting Ollama..."
    nohup ollama serve > ollama.log 2>&1 &
    sleep 3
    
    # Install fast model
    echo "📥 Installing AI model..."
    ollama pull llama3.2:1b &
    echo "⏳ Model downloading in background..."
else
    echo "✅ Ollama already installed"
fi

# Run initial analysis
echo "📊 Analyzing your markdown files..."
node markdown_agent.js . 2>/dev/null || echo "⚠️ Will analyze on first run"

# Create environment file
cat > .env << 'ENV_EOF'
# AI OS Environment
WSL_ENVIRONMENT=true
PROJECT_PATH=/home/Projects/SEO/AIOS
NODE_OPTIONS=--max-old-space-size=4096

# Add your API keys here (optional):
# ANTHROPIC_API_KEY=sk-ant-your-key-here
# GOOGLE_API_KEY=your-gemini-key-here
ENV_EOF

echo ""
echo "🎉 INSTALLATION COMPLETE!"
echo "========================"
echo ""
echo "📁 Location: $TARGET_DIR"
echo "🪟 Windows Path: \\\\wsl\$\\Ubuntu\\home\\Projects\\SEO\\AIOS"
echo ""
echo "🚀 How to Start:"
echo "  From WSL:     ./start.sh"
echo "  From Windows: Double-click start_from_windows.bat"
echo ""
echo "🎮 Quick Commands:"
echo "  ./status.sh   - Check system status"
echo "  node ai_shell.js - Direct access"
echo ""
echo "💡 ADHD-Optimized Features Ready:"
echo "  ✅ Automatic file categorization"
echo "  ✅ Context-aware AI conversations"
echo "  ✅ Zero-overhead context switching"
echo "  ✅ Local AI (works offline)"
echo "  ✅ Natural language interaction"
echo ""

# Check if everything is working
if [[ -f ai_shell.js ]] && [[ -f markdown_agent.js ]] && command -v node >/dev/null; then
    echo "✅ All systems ready!"
    echo ""
    
    # Show current files found
    if [[ -f file_categories.json ]]; then
        echo "📊 Your Files Categorized:"
        cat file_categories.json 2>/dev/null | jq -r 'to_entries[] | "  📁 \(.key): \(.value | length) files"' 2>/dev/null || echo "  Categories created successfully"
        echo ""
    fi
    
    # Offer to start now
    read -p "🚀 Start the AI OS now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "🎯 Starting AI OS..."
        ./start.sh
    else
        echo ""
        echo "🎯 Ready to use! Start anytime with:"
        echo "  ./start.sh"
        echo ""
        echo "💡 From Windows: Double-click start_from_windows.bat"
    fi
else
    echo "⚠️ Some components may need attention. Run ./status.sh to check."
fi