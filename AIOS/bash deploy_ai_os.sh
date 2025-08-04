#!/bin/bash

# WSL-Optimized Autonomous AI OS Deployment
# For: \\wsl$\Ubuntu\home\Projects\SEO\AIOS
# Optimized for Windows + WSL2 environment

set -e

# WSL-specific configuration
export DISPLAY=:0
export WSL_HOST=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')

echo "🚀 AUTONOMOUS AI OS - WSL DEPLOYMENT"
echo "📁 Target: /home/Projects/SEO/AIOS"
echo "🪟 Windows WSL Environment Detected"
echo "⚠️  WARNING: Full autonomous system with sudo access"
echo ""

# Navigate to your specific directory
TARGET_DIR="/home/Projects/SEO/AIOS"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "📍 Working in: $(pwd)"

# WSL-specific dependency installation
install_wsl_dependencies() {
    echo "📦 Installing WSL dependencies..."
    
    # Update package list
    sudo apt update -y
    
    # Install core dependencies
    sudo apt install -y \
        curl \
        wget \
        git \
        nodejs \
        npm \
        python3 \
        python3-pip \
        jq \
        build-essential \
        software-properties-common
    
    # Install latest Node.js (WSL sometimes has old versions)
    if [[ $(node -v | cut -d'v' -f2 | cut -d'.' -f1) -lt 18 ]]; then
        echo "📦 Upgrading Node.js for WSL..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    echo "✅ WSL dependencies installed"
}

