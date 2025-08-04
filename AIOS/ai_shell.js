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
        this.loadEnvironment();
        this.loadContexts();
    }

    async loadEnvironment() {
        try {
            const envContent = await fs.readFile('.env', 'utf8');
            const lines = envContent.split('\n');
            for (const line of lines) {
                if (line.includes('=') && !line.startsWith('#')) {
                    const [key, value] = line.split('=');
                    if (key && value) {
                        process.env[key.trim()] = value.trim();
                    }
                }
            }
        } catch (error) {
            // .env file doesn't exist, that's fine
        }
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
            setup: () => this.setupAPIs(),
            
            // Quick context switches (will be updated after categorization)
            dev: () => this.switchContext('development'),
            development: () => this.switchContext('development'),
            seo: () => this.switchContext('seo'),
            docs: () => this.switchContext('documentation'),
            documentation: () => this.switchContext('documentation'),
            aios: () => this.switchContext('aios'),
            setup: () => this.switchContext('setup'),
            planning: () => this.switchContext('planning'),
            research: () => this.switchContext('research'),
            notes: () => this.switchContext('notes'),
            
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
        const availableContexts = Array.from(this.contexts.keys());
        
        console.log(`
🤖 AI Shell Commands:

Quick Context Switching:
${availableContexts.map(ctx => `  ${ctx.padEnd(12)} - Switch to ${ctx} context`).join('\n')}

General Commands:
  contexts         - List all contexts
  switch <name>    - Switch to specific context
  ask <question>   - Ask AI (context-aware)
  categorize       - Analyze/re-analyze files
  status           - Show system status
  setup            - Configure API keys
  help             - Show this help
  exit             - Exit shell

💡 ADHD-Friendly Tips:
  • Ask natural questions: "ask what should I work on next?"
  • Quick context switching preserves your flow
  • AI remembers your context across switches
  • Use "setup" to configure cloud APIs if local AI unavailable
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
            if (this.contexts.size === 0) {
                console.log('💡 Run "categorize" first to create contexts from your files.');
            }
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
            `Context: ${this.currentContext.name}\\nFiles: ${this.getContextFiles()}\\n\\n` : '';

        const fullPrompt = `${contextInfo}User: ${question}\\n\\nAssistant: I'll help you with your ${this.currentContext?.name || 'general'} work.`;

        // Try local AI first, then cloud APIs
        let response = await this.tryLocalAI(fullPrompt);
        if (!response) {
            response = await this.tryCloudAPIs(fullPrompt);
        }

        if (response) {
            console.log(`\\n💬 AI: ${response}\\n`);
        } else {
            console.log('❌ No AI service available. Try:');
            console.log('  1. Start local AI: ollama serve');
            console.log('  2. Setup cloud APIs: type "setup"');
        }
    }

    async tryLocalAI(prompt) {
        try {
            const response = await fetch('http://localhost:11434/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: 'llama3.2:1b',
                    prompt: prompt,
                    stream: false,
                    options: { temperature: 0.7 }
                })
            });

            if (response.ok) {
                const data = await response.json();
                return data.response;
            }
        } catch (error) {
            // Local AI not available
        }
        return null;
    }

    async tryCloudAPIs(prompt) {
        // Try Claude first
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

                if (response.ok) {
                    const data = await response.json();
                    return data.content[0].text;
                }
            } catch (error) {
                console.log('⚠️ Claude API error:', error.message);
            }
        }

        // Try Gemini
        if (process.env.GOOGLE_API_KEY) {
            try {
                const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${process.env.GOOGLE_API_KEY}`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        contents: [{
                            parts: [{ text: prompt }]
                        }],
                        generationConfig: {
                            temperature: 0.7,
                            topP: 0.8
                        }
                    })
                });

                if (response.ok) {
                    const data = await response.json();
                    return data.candidates[0].content.parts[0].text;
                }
            } catch (error) {
                console.log('⚠️ Gemini API error:', error.message);
            }
        }

        return null;
    }

    async setupAPIs() {
        console.log(`
🔑 API Setup Guide:

Current .env file status:
  Claude API: ${process.env.ANTHROPIC_API_KEY ? '✅ Configured' : '❌ Not set'}
  Gemini API: ${process.env.GOOGLE_API_KEY ? '✅ Configured' : '❌ Not set'}

To add API keys:
1. Edit your .env file: nano .env
2. Add these lines:
   ANTHROPIC_API_KEY=sk-ant-your-key-here
   GOOGLE_API_KEY=your-gemini-key-here

Get API keys:
📋 Claude: https://console.anthropic.com/
📋 Gemini: https://makersuite.google.com/app/apikey

After adding keys, restart the shell: exit and ./start.sh
        `);
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

🤖 AI Services:
  Local AI: ${this.checkLocalAI()}
  Claude API: ${process.env.ANTHROPIC_API_KEY ? '✅ Configured' : '❌ Not configured'}
  Gemini API: ${process.env.GOOGLE_API_KEY ? '✅ Configured' : '❌ Not configured'}
        `);
    }

    checkLocalAI() {
        try {
            execSync('pgrep -f "ollama serve"', { stdio: 'ignore' });
            return '✅ Running';
        } catch {
            return '❌ Not running';
        }
    }

    async start() {
        console.log('🚀 AI Shell Started for WSL');
        console.log('📁 AIOS Project Directory');
        console.log('Type "help" for commands or "ask <question>" to get started\\n');
        
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
            console.log('\\n👋 Goodbye! Your contexts are saved.');
            process.exit(0);
        });
    }
}

const shell = new AIShell();
shell.start();
