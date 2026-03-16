import type { UserConfig } from "@commitlint/types";

const config: UserConfig = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    // Enforce lowercase type
    "type-case": [2, "always", "lower-case"],
    // Limit subject line to 100 chars
    "header-max-length": [2, "always", 100],
    // Require a non-empty subject
    "subject-empty": [2, "never"],
    // Require a type
    "type-empty": [2, "never"],
    // Allow these types
    "type-enum": [
      2,
      "always",
      [
        "feat",     // New feature
        "fix",      // Bug fix
        "docs",     // Documentation only
        "style",    // Formatting, no code change
        "refactor", // Code change that neither fixes a bug nor adds a feature
        "perf",     // Performance improvement
        "test",     // Adding or updating tests
        "build",    // Build system or external dependencies
        "ci",       // CI configuration
        "chore",    // Maintenance tasks
        "revert",   // Revert a previous commit
        "improve",  // Improvement to existing feature
      ],
    ],
  },
};

export default config;