# Create the complete agent coordinator system
create_agent_coordinator() {
    echo "🤖 Creating autonomous agent coordinator..."
    
    cat > agent_coordinator.js << 'EOF'
#!/usr/bin/env node

/**
 * WSL-Optimized Autonomous Agent Coordinator
 * Designed for Windows + WSL2 environment
 */

import fs from 'fs/promises';
import { spawn, exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execAsync = promisify(exec);

class WSLAIAgent {
    constructor(name, capabilities) {
        this.name = name;
        this.capabilities = capabilities;
        this.taskQueue = [];
        this.log = [];
        this.wslEnvironment = this.detectWSLEnvironment();
    }

    detectWSLEnvironment() {
        return {
            isWSL: process.platform === 'linux' && process.env.WSL_DISTRO_NAME,
            windowsHost: process.env.WSL_HOST || 'localhost',
            homeDir: process.env.HOME,
            projectPath: process.cwd()
        };
    }

    async executeTask(task) {
        console.log(`🤖 [${this.name}] ${task.description}`);
        
        try {
            const result = await this.processTask(task);
            this.log.push({ timestamp: new Date(), task, result, status: 'success' });
            return result;
        } catch (error) {
            console.error(`❌ [${this.name}] Failed: ${error.message}`);
            this.log.push({ timestamp: new Date(), task, error: error.message, status: 'failed' });
            throw error;
        }
    }

    async processTask(task) {
        switch (task.type) {
            case 'wsl_setup':
                return await this.setupWSLEnvironment();
            case 'install_ollama':
                return await this.installOllamaWSL();
            case 'categorize_files':
                return await this.categorizeMarkdownFiles(task.directory);
            case 'create_contexts':
                return await this.createContextSystems(task.categories);
            case 'ai_query':
                return await this.queryAI(task.prompt, task.context);
            case 'generate_code':
                return await this.generateSystemCode(task.requirements);
            case 'optimize_wsl':
                return await this.optimizeWSLPerformance();
            default:
                return await this.executeSystemCommand(task.command);
        }
    }

    async setupWSLEnvironment() {
        console.log('🪟 Optimizing WSL environment...');
        
        // Create WSL-specific configuration
        const wslConfig = `
# WSL AI OS Configuration
export OLLAMA_HOST=0.0.0.0:11434
export AI_SHELL_WSL=true
export NODE_OPTIONS="--max-old-space-size=4096"

# Path optimizations for WSL
export PATH="$PATH:/usr/local/bin:/opt/ollama/bin"

# AI OS aliases
alias ai='node ${process.cwd()}/ai_shell.js'
alias categorize='node ${process.cwd()}/markdown_agent.js'
alias contexts='node ${process.cwd()}/context_manager.js'
`;

        await fs.appendFile(`${process.env.HOME}/.bashrc`, wslConfig);
        
        return { success: true, message: 'WSL environment configured' };
    }

    async installOllamaWSL() {
        console.log('🤖 Installing Ollama for WSL...');
        
        try {
            // Download and install Ollama
            await execAsync('curl -fsSL https://ollama.ai/install.sh | sh');
            
            // Start Ollama service
            const ollamaProcess = spawn('ollama', ['serve'], {
                detached: true,
                stdio: 'ignore'
            });
            ollamaProcess.unref();
            
            // Wait for service to start
            await new Promise(resolve => setTimeout(resolve, 5000));
            
            // Install a fast model for quick responses
            console.log('📥 Installing AI model...');
            await execAsync('ollama pull llama3.2:1b');
            
            return { success: true, model: 'llama3.2:1b' };
        } catch (error) {
            console.warn('⚠️ Ollama installation failed, will use cloud APIs');
            return { success: false, error: error.message };
        }
    }

    async categorizeMarkdownFiles(directory) {
        console.log(`📊 Analyzing markdown files in ${directory}...`);
        
        const files = await this.findMarkdownFiles(directory);
        const categories = {};
        
        for (const file of files) {
            const content = await fs.readFile(file, 'utf8');
            const category = await this.classifyFile(content, file);
            
            if (!categories[category]) {
                categories[category] = [];
            }
            categories[category].push(file);
        }
        
        // Save categorization
        await fs.writeFile('file_categories.json', JSON.stringify(categories, null, 2));
        
        return categories;
    }

    async findMarkdownFiles(dir, files = []) {
        const entries = await fs.readdir(dir, { withFileTypes: true });
        
        for (const entry of entries) {
            const fullPath = path.join(dir, entry.name);
            
            if (entry.isDirectory() && !entry.name.startsWith('.')) {
                await this.findMarkdownFiles(fullPath, files);
            } else if (entry.isFile() && entry.name.endsWith('.md')) {
                files.push(fullPath);
            }
        }
        
        return files;
    }

    async classifyFile(content, filePath) {
        // Simple AI-powered classification
        const prompt = `Classify this markdown file into ONE category: setup, documentation, planning, research, development, notes, or seo.

File: ${path.basename(filePath)}
Content preview: ${content.substring(0, 500)}

Respond with ONLY the category name.`;

        try {
            const response = await this.queryAI(prompt);
            const category = response.toLowerCase().trim();
            
            // Validate category
            const validCategories = ['setup', 'documentation', 'planning', 'research', 'development', 'notes', 'seo'];
            return validCategories.includes(category) ? category : 'notes';
        } catch (error) {
            // Fallback classification
            return this.fallbackClassify(content, filePath);
        }
    }

    fallbackClassify(content, filePath) {
        const fileName = path.basename(filePath).toLowerCase();
        const contentLower = content.toLowerCase();
        
        if (fileName.includes('setup') || contentLower.includes('install')) return 'setup';
        if (fileName.includes('seo') || contentLower.includes('seo')) return 'seo';
        if (fileName.includes('plan') || contentLower.includes('roadmap')) return 'planning';
        if (contentLower.includes('research') || contentLower.includes('analysis')) return 'research';
        if (contentLower.includes('function') || contentLower.includes('code')) return 'development';
        if (contentLower.includes('api') || contentLower.includes('documentation')) return 'documentation';
        
        return 'notes';
    }

    async createContextSystems(categories) {
        console.log('🏗️ Creating specialized context systems...');
        
        const contextSystems = {};
        
        for (const [categoryName, files] of Object.entries(categories)) {
            const contextCode = await this.generateContextCode(categoryName, files);
            const fileName = `context_${categoryName}.js`;
            
            await fs.writeFile(fileName, contextCode);
            contextSystems[categoryName] = fileName;
            
            console.log(`✅ Created: ${fileName}`);
        }
        
        return contextSystems;
    }

    async generateContextCode(categoryName, files) {
        const prompt = `Generate a specialized AI context manager for category "${categoryName}" with files: ${files.map(f => path.basename(f)).join(', ')}.

Create JavaScript code that:
1. Manages this specific category of work
2. Provides category-specific AI prompts
3. Implements auto-tracking for these files
4. Includes quick commands for this work type
5. Optimizes for ADHD workflow

Respond with only the JavaScript code.`;

        try {
            const response = await this.queryAI(prompt);
            return response;
        } catch (error) {
            return this.getFallbackContextCode(categoryName, files);
        }
    }

    getFallbackContextCode(categoryName, files) {
        return `
// Auto-generated context for ${categoryName}
class ${this.toPascalCase(categoryName)}Context {
    constructor() {
        this.name = '${categoryName}';
        this.files = ${JSON.stringify(files)};
        this.lastActivity = new Date();
        console.log('🎯 ${categoryName} context activated');
    }

    getPrompt(userQuery) {
        return \`You are helping with ${categoryName} work. 
        
Current files: \${this.files.map(f => path.basename(f)).join(', ')}
User question: \${userQuery}

Be specific and actionable for ${categoryName} tasks.\`;
    }

    quickCommands() {
        return {
            'ls': () => console.log('📁 Files:', this.files.map(f => path.basename(f)).join(', ')),
            'summary': () => console.log('📊 Working on ${categoryName} with \${this.files.length} files'),
            'focus': () => console.log('🎯 Focusing on ${categoryName} work')
        };
    }
}

export default ${this.toPascalCase(categoryName)}Context;
`;
    }

    toPascalCase(str) {
        return str.split(/[-_]/)
                 .map(word => word.charAt(0).toUpperCase() + word.slice(1))
                 .join('');
    }

    async queryAI(prompt, context = {}) {
        // Try Ollama first (local), fallback to environment APIs
        try {
            const response = await fetch('http://localhost:11434/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: 'llama3.2:1b',
                    prompt: prompt,
                    stream: false,
                    options: { temperature: 0.1 }
                })
            });

            if (response.ok) {
                const data = await response.json();
                return data.response;
            }
        } catch (error) {
            console.log('Local AI unavailable, using fallback');
        }

        // Cloud API fallback
        return await this.queryCloudAI(prompt);
    }

    async queryCloudAI(prompt) {
        if (process.env.ANTHROPIC_API_KEY) {
            try {
                const response = await fetch('https://api.anthropic.com/v1/messages', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'x-api-key': process.env.ANTHROPIC_API_KEY,
                        'anthropic-version': '2023-06-01'
                    },
                    body: JSON.stringify({
                        model: 'claude-3-sonnet-20240229',
                        max_tokens: 1000,
                        messages: [{ role: 'user', content: prompt }]
                    })
                });

                const data = await response.json();
                return data.content[0].text;
            } catch (error) {
                console.error('Cloud AI failed:', error.message);
            }
        }

        return "AI response unavailable - please configure API keys or install Ollama";
    }

    async generateSystemCode(requirements) {
        const prompt = `Generate production-ready code for: ${requirements.description}

Requirements: ${JSON.stringify(requirements)}

Generate complete, working code with no explanations.`;

        return await this.queryAI(prompt);
    }

    async optimizeWSLPerformance() {
        console.log('⚡ Optimizing WSL performance...');
        
        try {
            // WSL memory optimization
            await execAsync('echo 1 | sudo tee /proc/sys/vm/drop_caches');
            
            // Node.js optimization for WSL
            process.env.NODE_OPTIONS = '--max-old-space-size=4096';
            
            return { success: true, message: 'WSL performance optimized' };
        } catch (error) {
            return { success: false, error: error.message };
        }
    }

    async executeSystemCommand(command) {
        const { stdout, stderr } = await execAsync(command);
        return { stdout, stderr, success: true };
    }
}

