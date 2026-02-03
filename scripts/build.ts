/**
 * Main Build Script
 * Orchestrates the conversion of Claude plugins to OpenCode format
 */

import { $ } from 'bun';
import { Glob } from 'bun';
import { readFile, writeFile, mkdir } from 'fs/promises';
import { parse as parseYaml } from 'yaml';
import { join, basename, dirname } from 'path';

interface AgentConfig {
  mode: 'primary' | 'subagent';
  description: string;
  prompt: string;
  model?: string;
  tools?: Record<string, boolean>;
  color?: string;
}

interface OpenCodeConfig {
  $schema: string;
  agent: Record<string, AgentConfig>;
}

async function generateOpenCodeConfig(): Promise<void> {
  console.log('Generating opencode.json configuration...\n');

  const agentDir = '.opencode/agents';
  const glob = new Glob('*.md');
  const agents: Record<string, AgentConfig> = {};

  for await (const file of glob.scan(agentDir)) {
    const filePath = join(agentDir, file);
    const content = await readFile(filePath, 'utf-8');

    // Parse frontmatter
    const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (!match) continue;

    try {
      const frontmatter = parseYaml(match[1]) as Record<string, any>;
      const agentName = basename(file, '.md');

      agents[agentName] = {
        mode: frontmatter.mode || 'subagent',
        description: frontmatter.description || '',
        prompt: `{file:./.opencode/agents/${file}}`,
        ...(frontmatter.model && { model: frontmatter.model }),
        ...(frontmatter.tools && { tools: frontmatter.tools }),
        ...(frontmatter.color && { color: frontmatter.color }),
      };
    } catch (e) {
      console.log(`Warning: Could not parse ${file}`);
    }
  }

  const config: OpenCodeConfig = {
    $schema: 'https://opencode.ai/config.json',
    agent: agents,
  };

  // Write config
  const configPath = 'opencode.json';
  await writeFile(configPath, JSON.stringify(config, null, 2));
  console.log(`Generated ${configPath} with ${Object.keys(agents).length} agents`);
}

async function main() {
  console.log('╔════════════════════════════════════════╗');
  console.log('║   OpenCode Plugin Build Pipeline       ║');
  console.log('╚════════════════════════════════════════╝\n');

  const startTime = Date.now();

  // Step 1: Convert agents
  console.log('┌──────────────────────────────────────────┐');
  console.log('│ Step 1: Converting Agents                │');
  console.log('└──────────────────────────────────────────┘\n');

  try {
    await $`bun run scripts/convert-agents.ts`;
  } catch (e) {
    console.error('Agent conversion failed:', e);
    process.exit(1);
  }

  // Step 2: Convert skills
  console.log('\n┌──────────────────────────────────────────┐');
  console.log('│ Step 2: Converting Skills                │');
  console.log('└──────────────────────────────────────────┘\n');

  try {
    await $`bun run scripts/convert-skills.ts`;
  } catch (e) {
    console.error('Skill conversion failed:', e);
    process.exit(1);
  }

  // Step 3: Generate opencode.json
  console.log('\n┌──────────────────────────────────────────┐');
  console.log('│ Step 3: Generating OpenCode Configuration │');
  console.log('└──────────────────────────────────────────┘\n');

  try {
    await generateOpenCodeConfig();
  } catch (e) {
    console.error('Config generation failed:', e);
    process.exit(1);
  }

  // Step 4: Generate OpenPackage manifests
  console.log('\n┌──────────────────────────────────────────┐');
  console.log('│ Step 4: Generating OpenPackage Manifests │');
  console.log('└──────────────────────────────────────────┘\n');

  try {
    await $`bun run scripts/build-openpackage.ts`;
  } catch (e) {
    console.error('OpenPackage manifest generation failed:', e);
    process.exit(1);
  }

  // Summary
  const endTime = Date.now();
  const duration = ((endTime - startTime) / 1000).toFixed(2);

  console.log('\n╔════════════════════════════════════════╗');
  console.log('║   Build Complete!                       ║');
  console.log('╚════════════════════════════════════════╝');
  console.log(`\nTotal time: ${duration}s`);
  console.log('\nNext steps:');
  console.log('1. Review generated files in .opencode/');
  console.log('2. Test OpenCode: opencode --config ./opencode.json');
  console.log('3. Test OpenPackage: opkg install . --plugins debugging-toolkit');
  console.log('4. For multi-platform: opkg install gh@esimplicityinc/prima-delivery');
}

main().catch((e) => {
  console.error('Build failed:', e);
  process.exit(1);
});
