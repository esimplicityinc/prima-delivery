/**
 * Skill Conversion Script
 * Validates and copies Claude Code skills to OpenCode format
 * (Skills use nearly identical format, so mostly validation + copy)
 */

import { Glob } from 'bun';
import { parse as parseYaml } from 'yaml';
import { readFile, cp, mkdir, access } from 'fs/promises';
import { join, dirname, basename } from 'path';

// Types
interface SkillFrontmatter {
  name: string;
  description: string;
  version?: string;
  license?: string;
  compatibility?: string;
  metadata?: Record<string, string>;
}

interface ValidationResult {
  valid: boolean;
  name: string;
  source: string;
  dest?: string;
  errors: string[];
  warnings: string[];
}

// Validation functions
function validateSkillName(name: string): { valid: boolean; error?: string } {
  // OpenCode skill name rules:
  // - 1-64 characters
  // - Lowercase alphanumeric with single hyphen separators
  // - Not start or end with hyphen
  // - No consecutive hyphens

  if (!name) {
    return { valid: false, error: 'Name is required' };
  }

  if (name.length < 1 || name.length > 64) {
    return { valid: false, error: `Name must be 1-64 characters (got ${name.length})` };
  }

  const pattern = /^[a-z0-9]+(-[a-z0-9]+)*$/;
  if (!pattern.test(name)) {
    return {
      valid: false,
      error: 'Name must be lowercase alphanumeric with single hyphen separators',
    };
  }

  return { valid: true };
}

function validateDescription(description: string): { valid: boolean; error?: string } {
  if (!description) {
    return { valid: false, error: 'Description is required' };
  }

  if (description.length < 1 || description.length > 1024) {
    return {
      valid: false,
      error: `Description must be 1-1024 characters (got ${description.length})`,
    };
  }

  return { valid: true };
}