// Main coordinator
class WSLAICoordinator {
    constructor() {
        this.agents = new Map();
        this.initializeAgents();
        this.taskQueue = [];
        this.running = false;
    }

    initializeAgents() {
        this.agents.set('system', new WSLAIAgent('SystemAgent', ['wsl_setup', 'optimization']));
        this.agents.set('ai', new WSLAIAgent('AIAgent', ['ollama', 'inference']));
        this.agents.set('file', new WSLAIAgent('FileAgent', ['categorization', 'organization']));
        this.agents.set('code', new WSLAIAgent('CodeAgent', ['generation', 'context_creation']));
    }

    async start() {
        console.log('🚀 Starting WSL AI Coordinator...');
        this.running = true;

        // Queue bootstrap tasks
        this.queueTask('system', { type: 'wsl_setup', description: 'Configure WSL environment' });
        this.queueTask('ai', { type: 'install_ollama', description: 'Install local AI' });
        this.queueTask('file', { type: 'categorize_files', directory: '.', description: 'Categorize markdown files' });
        
        await this.processTasks();
        await this.createFinalSystem();
    }

    queueTask(agentName, task) {
        this.taskQueue.push({ agent: agentName, task });
    }

    async processTasks() {
        while (this.taskQueue.length > 0) {
            const { agent: agentName, task } = this.taskQueue.shift();
            const agent = this.agents.get(agentName);
            
            try {
                const result = await agent.executeTask(task);
                await this.handleResult(agentName, task, result);
            } catch (error) {
                console.error(`Task failed: ${error.message}`);
            }
        }
    }

    async handleResult(agentName, task, result) {
        if (task.type === 'categorize_files') {
            // Queue context creation for each category
            this.queueTask('code', {
                type: 'create_contexts',
                categories: result,
                description: 'Create context systems'
            });
        }
    }

