#!/usr/bin/env node

/**
 * AI Shell Proof of Concept
 * A minimal shell that demonstrates multi-context AI workspace management
 * Designed for ADHD-friendly workflow patterns
 */

import readline from 'readline';
import fs from 'fs/promises';
import path from 'path';
import { spawn } from 'child_process';

class AIContext {
  constructor(name, description = '') {
    this.name = name;
    this.description = description;
    this.history = [];
    this.files = new Set();
    this.lastActivity = new Date();
    this.currentDirectory = process.cwd();
    this.metadata = {};
  }

  addToHistory(command, result, timestamp = new Date()) {
    this.history.push({ command, result, timestamp });
    this.lastActivity = timestamp;
    
    // Keep history manageable (last 50 entries)
    if (this.history.length > 50) {
      this.history = this.history.slice(-50);
    }
  }

  addFile(filePath) {
    this.files.add(path.resolve(filePath));
  }

  getContextSummary() {
    const recentCommands = this.history.slice(-5);
    return {
      name: this.name,
      description: this.description,
      recentActivity: this.lastActivity,
      fileCount: this.files.size,
      recentCommands: recentCommands.map(h => h.command),
      currentDir: this.currentDirectory,
      metadata: this.metadata
    };
  }

  serialize() {
    return {
      name: this.name,
      description: this.description,
      history: this.history,
      files: Array.from(this.files),
      currentDirectory: this.currentDirectory,
      metadata: this.metadata,
      lastActivity: this.lastActivity.toISOString()
    };
  }

  static deserialize(data) {
    const context = new AIContext(data.name, data.description);
    context.history = data.history || [];
    context.files = new Set(data.files || []);
    context.currentDirectory = data.currentDirectory || process.cwd();
    context.metadata = data.metadata || {};
    context.lastActivity = new Date(data.lastActivity || Date.now());
    return context;
  }
}

