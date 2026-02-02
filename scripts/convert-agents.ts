/**
 * Agent Conversion Script
 * Converts Claude Code agent format to OpenCode agent format
 */

import { Glob } from 'bun';
import { parse as parseYaml, stringify as stringifyYaml } from 'yaml';
import { readFile, writeFile, mkdir } from 'fs/promises';
import { join, basename, dirname } from 'path';

// Types
interface ClaudeFrontmatter {
  name: string;
  description: string;
  tools?: string;
  model?: string;
  color?: string;
}

interface OpenCodeFrontmatter {
  description: string;
  mode: 'primary' | 'subagent';
  model?: string;
  color?: string;
  tools?: Record<string, boolean>;
}

interface ConversionResult {
  success: boolean;
  name: string;
  source: string;
  dest?: string;
  error?: string;
}

// Mappings
const MODEL_MAP: Record<string, string> = {
  'opus': 'anthropic/claude-opus-4-5',
  'sonnet': 'anthropic/claude-sonnet-4-20250514',
  'haiku': 'anthropic/claude-haiku-4-20250514',
};

const COLOR_MAP: Record<string, string> = {
  'cyan': '#00FFFF',
  'green': '#00FF00',
  'yellow': '#FFFF00',
  'red': '#FF0000',
  'blue': '#0000FF',
  'magenta': '#FF00FF',
  'orange': '#FFA500',
  'purple': '#800080',
  'pink': '#FFC0CB',
  'white': '#FFFFFF',
  'gray': '#808080',
  'grey': '#808080',
};

// Tool parsing
function parseTools(toolInput?: string | string[]): Record<string, boolean> | undefined {
  if (!toolInput) return undefined;

  // Handle array format (e.g., tools: [])
  if (Array.isArray(toolInput)) {
    if (toolInput.length === 0) return undefined;
    // Convert array to comma-separated string
    const toolString = toolInput.join(',');
    return parseTools(toolString);
  }

  // Handle string format
  const toolString = String(toolInput);
  if (!toolString.trim()) return undefined;

  const toolList = toolString
    .split(/[,\s]+/)
    .map(t => t.trim().toLowerCase())
    .filter(t => t.length > 0);

  // Default all tools to false, then enable what's specified
  const tools: Record<string, boolean> = {
    read: false,
    glob: false,
    grep: false,
    bash: false,
    write: false,
    edit: false,
    task: false,
    webfetch: false,
    todowrite: false,
    todoread: false,
  };

  for (const tool of toolList) {
    switch (tool) {
      case 'read':
        tools.read = true;
        break;
      case 'glob':
        tools.glob = true;
        break;
      case 'grep':
        tools.grep = true;
        break;
      case 'bash':
        tools.bash = true;
        break;
      case 'write':
        tools.write = true;
        break;
      case 'edit':
        tools.edit = true;
        break;
      case 'task':
        tools.task = true;
        break;
      case 'webfetch':
      case 'web':
        tools.webfetch = true;
        break;
      case 'todo':
      case 'todowrite':
        tools.todowrite = true;
        tools.todoread = true;
        break;
    }
  }

  // Only return tools object if at least one tool is enabled
  const hasEnabledTools = Object.values(tools).some(v => v);
  return hasEnabledTools ? tools : undefined;
}

// Frontmatter conversion
function convertFrontmatter(claude: ClaudeFrontmatter): OpenCodeFrontmatter {
  const opencode: OpenCodeFrontmatter = {
    description: claude.description,
    mode: 'subagent', // Default to subagent
  };

  // Map model
  if (claude.model) {
    const mappedModel = MODEL_MAP[claude.model.toLowerCase()];
    if (mappedModel) {
      opencode.model = mappedModel;
    } else if (claude.model.includes('/')) {
      // Already in provider/model format
      opencode.model = claude.model;
    }
  }

  // Map color
  if (claude.color) {
    const lowerColor = claude.color.toLowerCase();
    opencode.color = COLOR_MAP[lowerColor] || claude.color;
    // If it's already a hex code, use as-is
    if (claude.color.startsWith('#')) {
      opencode.color = claude.color;
    }
  }

  // Parse tools
  const tools = parseTools(claude.tools);
  if (tools) {
    opencode.tools = tools;
  }

  return opencode;
}

// Parse markdown file with frontmatter
function parseMarkdownWithFrontmatter(content: string): { frontmatter: Record<string, any>; body: string } | null {
  // Check if content is empty or too short
  if (!content || content.trim().length < 10) {
    return null;
  }

  // Check if content starts with frontmatter delimiter
  if (!content.trim().startsWith('---')) {
    return null;
  }

  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
  if (!match) {
    return null;
  }

  try {
    const frontmatter = parseYaml(match[1]) as Record<string, any>;
    const body = match[2];
    return { frontmatter, body };
  } catch (e) {
    return null;
  }
}

// Convert a single agent file
async function convertAgent(sourcePath: string, destDir: string): Promise<ConversionResult> {
  try {
    const content = await readFile(sourcePath, 'utf-8');
    const parsed = parseMarkdownWithFrontmatter(content);

    if (!parsed) {
      return {
        success: false,
        name: basename(sourcePath),
        source: sourcePath,
        error: 'Invalid frontmatter format',
      };
    }

    const claudeFrontmatter = parsed.frontmatter as ClaudeFrontmatter;

    if (!claudeFrontmatter.name || !claudeFrontmatter.description) {
      return {
        success: false,
        name: basename(sourcePath),
        source: sourcePath,
        error: 'Missing required fields (name or description)',
      };
    }

    const opencodeFrontmatter = convertFrontmatter(claudeFrontmatter);

    // Generate output content
    const outputContent = `---\n${stringifyYaml(opencodeFrontmatter)}---\n${parsed.body}`;

    // Use the agent name as filename
    const destFilename = `${claudeFrontmatter.name}.md`;
    const destPath = join(destDir, destFilename);

    await writeFile(destPath, outputContent);

    return {
      success: true,
      name: claudeFrontmatter.name,
      source: sourcePath,
      dest: destPath,
    };
  } catch (e) {
    return {
      success: false,
      name: basename(sourcePath),
      source: sourcePath,
      error: e instanceof Error ? e.message : String(e),
    };
  }
}

// Main conversion function
async function main() {
  const sourcePattern = 'plugins/*/agents/*.md';
  const destDir = '.opencode/agents';

  console.log('=== Agent Conversion Script ===\n');

  // Ensure destination directory exists
  await mkdir(destDir, { recursive: true });

  // Find all agent files
  const glob = new Glob(sourcePattern);
  const files: string[] = [];

  for await (const file of glob.scan('.')) {
    files.push(file);
  }

  console.log(`Found ${files.length} agent files to convert\n`);

  // Convert each agent
  const results: ConversionResult[] = [];
  for (const file of files) {
    const result = await convertAgent(file, destDir);
    results.push(result);

    if (result.success) {
      console.log(`✓ ${result.name}`);
    } else {
      console.log(`✗ ${result.name}: ${result.error}`);
    }
  }

  // Summary
  const successful = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;

  console.log(`\n=== Summary ===`);
  console.log(`Total: ${results.length}`);
  console.log(`Success: ${successful}`);
  console.log(`Failed: ${failed}`);

  if (failed > 0) {
    console.log(`\n=== Failed Conversions ===`);
    for (const result of results.filter(r => !r.success)) {
      console.log(`- ${result.source}: ${result.error}`);
    }
  }

  // Return results for programmatic use
  return results;
}

// Run if executed directly
main().catch(console.error);

export { convertAgent, convertFrontmatter, parseTools, MODEL_MAP, COLOR_MAP };