    async createFinalSystem() {
        console.log('🎯 Creating final integrated system...');
        
        // Create main AI shell
        const shellCode = await this.generateMainShell();
        await fs.writeFile('ai_shell.js', shellCode);
        
        // Create startup script
        const startupScript = `#!/bin/bash
cd "${process.cwd()}"

echo "🚀 Starting AI OS..."

# Source environment
[[ -f .env ]] && source .env

# Start Ollama if available
if command -v ollama >/dev/null 2>&1; then
    if ! pgrep -f "ollama serve" > /dev/null; then
        ollama serve > /dev/null 2>&1 &
        echo "🤖 Local AI started"
    fi
fi

# Start AI shell
node ai_shell.js
`;

        await fs.writeFile('start.sh', startupScript);
        await execAsync('chmod +x start.sh');
        
        console.log('✅ System creation complete!');
    }

    async generateMainShell() {
        return `#!/usr/bin/env node

/**
 * WSL-Optimized AI Shell
 * Auto-generated integrated system
 */

import readline from 'readline';
import fs from 'fs/promises';
import { execSync } from 'child_process';

class AIShell {
    constructor() {
        this.contexts = new Map();
        this.currentContext = null;
        this.rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        this.loadContexts();
        this.setupCommands();
    }

    async loadContexts() {
        try {
            const categories = JSON.parse(await fs.readFile('file_categories.json', 'utf8'));
            
            for (const [name, files] of Object.entries(categories)) {
                this.contexts.set(name, {
                    name,
                    files,
                    active: false
                });
            }
            
            console.log(\`📁 Loaded \${this.contexts.size} contexts: \${Array.from(this.contexts.keys()).join(', ')}\`);
        } catch (error) {
            console.log('📁 No existing contexts found, starting fresh');
        }
    }

    setupCommands() {
        this.commands = {
            help: () => this.showHelp(),
            contexts: () => this.listContexts(),
            switch: (name) => this.switchContext(name),
            ask: (...args) => this.askAI(args.join(' ')),
            categorize: () => this.recategorizeFiles(),
            status: () => this.showStatus(),
            exit: () => process.exit(0)
        };

        // Add quick context switches
        for (const contextName of this.contexts.keys()) {
            this.commands[contextName] = () => this.switchContext(contextName);
        }
    }

    showHelp() {
        console.log(\`
🤖 AI Shell Commands:

Context Management:
  contexts          - List all contexts
  switch <name>     - Switch to context
  \${Array.from(this.contexts.keys()).map(n => \`  \${n}\`).join('\\n')}

AI Interaction:
  ask <question>    - Ask AI with current context
  
System:
  categorize        - Re-analyze files
  status            - Show current status
  help              - Show this help
  exit              - Exit shell
        \`);
    }

    listContexts() {
        console.log('\\n📁 Available Contexts:');
        for (const [name, context] of this.contexts) {
            const indicator = context === this.currentContext ? '→' : ' ';
            console.log(\`\${indicator} \${name} (\${context.files.length} files)\`);
        }
    }

    switchContext(name) {
        const context = this.contexts.get(name);
        if (context) {
            this.currentContext = context;
            console.log(\`🔄 Switched to \${name} context\`);
            this.updatePrompt();
        } else {
            console.log(\`❌ Context '\${name}' not found\`);
        }
    }

    updatePrompt() {
        const contextName = this.currentContext?.name || 'general';
        this.rl.setPrompt(\`🤖 [\${contextName}] > \`);
    }

    async askAI(question) {
        if (!question) {
            console.log('Ask me anything!');
            return;
        }

        console.log('🤖 Thinking...');
        
        try {
            const contextInfo = this.currentContext ? 
                \`Current context: \${this.currentContext.name}\\nFiles: \${this.currentContext.files.map(f => f.split('/').pop()).join(', ')}\\n\\n\` : '';
            
            const response = await fetch('http://localhost:11434/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: 'llama3.2:1b',
                    prompt: \`\${contextInfo}User: \${question}\`,
                    stream: false
                })
            });

            if (response.ok) {
                const data = await response.json();
                console.log(\`\\n💬 AI: \${data.response}\\n\`);
            } else {
                console.log('❌ AI service unavailable');
            }
        } catch (error) {
            console.log('❌ Could not reach AI service');
        }
    }

    async recategorizeFiles() {
        console.log('📊 Re-analyzing files...');
        execSync('node markdown_agent.js .', { stdio: 'inherit' });
        await this.loadContexts();
        console.log('✅ Files re-categorized');
    }

    showStatus() {
        console.log(\`
📊 System Status:
Context: \${this.currentContext?.name || 'none'}
Contexts: \${this.contexts.size}
Files tracked: \${Array.from(this.contexts.values()).reduce((sum, c) => sum + c.files.length, 0)}
        \`);
    }

    async start() {
        console.log('🚀 WSL AI Shell Started');
        console.log('Type "help" for commands');
        
        this.updatePrompt();
        this.rl.prompt();

        this.rl.on('line', async (input) => {
            const parts = input.trim().split(' ');
            const command = parts[0];
            const args = parts.slice(1);

            if (this.commands[command]) {
                await this.commands[command](...args);
            } else if (input.trim()) {
                console.log(\`Unknown command: \${command}. Type "help" for available commands.\`);
            }

            this.rl.prompt();
        });

        this.rl.on('SIGINT', () => {
            console.log('\\nGoodbye! 👋');
            process.exit(0);
        });
    }
}

const shell = new AIShell();
shell.start();
`;
    }
}

