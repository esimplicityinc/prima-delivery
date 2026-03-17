# ── Prima Delivery ────────────────────────────────────────────────────────────
# Usage: just <recipe>
#   Run `just` with no arguments to list all available recipes.

set dotenv-load
set tempdir := "."

# ── Taxonomy: layer types ───────────────────────────────────────────────────
import ".global/taxonomy/actions/just/layerTypes/iac-terragrunt.just"

export STACK_DIR := env("STACK_DIR", justfile_directory())

# List available recipes
default:
    @just --list --unsorted
