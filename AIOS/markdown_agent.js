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