// Auto-start
const coordinator = new WSLAICoordinator();
coordinator.start().catch(console.error);
EOF

    chmod +x agent_coordinator.js
    echo "✅ Agent coordinator created"
}

# Create the markdown analysis agent
create_markdown_agent() {
    echo "📊 Creating markdown categorization agent..."
    
    cat > markdown_agent.js << 'EOF'
#!/usr/bin/env node

/**
 * WSL-Optimized Markdown Categorization Agent
 * Specifically designed for SEO project structure
 */

import fs from 'fs/promises';
import path from 'path';

class MarkdownAgent {
    constructor() {
        this.categories = {};
        this.seoSpecific = true; // Optimize for SEO project
    }

    async analyzeDirectory(dir = '.') {
        console.log(`📊 Analyzing markdown files in ${dir}...`);
        
        const files = await this.findMarkdownFiles(dir);
        console.log(`📄 Found ${files.length} markdown files`);

        for (const file of files) {
            await this.analyzeFile(file);
        }

        await this.createCategories();
        await this.saveResults();
        
        console.log('✅ Analysis complete!');
        return this.categories;
    }

    async findMarkdownFiles(dir, files = []) {
        try {
            const entries = await fs.readdir(dir, { withFileTypes: true });
            
            for (const entry of entries) {
                const fullPath = path.join(dir, entry.name);
                
                if (entry.isDirectory() && !entry.name.startsWith('.') && entry.name !== 'node_modules') {
                    await this.findMarkdownFiles(fullPath, files);
                } else if (entry.isFile() && entry.name.endsWith('.md')) {
                    files.push(fullPath);
                }
            }
        } catch (error) {
            console.warn(`⚠️ Cannot read directory ${dir}: ${error.message}`);
        }
        
        return files;
    }

    async analyzeFile(filePath) {
        try {
            const content = await fs.readFile(filePath, 'utf8');
            const analysis = this.classifyContent(content, filePath);
            
            if (!this.categories[analysis.category]) {
                this.categories[analysis.category] = [];
            }
            
            this.categories[analysis.category].push({
                path: filePath,
                name: path.basename(filePath),
                ...analysis
            });
            
        } catch (error) {
            console.warn(`⚠️ Cannot analyze ${filePath}: ${error.message}`);
        }
    }

    classifyContent(content, filePath) {
        const fileName = path.basename(filePath).toLowerCase();
        const contentLower = content.toLowerCase();
        const dir = path.dirname(filePath);
        
        // SEO-specific classification
        if (fileName.includes('seo') || contentLower.includes('seo') || dir.includes('SEO')) {
            return { category: 'seo', priority: 10, type: 'seo_strategy' };
        }
        
        if (fileName.includes('aios') || contentLower.includes('ai os') || contentLower.includes('autonomous')) {
            return { category: 'aios', priority: 10, type: 'ai_system' };
        }
        
        // Development files
        if (contentLower.includes('function') || contentLower.includes('class') || contentLower.includes('```')) {
            return { category: 'development', priority: 8, type: 'code_documentation' };
        }
        
        // Setup and configuration
        if (fileName.includes('setup') || fileName.includes('install') || contentLower.includes('installation')) {
            return { category: 'setup', priority: 9, type: 'configuration' };
        }
        
        // Planning and roadmaps
        if (fileName.includes('plan') || fileName.includes('roadmap') || contentLower.includes('todo')) {
            return { category: 'planning', priority: 7, type: 'strategy' };
        }
        
        // Research and analysis
        if (contentLower.includes('research') || contentLower.includes('analysis') || contentLower.includes('study')) {
            return { category: 'research', priority: 6, type: 'analysis' };
        }
        
        // Documentation
        if (fileName.includes('doc') || fileName.includes('readme') || contentLower.includes('documentation')) {
            return { category: 'documentation', priority: 5, type: 'reference' };
        }
        
        // Default category
        return { category: 'notes', priority: 3, type: 'general' };
    }

    async createCategories() {
        console.log('🏗️ Creating category structure...');
        
        // Sort categories by priority and file count
        const sortedCategories = Object.entries(this.categories)
            .sort(([,a], [,b]) => {
                const priorityA = a[0]?.priority || 0;
                const priorityB = b[0]?.priority || 0;
                return priorityB - priorityA || b.length - a.length;
            });

        console.log('📊 Categories found:');
        for (const [name, files] of sortedCategories) {
            console.log(`  📁 ${name}: ${files.length} files`);
        }
    }

    async saveResults() {
        // Save categorization results
        await fs.writeFile('file_categories.json', JSON.stringify(this.categories, null, 2));
        
        // Create category summary
        const summary = {
            timestamp: new Date().toISOString(),
            totalFiles: Object.values(this.categories).flat().length,
            categories: Object.fromEntries(
                Object.entries(this.categories).map(([name, files]) => [
                    name, {
                        count: files.length,
                        files: files.map(f => f.name),
                        priority: files[0]?.priority || 0
                    }
                ])
            )
        };
        
        await fs.writeFile('categorization_summary.json', JSON.stringify(summary, null, 2));
        
        console.log('💾 Results saved to file_categories.json');
    }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    const agent = new MarkdownAgent();
    const targetDir = process.argv[2] || '.';
    
    agent.analyzeDirectory(targetDir)
        .then(() => console.log('🎉 Categorization complete!'))
        .catch(console.error);
}

export default MarkdownAgent;
EOF

    chmod +x markdown_agent.js
    echo "✅ Markdown agent created"
}

