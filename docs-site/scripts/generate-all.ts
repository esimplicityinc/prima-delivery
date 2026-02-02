/**
 * Generate All Documentation
 * 
 * Main script that orchestrates doc generation
 */

import { execSync } from 'child_process';
import * as path from 'path';

const scriptsDir = __dirname;

console.log('=== Prima Delivery Documentation Generator ===\n');

// Run agent generation
console.log('Generating agent documentation...');
execSync(`npx ts-node ${path.join(scriptsDir, 'generate-agent-docs.ts')}`, {
  stdio: 'inherit',
  cwd: path.resolve(scriptsDir, '..'),
});

console.log('\n');

// Run skill generation
console.log('Generating skill documentation...');
execSync(`npx ts-node ${path.join(scriptsDir, 'generate-skill-docs.ts')}`, {
  stdio: 'inherit',
  cwd: path.resolve(scriptsDir, '..'),
});

console.log('\n=== Documentation generation complete ===');
