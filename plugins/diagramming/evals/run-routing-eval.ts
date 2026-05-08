#!/usr/bin/env bun
/**
 * Routing fixture validator.
 *
 * This is NOT an LLM-driven eval. It is a static-shape validator that asserts
 * each line of routing-fixtures.jsonl is well-formed and that the expected
 * skill/mode values match the agent's documented routing table.
 *
 * The real LLM-in-the-loop routing eval (does the agent ACTUALLY pick the
 * right skill when given the prompt and the agent description?) requires an
 * orchestrator capable of invoking an AI. For v1.1.0, that is exercised
 * manually at sponsor checkpoint or via /qa. The fixtures live here so the
 * future LLM eval has a stable input set.
 *
 * This validator:
 *   - confirms the JSONL parses, every line has { prompt, expected_skill, expected_mode }
 *   - confirms expected_skill is one of the documented options
 *   - confirms expected_mode is one of the documented options
 *   - confirms the agent file references both skills (so the AI's prompt is
 *     actually pointing at them)
 *
 * Usage:
 *   bun run plugins/diagramming/evals/run-routing-eval.ts
 */

import { readFile } from "node:fs/promises";
import { join } from "node:path";

const VALID_SKILLS = new Set([
  "architecture-diagrams",
  "flow-diagrams",
  "both",
]);
const VALID_MODES = new Set(["plain", "powerpoint"]);

interface Fixture {
  prompt: string;
  expected_skill: string;
  expected_mode: string;
}

const ROOT = join(import.meta.dir, "..");
const FIXTURES_PATH = join(import.meta.dir, "routing-fixtures.jsonl");
const AGENT_PATH = join(ROOT, "agents", "diagramming-engineer.md");

async function main() {
  const failures: string[] = [];

  const raw = await readFile(FIXTURES_PATH, "utf8");
  const lines = raw
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l.length > 0);

  if (lines.length < 10) {
    failures.push(`expected >= 10 fixtures, got ${lines.length}`);
  }

  const fixtures: Fixture[] = [];
  for (let i = 0; i < lines.length; i++) {
    try {
      const fx = JSON.parse(lines[i]) as Fixture;
      if (typeof fx.prompt !== "string" || fx.prompt.length < 10) {
        failures.push(`line ${i + 1}: prompt missing or too short`);
      }
      if (!VALID_SKILLS.has(fx.expected_skill)) {
        failures.push(
          `line ${i + 1}: expected_skill="${fx.expected_skill}" not in ${[...VALID_SKILLS].join("|")}`,
        );
      }
      if (!VALID_MODES.has(fx.expected_mode)) {
        failures.push(
          `line ${i + 1}: expected_mode="${fx.expected_mode}" not in ${[...VALID_MODES].join("|")}`,
        );
      }
      fixtures.push(fx);
    } catch (err) {
      failures.push(`line ${i + 1}: not valid JSON: ${(err as Error).message}`);
    }
  }

  // Coverage checks: the fixture set should exercise both skills and both modes.
  const skillsHit = new Set(fixtures.map((f) => f.expected_skill));
  if (!skillsHit.has("architecture-diagrams")) {
    failures.push("fixture set never exercises architecture-diagrams");
  }
  if (!skillsHit.has("flow-diagrams")) {
    failures.push("fixture set never exercises flow-diagrams");
  }
  const modesHit = new Set(fixtures.map((f) => f.expected_mode));
  if (!modesHit.has("plain")) failures.push("fixture set never exercises plain mode");
  if (!modesHit.has("powerpoint")) failures.push("fixture set never exercises powerpoint mode");

  // Agent file should reference both skills by name. If it does not, the agent
  // does not know it has these skills available, and routing will fail at runtime.
  const agent = await readFile(AGENT_PATH, "utf8");
  if (!agent.includes("architecture-diagrams")) {
    failures.push("agent file does not reference architecture-diagrams");
  }
  if (!agent.includes("flow-diagrams")) {
    failures.push("agent file does not reference flow-diagrams");
  }

  if (failures.length === 0) {
    console.log(`[PASS] routing fixtures: ${fixtures.length} valid entries`);
    process.exit(0);
  }
  console.log(`[FAIL] routing fixtures: ${failures.length} issue(s)`);
  for (const f of failures) console.log(`    ${f}`);
  process.exit(1);
}

await main();