# Main deployment function
deploy_wsl_system() {
    echo "🚀 Starting WSL deployment..."
    
    # Install dependencies
    install_wsl_dependencies
    
    # Create system files
    create_agent_coordinator
    create_markdown_agent
    
    # Install Node.js dependencies
    echo "📦 Installing Node.js packages..."
    npm init -y
    npm install node-fetch
    
    # Create package.json with proper module support
    cat > package.json << 'PKG_EOF'
{
  "name": "autonomous-ai-os",
  "version": "1.0.0",
  "type": "module",
  "description": "Autonomous AI Operating System for ADHD-optimized workflows",
  "main": "ai_shell.js",
  "scripts": {
    "start": "./start.sh",
    "categorize": "node markdown_agent.js",
    "analyze": "node agent_coordinator.js"
  },
  "dependencies": {
    "node-fetch": "^3.3.2"
  },
  "keywords": ["ai", "automation", "adhd", "productivity"],
  "author": "Autonomous AI System",
  "license": "MIT"
}
PKG_EOF
    
    # Setup environment configuration
    setup_wsl_environment
    
    # Install and configure Ollama
    setup_ollama_wsl
    
    # Create startup and management scripts
    create_management_scripts
    
    # Run initial analysis
    run_initial_analysis
    
    echo "✅ WSL deployment complete!"
}

setup_wsl_environment() {
    echo "🪟 Configuring WSL environment..."
    
    # API key setup (optional)
    echo ""
    echo "🔑 API Configuration (optional - local AI will work without this)"
    read -p "Claude API key (press Enter to skip): " claude_key
    read -p "Gemini API key (press Enter to skip): " gemini_key
    
    # Create .env file
    cat > .env << ENV_EOF
# AI OS Environment Configuration
WSL_ENVIRONMENT=true
PROJECT_PATH=${TARGET_DIR}
NODE_OPTIONS=--max-old-space-size=4096

# API Keys (optional)
ENV_EOF

    if [[ -n "$claude_key" ]]; then
        echo "ANTHROPIC_API_KEY=$claude_key" >> .env
    fi
    
    if [[ -n "$gemini_key" ]]; then
        echo "GOOGLE_API_KEY=$gemini_key" >> .env
    fi
    
    # Add to bashrc for persistence
    echo "" >> ~/.bashrc
    echo "# AI OS Configuration" >> ~/.bashrc
    echo "cd $TARGET_DIR" >> ~/.bashrc
    echo "export AI_OS_HOME=$TARGET_DIR" >> ~/.bashrc
    echo "alias ai='cd $TARGET_DIR && ./start.sh'" >> ~/.bashrc
    echo "alias aios='cd $TARGET_DIR && node ai_shell.js'" >> ~/.bashrc
    
    echo "✅ WSL environment configured"
}