class AIShell {
  constructor() {
    this.contexts = new Map();
    this.currentContext = null;
    this.configDir = path.join(process.env.HOME || process.env.USERPROFILE, '.aishell');
    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      prompt: '🤖 > '
    });

    this.setupCommands();
    this.loadContexts();
  }

  async init() {
    await this.ensureConfigDir();
    console.log('🚀 AI Shell v0.1 - ADHD-Friendly Multi-Context Environment');
    console.log('Type "help" for commands, "switch <context>" to change contexts');
    console.log('Current contexts:', Array.from(this.contexts.keys()).join(', ') || 'none');
    
    this.updatePrompt();
    this.rl.prompt();
  }

  async ensureConfigDir() {
    try {
      await fs.mkdir(this.configDir, { recursive: true });
    } catch (error) {
      console.error('Failed to create config directory:', error.message);
    }
  }

  updatePrompt() {
    const contextName = this.currentContext?.name || 'no-context';
    const dir = path.basename(process.cwd());
    this.rl.setPrompt(`🤖 [${contextName}] ${dir} > `);
  }

  setupCommands() {
    this.commands = {
      help: () => this.showHelp(),
      contexts: () => this.listContexts(),
      switch: (name) => this.switchContext(name),
      create: (name, description) => this.createContext(name, description),
      delete: (name) => this.deleteContext(name),
      status: () => this.showStatus(),
      save: () => this.saveContexts(),
      load: () => this.loadContexts(),
      history: () => this.showHistory(),
      files: () => this.showFiles(),
      cd: (dir) => this.changeDirectory(dir),
      ls: () => this.listDirectory(),
      track: (file) => this.trackFile(file),
      simulate: (prompt) => this.simulateAI(prompt),
      clear: () => console.clear(),
      exit: () => this.exit()
    };
  }

  async processCommand(input) {
    const parts = input.trim().split(' ');
    const command = parts[0];
    const args = parts.slice(1);

    if (this.commands[command]) {
      try {
        const result = await this.commands[command](...args);
        
        // Track command in current context
        if (this.currentContext) {
          this.currentContext.addToHistory(input, result || 'completed');
        }
        
        return result;
      } catch (error) {
        console.error(`Error executing ${command}:`, error.message);
        return `Error: ${error.message}`;
      }
    } else {
      // Try to execute as system command
      return await this.executeSystemCommand(input);
    }
  }

  async executeSystemCommand(command) {
    return new Promise((resolve) => {
      const child = spawn('bash', ['-c', command], {
        stdio: 'inherit',
        cwd: this.currentContext?.currentDirectory || process.cwd()
      });

      child.on('close', (code) => {
        const result = `Command exited with code ${code}`;
        if (this.currentContext) {
          this.currentContext.addToHistory(command, result);
        }
        resolve(result);
      });

      child.on('error', (error) => {
        console.error('Command failed:', error.message);
        resolve(`Error: ${error.message}`);
      });
    });
  }

  showHelp() {
    console.log(`
🤖 AI Shell Commands:

Context Management:
  contexts                 - List all contexts
  create <name> [desc]     - Create new context
  switch <name>            - Switch to context
  delete <name>            - Delete context
  status                   - Show current context status

File Operations:
  cd <directory>           - Change directory
  ls                       - List current directory
  track <file>             - Track file in current context
  files                    - Show tracked files

System:
  history                  - Show command history
  save                     - Save all contexts
  load                     - Load saved contexts
  simulate <prompt>        - Simulate AI response
  clear                    - Clear screen
  exit                     - Exit shell

Any other command will be executed as a system command.
    `);
  }

  listContexts() {
    if (this.contexts.size === 0) {
      console.log('No contexts created yet. Use "create <name>" to start.');
      return;
    }

    console.log('\n📁 Available Contexts:');
    for (const [name, context] of this.contexts) {
      const isCurrent = context === this.currentContext;
      const summary = context.getContextSummary();
      const timeAgo = this.getTimeAgo(summary.recentActivity);
      
      console.log(`${isCurrent ? '→' : ' '} ${name} (${summary.fileCount} files, ${timeAgo})`);
      if (summary.description) {
        console.log(`   ${summary.description}`);
      }
    }
    console.log();
  }

  async createContext(name, description = '') {
    if (!name) {
      console.log('Usage: create <name> [description]');
      return;
    }

    if (this.contexts.has(name)) {
      console.log(`Context "${name}" already exists.`);
      return;
    }

    const context = new AIContext(name, description);
    context.currentDirectory = process.cwd();
    this.contexts.set(name, context);
    
    console.log(`✨ Created context "${name}"`);
    
    // Auto-switch to new context
    return this.switchContext(name);
  }

  switchContext(name) {
    if (!name) {
      console.log('Usage: switch <name>');
      return;
    }

    const context = this.contexts.get(name);
    if (!context) {
      console.log(`Context "${name}" not found. Available: ${Array.from(this.contexts.keys()).join(', ')}`);
      return;
    }

    this.currentContext = context;
    
    // Change to context's directory
    try {
      process.chdir(context.currentDirectory);
    } catch (error) {
      console.log(`Warning: Could not change to ${context.currentDirectory}`);
    }

    this.updatePrompt();
    console.log(`🔄 Switched to context "${name}"`);
    
    // Show quick context summary
    const summary = context.getContextSummary();
    if (summary.recentCommands.length > 0) {
      console.log(`   Recent: ${summary.recentCommands.slice(-2).join(', ')}`);
    }
  }

  deleteContext(name) {
    if (!name) {
      console.log('Usage: delete <name>');
      return;
    }

    if (!this.contexts.has(name)) {
      console.log(`Context "${name}" not found.`);
      return;
    }

    this.contexts.delete(name);
    
    if (this.currentContext?.name === name) {
      this.currentContext = null;
      this.updatePrompt();
    }

    console.log(`🗑️ Deleted context "${name}"`);
  }

  showStatus() {
    if (!this.currentContext) {
      console.log('No active context. Use "create <name>" or "switch <name>".');
      return;
    }

    const summary = this.currentContext.getContextSummary();
    console.log(`
📊 Context Status: ${summary.name}
Description: ${summary.description || 'None'}
Directory: ${summary.currentDir}
Files tracked: ${summary.fileCount}
Recent activity: ${this.getTimeAgo(summary.recentActivity)}
Recent commands: ${summary.recentCommands.slice(-3).join(', ') || 'None'}
    `);
  }

  showHistory() {
    if (!this.currentContext) {
      console.log('No active context.');
      return;
    }

    const history = this.currentContext.history.slice(-10);
    console.log(`\n📜 Recent History (${this.currentContext.name}):`);
    
    history.forEach((entry, i) => {
      const time = new Date(entry.timestamp).toLocaleTimeString();
      console.log(`${i + 1}. [${time}] ${entry.command}`);
    });
    console.log();
  }

  showFiles() {
    if (!this.currentContext) {
      console.log('No active context.');
      return;
    }

    const files = Array.from(this.currentContext.files);
    console.log(`\n📁 Tracked Files (${this.currentContext.name}):`);
    
    if (files.length === 0) {
      console.log('No files tracked. Use "track <file>" to add files.');
    } else {
      files.forEach((file, i) => {
        const relative = path.relative(process.cwd(), file);
        console.log(`${i + 1}. ${relative}`);
      });
    }
    console.log();
  }

  changeDirectory(dir) {
    if (!dir) {
      console.log(process.cwd());
      return;
    }

    try {
      process.chdir(dir);
      
      if (this.currentContext) {
        this.currentContext.currentDirectory = process.cwd();
      }
      
      this.updatePrompt();
      console.log(`📂 Changed to ${process.cwd()}`);
    } catch (error) {
      console.log(`cd: ${error.message}`);
    }
  }

  async listDirectory() {
    try {
      const files = await fs.readdir(process.cwd());
      console.log(files.join('  '));
    } catch (error) {
      console.log(`ls: ${error.message}`);
    }
  }

  trackFile(filePath) {
    if (!this.currentContext) {
      console.log('No active context. Create or switch to a context first.');
      return;
    }

    if (!filePath) {
      console.log('Usage: track <file>');
      return;
    }

    this.currentContext.addFile(filePath);
    console.log(`📎 Tracking ${filePath} in context "${this.currentContext.name}"`);
  }

  simulateAI(prompt) {
    if (!prompt) {
      console.log('Usage: simulate <your prompt>');
      return;
    }

    // Simulate an AI response based on current context
    const contextInfo = this.currentContext ? this.currentContext.getContextSummary() : null;
    
    console.log(`\n🤖 Simulated AI Response to: "${prompt}"`);
    console.log('─'.repeat(50));
    
    if (contextInfo) {
      console.log(`Based on your current context "${contextInfo.name}":`);
      console.log(`- Working directory: ${contextInfo.currentDir}`);
      console.log(`- ${contextInfo.fileCount} tracked files`);
      console.log(`- Recent commands: ${contextInfo.recentCommands.slice(-2).join(', ')}`);
    }
    
    console.log(`\nI understand you want to: ${prompt}`);
    console.log('In a real implementation, I would:');
    console.log('1. Analyze your current context and files');
    console.log('2. Execute the appropriate MCP tools');
    console.log('3. Provide intelligent suggestions based on your workflow');
    console.log('4. Remember this interaction for future context');
    console.log('─'.repeat(50));
  }

  async saveContexts() {
    try {
      const data = {};
      for (const [name, context] of this.contexts) {
        data[name] = context.serialize();
      }
      
      const filePath = path.join(this.configDir, 'contexts.json');
      await fs.writeFile(filePath, JSON.stringify(data, null, 2));
      console.log(`💾 Saved ${this.contexts.size} contexts to ${filePath}`);
    } catch (error) {
      console.error('Failed to save contexts:', error.message);
    }
  }

  async loadContexts() {
    try {
      const filePath = path.join(this.configDir, 'contexts.json');
      const data = JSON.parse(await fs.readFile(filePath, 'utf8'));
      
      this.contexts.clear();
      for (const [name, contextData] of Object.entries(data)) {
        this.contexts.set(name, AIContext.deserialize(contextData));
      }
      
      console.log(`📂 Loaded ${this.contexts.size} contexts`);
    } catch (error) {
      if (error.code !== 'ENOENT') {
        console.error('Failed to load contexts:', error.message);
      }
    }
  }

  getTimeAgo(date) {
    const now = new Date();
    const diff = now - new Date(date);
    const minutes = Math.floor(diff / 60000);
    
    if (minutes < 1) return 'just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (minutes < 1440) return `${Math.floor(minutes / 60)}h ago`;
    return `${Math.floor(minutes / 1440)}d ago`;
  }

  async exit() {
    await this.saveContexts();
    console.log('\n👋 Goodbye! Contexts saved automatically.');
    this.rl.close();
    process.exit(0);
  }

  start() {
    this.rl.on('line', async (input) => {
      if (input.trim()) {
        await this.processCommand(input);
      }
      this.rl.prompt();
    });

    this.rl.on('SIGINT', () => {
      console.log('\n(Use "exit" to quit)');
      this.rl.prompt();
    });

    this.init();
  }
}

// Start the shell
const shell = new AIShell();
shell.start();