// Parse markdown file with frontmatter
function parseMarkdownWithFrontmatter(content: string): { frontmatter: Record<string, any>; body: string } | null {
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

// Validate and copy a single skill
async function validateAndCopySkill(sourcePath: string, destBase: string): Promise<ValidationResult> {
  const skillDir = dirname(sourcePath);
  const skillDirName = basename(skillDir);

  const result: ValidationResult = {
    valid: true,
    name: skillDirName,
    source: sourcePath,
    errors: [],
    warnings: [],
  };

  try {
    // Read and parse SKILL.md
    const content = await readFile(sourcePath, 'utf-8');
    const parsed = parseMarkdownWithFrontmatter(content);

    if (!parsed) {
      result.valid = false;
      result.errors.push('Invalid frontmatter format');
      return result;
    }

    const frontmatter = parsed.frontmatter as SkillFrontmatter;

    // Validate name
    if (!frontmatter.name) {
      result.valid = false;
      result.errors.push('Missing required field: name');
    } else {
      const nameValidation = validateSkillName(frontmatter.name);
      if (!nameValidation.valid) {
        result.valid = false;
        result.errors.push(`Invalid name: ${nameValidation.error}`);
      }

      // Check if directory name matches skill name
      if (frontmatter.name !== skillDirName) {
        result.warnings.push(
          `Directory name (${skillDirName}) doesn't match skill name (${frontmatter.name})`
        );
      }

      result.name = frontmatter.name;
    }

    // Validate description
    if (!frontmatter.description) {
      result.valid = false;
      result.errors.push('Missing required field: description');
    } else {
      const descValidation = validateDescription(frontmatter.description);
      if (!descValidation.valid) {
        result.valid = false;
        result.errors.push(`Invalid description: ${descValidation.error}`);
      }

      // Check for "Use when" trigger (warning only)
      if (!frontmatter.description.toLowerCase().includes('use')) {
        result.warnings.push('Description should include activation trigger (e.g., "Use when...")');
      }
    }

    // If validation passed, copy the skill directory
    if (result.valid) {
      const destDir = join(destBase, frontmatter.name || skillDirName);
      await mkdir(destDir, { recursive: true });
      await cp(skillDir, destDir, { recursive: true });
      result.dest = destDir;
    }

    return result;
  } catch (e) {
    result.valid = false;
    result.errors.push(e instanceof Error ? e.message : String(e));
    return result;
  }
}

// Main function
async function main() {
  const sourcePattern = 'plugins/*/skills/*/SKILL.md';
  const destBase = '.opencode/skills';
  const validateOnly = process.argv.includes('--validate');

  console.log('=== Skill Conversion Script ===\n');
  if (validateOnly) {
    console.log('Mode: Validation only (no files will be copied)\n');
  }

  // Ensure destination directory exists
  if (!validateOnly) {
    await mkdir(destBase, { recursive: true });
  }

  // Find all skill files
  const glob = new Glob(sourcePattern);
  const files: string[] = [];

  for await (const file of glob.scan('.')) {
    files.push(file);
  }

  console.log(`Found ${files.length} skill files to process\n`);

  // Process each skill
  const results: ValidationResult[] = [];
  const seenNames = new Set<string>();

  for (const file of files) {
    const result = validateOnly
      ? await validateSkill(file)
      : await validateAndCopySkill(file, destBase);

    // Check for duplicate names
    if (seenNames.has(result.name)) {
      result.warnings.push(`Duplicate skill name: ${result.name}`);
    }
    seenNames.add(result.name);

    results.push(result);

    // Output status
    const statusIcon = result.valid ? '✓' : '✗';
    const warningIcon = result.warnings.length > 0 ? ' ⚠' : '';
    console.log(`${statusIcon}${warningIcon} ${result.name}`);

    if (result.errors.length > 0) {
      for (const error of result.errors) {
        console.log(`    Error: ${error}`);
      }
    }

    if (result.warnings.length > 0) {
      for (const warning of result.warnings) {
        console.log(`    Warning: ${warning}`);
      }
    }
  }

  // Summary
  const valid = results.filter(r => r.valid).length;
  const invalid = results.filter(r => !r.valid).length;
  const withWarnings = results.filter(r => r.warnings.length > 0).length;

  console.log(`\n=== Summary ===`);
  console.log(`Total: ${results.length}`);
  console.log(`Valid: ${valid}`);
  console.log(`Invalid: ${invalid}`);
  console.log(`With warnings: ${withWarnings}`);

  return results;
}

// Validation-only function (doesn't copy files)
async function validateSkill(sourcePath: string): Promise<ValidationResult> {
  const skillDir = dirname(sourcePath);
  const skillDirName = basename(skillDir);

  const result: ValidationResult = {
    valid: true,
    name: skillDirName,
    source: sourcePath,
    errors: [],
    warnings: [],
  };

  try {
    const content = await readFile(sourcePath, 'utf-8');
    const parsed = parseMarkdownWithFrontmatter(content);

    if (!parsed) {
      result.valid = false;
      result.errors.push('Invalid frontmatter format');
      return result;
    }

    const frontmatter = parsed.frontmatter as SkillFrontmatter;

    // Same validation as validateAndCopySkill but without copying
    if (!frontmatter.name) {
      result.valid = false;
      result.errors.push('Missing required field: name');
    } else {
      const nameValidation = validateSkillName(frontmatter.name);
      if (!nameValidation.valid) {
        result.valid = false;
        result.errors.push(`Invalid name: ${nameValidation.error}`);
      }
      if (frontmatter.name !== skillDirName) {
        result.warnings.push(
          `Directory name (${skillDirName}) doesn't match skill name (${frontmatter.name})`
        );
      }
      result.name = frontmatter.name;
    }

    if (!frontmatter.description) {
      result.valid = false;
      result.errors.push('Missing required field: description');
    } else {
      const descValidation = validateDescription(frontmatter.description);
      if (!descValidation.valid) {
        result.valid = false;
        result.errors.push(`Invalid description: ${descValidation.error}`);
      }
      if (!frontmatter.description.toLowerCase().includes('use')) {
        result.warnings.push('Description should include activation trigger');
      }
    }

    return result;
  } catch (e) {
    result.valid = false;
    result.errors.push(e instanceof Error ? e.message : String(e));
    return result;
  }
}

// Run if executed directly
main().catch(console.error);

export { validateAndCopySkill, validateSkill, validateSkillName, validateDescription };