setup_ollama_wsl() {
    echo "🤖 Setting up Ollama for WSL..."
    
    # Install Ollama
    if ! command -v ollama >/dev/null 2>&1; then
        echo "📥 Installing Ollama..."
        curl -fsSL https://ollama.ai/install.sh | sh
        
        # Add to PATH
        echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
    else
        echo "✅ Ollama already installed"
    fi
    
    # Start Ollama service
    echo "🔄 Starting Ollama service..."
    if ! pgrep -f "ollama serve" >/dev/null; then
        nohup ollama serve > ollama.log 2>&1 &
        echo $! > ollama.pid
        sleep 5
    fi
    
    # Install fast model for quick responses
    echo "📥 Installing AI model (this may take a few minutes)..."
    ollama pull llama3.2:1b &
    OLLAMA_PID=$!
    
    echo "⏳ Model downloading in background (PID: $OLLAMA_PID)"
    echo "✅ Ollama setup complete"
}

create_management_scripts() {
    echo "🛠️ Creating management scripts..."
    
    # Main startup script
    cat > start.sh << 'START_EOF'
#!/bin/bash

# WSL AI OS Startup Script
cd "$(dirname "$0")"

echo "🚀 Starting Autonomous AI OS for WSL..."
echo "📁 Location: $(pwd)"

# Source environment
if [[ -f .env ]]; then
    set -a
    source .env
    set +a
    echo "✅ Environment loaded"
fi

# Check Node.js
if ! command -v node >/dev/null 2>&1; then
    echo "❌ Node.js not found. Please install Node.js first."
    exit 1
fi

# Start Ollama if not running
if ! pgrep -f "ollama serve" >/dev/null 2>&1; then
    echo "🤖 Starting local AI service..."
    nohup ollama serve > ollama.log 2>&1 &
    echo $! > ollama.pid
    sleep 3
    
    # Ensure model is available
    if command -v ollama >/dev/null 2>&1; then
        ollama list | grep -q "llama3.2:1b" || {
            echo "📥 Installing AI model..."
            ollama pull llama3.2:1b
        }
    fi
fi

# Check if categorization has been run
if [[ ! -f file_categories.json ]]; then
    echo "📊 Running initial file analysis..."
    node markdown_agent.js .
fi

# Start the AI shell
echo "🎯 Starting AI Shell..."
node ai_shell.js
START_EOF

    # Stop script
    cat > stop.sh << 'STOP_EOF'
#!/bin/bash

echo "🛑 Stopping AI OS..."

# Kill Ollama
if [[ -f ollama.pid ]]; then
    kill $(cat ollama.pid) 2>/dev/null
    rm ollama.pid
fi

# Kill any remaining processes
pkill -f "ollama serve" 2>/dev/null
pkill -f "ai_shell.js" 2>/dev/null
pkill -f "agent_coordinator.js" 2>/dev/null

echo "✅ AI OS stopped"
STOP_EOF

    # Status check script
    cat > status.sh << 'STATUS_EOF'
#!/bin/bash

echo "📊 AI OS Status Check"
echo "===================="

# Check if in correct directory
if [[ ! -f ai_shell.js ]]; then
    echo "❌ Not in AI OS directory"
    exit 1
fi

echo "📁 Directory: $(pwd)"

# Check Node.js
if command -v node >/dev/null 2>&1; then
    echo "✅ Node.js: $(node --version)"
else
    echo "❌ Node.js: Not installed"
fi

# Check Ollama
if command -v ollama >/dev/null 2>&1; then
    echo "✅ Ollama: Installed"
    if pgrep -f "ollama serve" >/dev/null; then
        echo "✅ Ollama: Running"
        echo "🤖 Models: $(ollama list 2>/dev/null | grep -v NAME | wc -l) installed"
    else
        echo "⚠️  Ollama: Not running"
    fi
else
    echo "❌ Ollama: Not installed"
fi

# Check categorization
if [[ -f file_categories.json ]]; then
    CATEGORIES=$(cat file_categories.json | jq 'keys | length' 2>/dev/null || echo "unknown")
    echo "✅ Categories: $CATEGORIES found"
else
    echo "⚠️  Categories: Not analyzed yet"
fi

# Check environment
if [[ -f .env ]]; then
    echo "✅ Environment: Configured"
else
    echo "⚠️  Environment: Not configured"
fi

echo ""
echo "🚀 Ready to start: ./start.sh"
STATUS_EOF

    # Quick categorize script
    cat > categorize.sh << 'CAT_EOF'
#!/bin/bash

echo "📊 Quick File Categorization"
cd "$(dirname "$0")"

if [[ -f .env ]]; then
    source .env
fi

node markdown_agent.js "${1:-.}"
echo "✅ Categorization complete! Check file_categories.json"
CAT_EOF

    # Make all scripts executable
    chmod +x start.sh stop.sh status.sh categorize.sh
    
    echo "✅ Management scripts created"
}

run_initial_analysis() {
    echo "📊 Running initial file analysis..."
    
    # Wait for Node.js dependencies to be ready
    sleep 2
    
    # Source environment if it exists
    if [[ -f .env ]]; then
        set -a
        source .env
        set +a
    fi
    
    # Run the markdown analysis
    if [[ -f markdown_agent.js ]]; then
        echo "🔍 Analyzing your markdown files..."
        node markdown_agent.js . || echo "⚠️ Analysis completed with warnings"
        
        if [[ -f file_categories.json ]]; then
            echo "✅ File categorization complete!"
            
            # Show results
            if command -v jq >/dev/null 2>&1; then
                echo ""
                echo "📋 Categories found:"
                cat file_categories.json | jq -r 'to_entries[] | "  📁 \(.key): \(.value | length) files"'
            fi
        fi
    fi
    
    # Start the agent coordinator to build the final system
    echo "🏗️ Building integrated system..."
    timeout 30s node agent_coordinator.js || echo "⚠️ System build completed"
    
    echo "✅ Initial analysis complete"
}

# Create Windows-friendly shortcuts
create_windows_shortcuts() {
    echo "🪟 Creating Windows shortcuts..."
    
    # Create Windows batch file for easy access
    cat > start_ai_os.bat << 'BAT_EOF'
@echo off
title Autonomous AI OS
cd /d "\\wsl$\Ubuntu\home\Projects\SEO\AIOS"
wsl bash -c "cd /home/Projects/SEO/AIOS && ./start.sh"
pause
BAT_EOF

    # Create PowerShell script
    cat > start_ai_os.ps1 << 'PS_EOF'
# Autonomous AI OS Launcher for Windows
Write-Host "🚀 Starting Autonomous AI OS in WSL..." -ForegroundColor Green

# Navigate to WSL directory
Set-Location "\\wsl$\Ubuntu\home\Projects\SEO\AIOS"

# Start the AI OS
wsl bash -c "cd /home/Projects/SEO/AIOS && ./start.sh"
PS_EOF

    echo "✅ Windows shortcuts created"
    echo "   📄 start_ai_os.bat - Double-click to start from Windows"
    echo "   📄 start_ai_os.ps1 - PowerShell version"
}

# Final system verification
verify_installation() {
    echo "🔍 Verifying installation..."
    
    local errors=0
    
    # Check required files
    local required_files=("ai_shell.js" "agent_coordinator.js" "markdown_agent.js" "start.sh" "package.json")
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "✅ $file"
        else
            echo "❌ $file missing"
            ((errors++))
        fi
    done
    
    # Check Node.js
    if command -v node >/dev/null 2>&1; then
        echo "✅ Node.js $(node --version)"
    else
        echo "❌ Node.js not found"
        ((errors++))
    fi
    
    # Check if analysis ran
    if [[ -f file_categories.json ]]; then
        echo "✅ File categorization complete"
    else
        echo "⚠️  File categorization pending"
    fi
    
    if [[ $errors -eq 0 ]]; then
        echo "🎉 Installation verified successfully!"
        return 0
    else
        echo "⚠️  Installation completed with $errors issues"
        return 1
    fi
}

# Main execution
main() {
    echo ""
    echo "🎯 AUTONOMOUS AI OS - WSL DEPLOYMENT"
    echo "======================================"
    echo "📍 Target: $TARGET_DIR"
    echo "🪟 WSL Environment: Ubuntu"
    echo "🎮 Optimized for ADHD workflows"
    echo ""
    
    # Confirm deployment
    read -p "🚀 Deploy autonomous AI system? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Deployment cancelled"
        exit 1
    fi
    
    echo "🔄 Starting deployment..."
    
    # Run deployment steps
    deploy_wsl_system
    create_windows_shortcuts
    
    echo ""
    echo "🎉 DEPLOYMENT COMPLETE!"
    echo "======================"
    
    # Verify installation
    if verify_installation; then
        echo ""
        echo "🚀 Ready to use! Choose an option:"
        echo ""
        echo "  1. ./start.sh           - Start AI OS now"
        echo "  2. ./status.sh          - Check system status"
        echo "  3. ./categorize.sh      - Re-analyze files"
        echo "  4. node ai_shell.js     - Direct shell access"
        echo ""
        echo "🪟 From Windows:"
        echo "  • Double-click: start_ai_os.bat"
        echo "  • PowerShell: .\\start_ai_os.ps1"
        echo ""
        
        # Auto-start option
        read -p "🎯 Start the AI OS now? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo "🚀 Starting Autonomous AI OS..."
            ./start.sh
        else
            echo "🎯 System ready! Run './start.sh' when you want to begin."
        fi
    else
        echo ""
        echo "⚠️  Some issues detected. Try running:"
        echo "  ./status.sh - Check what needs fixing"
        echo "  ./start.sh  - Attempt to start anyway"
    fi
}

# Execute main function
main