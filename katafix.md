# Katalyst Taxonomy CLI — Findings and Workarounds

**Project:** prima-delivery (PRIMA-151)
**CLI Versions Tested:** v0.1.0 (initial), v0.14.0 (re-validation)
**Date:** 2026-03-16
**Author:** Aaron West

---

## Summary

This document records findings encountered while using the Katalyst Taxonomy CLI (`kata`) to scaffold infrastructure for deploying the Prima Delivery documentation site. Each finding describes what was done, what was expected, what actually happened, and what workaround was applied.

The taxonomy structure created:
```
prima [system]
└── delivery [subsystem]
    └── docs-site [stack]
        └── iac [layer] (iac-terragrunt)

prima-agents [library]
```

---

## Finding 1: `kata tax init` Does Not Scaffold `.global/iac/`

**What was done:**
Ran `kata tax init --layer-type iac-terragrunt --yes` to initialize the taxonomy.

**What was expected:**
Since `--layer-type iac-terragrunt` was specified, the init command should scaffold the `.global/iac/` directory with at minimum a `context.hcl` template and environment config files (`dev.yaml`, `prod.yaml`), as these are essential for Terragrunt to function.

**What actually happened:**
Init created `.global/taxonomy/` (with `environments.yaml`, `taxonomy.lock`, `templates/`) but did NOT create `.global/iac/` at all. No `context.hcl`, no environment YAML files.

**What had to be done instead:**
Manually created `.global/iac/context.hcl`, `.global/iac/dev.yaml`, and `.global/iac/prod.yaml` by hand.

**v0.1.0 vs v0.14.0:** Same behavior in both versions.

---

## Finding 2: `kata tax init` Now Creates `system.yaml` (v0.14.0 Improvement)

**What was done:**
Ran `kata tax init --layer-type iac-terragrunt --yes`.

**What was expected:**
In v0.1.0, `system.yaml` was NOT created by init and had to be manually created.

**What actually happened:**
In v0.14.0, `system.yaml` IS created automatically during init. It populates with the system name derived from the directory name, a default owner, and `dev` as the only environment.

**What had to be done instead:**
Minor edit to add `prod` to the environments list (since init only adds `dev`). This is a significant improvement over v0.1.0 where the entire file had to be created from scratch.

**v0.1.0 vs v0.14.0:** Fixed in v0.14.0 — system.yaml is now auto-generated.

---

## Finding 3: `kata tax init` Does Not Create `version.yaml`

**What was done:**
Ran `kata tax init --layer-type iac-terragrunt --yes`.

**What was expected:**
A `version.yaml` file at the root, since the generated `context.hcl` template (from the iac-terragrunt layer type) references `find_in_parent_folders("version.yaml")`.

**What actually happened:**
No `version.yaml` was created. The `context.hcl` that references it is also not created by init (see Finding 1), but the intended pattern clearly depends on this file existing.

**What had to be done instead:**
Manually created `version.yaml` with content `version: 1.3.7`.

**v0.1.0 vs v0.14.0:** Same behavior in both versions.

---

## Finding 4: `kata tax create` Places Nodes in Namespaced Subdirectories

**What was done:**
Ran `kata tax create subsystem delivery --parent prima` to create the delivery subsystem.

**What was expected:**
Since the repo root IS the delivery subsystem (common monorepo pattern), `sub_system.yaml` should be created at the repo root.

**What actually happened:**
The CLI created `delivery/sub_system.yaml` inside a new `delivery/` subdirectory, following a strict `<parent>/<node>/` directory convention. Similarly, `kata tax create stack docs-site --parent delivery` created `delivery/docs-site/stack.yaml` rather than recognizing that `docs-site/` already exists.

**What had to be done instead:**
After each `create` command, manually moved the YAML files to the correct locations:
- `delivery/sub_system.yaml` → `./sub_system.yaml` (repo root)
- `delivery/docs-site/stack.yaml` → `docs-site/stack.yaml` (existing directory)
- `delivery/docs-site/iac/layer.yaml` → `docs-site/iac/layer.yaml`
- Removed empty `delivery/` directories after each move.

**v0.1.0 vs v0.14.0:** Same behavior in both versions. The CLI assumes a strict hierarchical directory layout and cannot accommodate existing directory structures or monorepos where the repo root is a subsystem.

---

## Finding 5: `kata tax create` Only Captures First `--env` Flag

**What was done:**
Ran `kata tax create subsystem delivery --parent prima --env dev --env prod`.

**What was expected:**
Both `dev` and `prod` should appear in the `environments` list of the generated YAML.

**What actually happened:**
Only `dev` appeared in the `environments` list. The second `--env prod` was silently ignored.

**What had to be done instead:**
Manually edited each generated YAML file to add `"prod"` to the environments array.

**v0.1.0 vs v0.14.0:** Same behavior in both versions. The `--env` flag's argparse configuration may use `action='store'` instead of `action='append'`, or the handler only reads the first value.

---

## Finding 6: `kata tax create layer` Does Not Scaffold Terraform Files

**What was done:**
Ran `kata tax create layer iac --parent docs-site --layer-type iac-terragrunt`.

**What was expected:**
Since `--layer-type iac-terragrunt` was specified, the layer creation should scaffold at minimum:
- A `base/terraform/` directory with skeleton `.tf` files (main.tf, variables.tf, outputs.tf)
- Environment directories (`dev/`, `prod/`) with `terragrunt.hcl` and `environment.yaml`

**What actually happened:**
Only `layer.yaml` was created with the `layerType: iac-terragrunt` annotation. No Terraform files, no environment directories, no Terragrunt configs.

**What had to be done instead:**
Manually created the entire directory structure and all files:
- `docs-site/iac/base/terraform/main.tf` (256 lines of S3, CloudFront, ACM, Route53, OIDC)
- `docs-site/iac/base/terraform/variables.tf`
- `docs-site/iac/base/terraform/outputs.tf`
- `docs-site/iac/dev/environment.yaml` and `docs-site/iac/dev/terragrunt.hcl`
- `docs-site/iac/prod/environment.yaml` and `docs-site/iac/prod/terragrunt.hcl`

**v0.1.0 vs v0.14.0:** Same behavior in both versions.

---

## Finding 7: `kata tax create layer` Now Warns About Missing Environment Config (v0.14.0 Improvement)

**What was done:**
Ran `kata tax create layer iac --parent docs-site --layer-type iac-terragrunt --env dev --env prod`.

**What was expected:**
Some guidance on what's needed for the iac-terragrunt layer type.

**What actually happened:**
In v0.14.0, the CLI now outputs a helpful warning:
```
Warning: iac-terragrunt requires environment configuration that is not yet set in environments.yaml.
  Missing keys:
    [dev] iac-terragrunt.remote_state_bucket
    [dev] iac-terragrunt.remote_state_region
    [prod] iac-terragrunt.remote_state_bucket
    [prod] iac-terragrunt.remote_state_region
```

This was NOT present in v0.1.0.

**What had to be done instead:**
The warning is informational only — it still doesn't create the files, but at least it tells you what's missing. We still had to manually create everything.

**v0.1.0 vs v0.14.0:** Improved in v0.14.0 — the CLI now provides actionable guidance about missing configuration.

---

## Finding 8: `kata tax create library` Only Creates Metadata YAML

**What was done:**
Ran `kata tax create library prima-agents --parent-system prima`.

**What was expected:**
A `library.yaml` plus optionally a README or template scaffold for the library.

**What actually happened:**
Only `library.yaml` was created with minimal metadata. Created at `prima-agents/library.yaml` (top-level directory) rather than any nested path.

**What had to be done instead:**
Moved `prima-agents/library.yaml` to `prima/prima-agents/library.yaml` to match the intended directory structure. No additional files needed for this project, but a README or purpose doc would be helpful for discoverability.

**v0.1.0 vs v0.14.0:** Same behavior in both versions.

---

## Finding 9: `environments.yaml` Defaults Include Staging

**What was done:**
Ran `kata tax init --layer-type iac-terragrunt --yes`.

**What was expected:**
The generated `environments.yaml` should contain only the environments referenced by the project, or should be minimal for customization.

**What actually happened:**
The generated `environments.yaml` includes three environments: `dev`, `staging`, and `prod`. While this is a sensible default, it required manual editing to remove `staging` since our project only uses `dev` and `prod`.

**What had to be done instead:**
Edited `.global/taxonomy/environments.yaml` to remove the `staging` environment block.

**v0.1.0 vs v0.14.0:** Same behavior in both versions. This is a minor issue — the defaults are reasonable.

---

## Finding 10: Justfile References Non-Existent Actions Path

**What was done:**
`kata tax init` generated a `Justfile` at the repo root.

**What was expected:**
The import path in the Justfile should point to an existing file, or the file should be generated alongside the Justfile.

**What actually happened:**
The Justfile contains:
```
import ".global/taxonomy/actions/just/stack.just"
```
But `.global/taxonomy/actions/` directory does not exist. The init only creates `.global/taxonomy/templates/` and `.global/taxonomy/environments.yaml`.

**What had to be done instead:**
The Justfile is currently non-functional. For this project, we are not using the Just-based task runner, so this is a low-impact finding. The file was committed as-is for documentation purposes.

**v0.1.0 vs v0.14.0:** Same behavior in both versions.

---

## Finding 11: No Static Site Layer Type

**What was done:**
Searched for a layer type specific to static site hosting (S3 + CloudFront pattern).

**What was expected:**
A layer type like `static-site-aws` or `cloudfront-s3` that would scaffold the common pattern of S3 bucket + CloudFront distribution + ACM certificate + Route53 records.

**What actually happened:**
No such layer type exists. Available layer types are generic (e.g., `iac-terragrunt`, `app-docker`, `aws-lambda`). The `iac-terragrunt` type was used as the closest match.

**What had to be done instead:**
Used `iac-terragrunt` as the layer type and wrote all Terraform resources from scratch (S3, CloudFront OAC, ACM, Route53, GitHub OIDC). This is approximately 250 lines of Terraform that could be a reusable archetype or layer type.

**v0.1.0 vs v0.14.0:** Same behavior in both versions.

---

## Finding 12: CI/CD Templates Are Minimal Placeholders

**What was done:**
Examined the CI/CD templates generated by init in `.global/taxonomy/cicd/`.

**What was expected:**
Templates for GitHub Actions workflows that include AWS OIDC credential configuration, S3 sync deployment, and CloudFront invalidation — common patterns for AWS-hosted static sites.

**What actually happened:**
Init does NOT generate `.global/taxonomy/cicd/` directory at all. The CI/CD template generation appears to be available through `kata tax cicd` command but is a separate step.

**What had to be done instead:**
Wrote complete GitHub Actions workflows from scratch:
- `deploy-docs-dev.yml`: Triggered on push to main, builds and deploys to dev.alvisprima.com
- `deploy-docs-prod.yml`: Triggered on release publish, builds and deploys to alvisprima.com

Each workflow includes Node.js setup, npm build, AWS OIDC credential configuration, S3 sync with cache control, and CloudFront invalidation.

**v0.1.0 vs v0.14.0:** Same behavior in both versions.

---

## Finding 13: `kata tax lint` Reports Error Without Detail

**What was done:**
Ran `kata tax lint` to validate the taxonomy structure.

**What was expected:**
Either a clean pass, or detailed error messages identifying which file/rule failed and how to fix it.

**What actually happened:**
Output: `Found 1 error(s) in taxonomy.` — with no indication of which file, which rule, or what the error is. The only other output was a warning about `plugins/conductor/openpackage.yml` (a YAML parse warning for a non-taxonomy file).

No `--verbose` or `-v` flag is available to get more detail.

**What had to be done instead:**
Could not determine the root cause of the lint error. Suspected it's the `openpackage.yml` parse warning being counted as an error. Tree and deps commands both succeed, and all node files follow the correct schema format. This finding makes `kata tax lint` unreliable for CI/CD gating without detailed error output.

**v0.1.0 vs v0.14.0:** Could not compare — lint was not tested in the v0.1.0 run.

---

## Finding 14: Plugins Not Installed by Default — `kata tax add` Required

**What was done:**
Ran `kata tax init --layer-type iac-terragrunt --yes`. Later compared the resulting `.global/taxonomy/` structure against a working reference project (prima-common2).

**What was expected:**
The init with `--layer-type iac-terragrunt` should install all necessary components, including:
- Layer type templates (`.global/taxonomy/layer_types/`)
- CI/CD pipeline templates (`.global/taxonomy/cicd/`)
- Just action recipes (`.global/taxonomy/actions/`)
- Layer action definitions

The reference project had ~100+ files in `.global/taxonomy/` while our init only produced ~12 files.

**What actually happened:**
The `taxonomy.lock` created by init only had `core:` installed — no plugins. The working reference had `layer_types`, `cicd`, `just`, and `layer_actions` plugins all installed. The Justfile generated by init imported `.global/taxonomy/actions/just/stack.just` which didn't exist because the `just` plugin wasn't installed.

**What had to be done instead:**
After init, ran `kata tax add --plugin cicd --plugin just --plugin layer_actions --plugin layer_types --yes` to install all bundled plugins. This populated the missing directories and files, bringing our taxonomy structure in line with the reference:
- `.global/taxonomy/layer_types/iac-terragrunt/` — includes `composite/terraform/` skeleton, `env-template/`, `global/iac/context.hcl` reference template
- `.global/taxonomy/cicd/` — workflow templates, job definitions, Jinja2 templates
- `.global/taxonomy/actions/` — Just recipes for all layer types, tools, and orchestration

**Impact:** Without plugins, the Justfile is broken, there are no CI/CD rendering capabilities (`kata tax cicd render`), and the iac-terragrunt layer type reference templates are unavailable. The `--layer-type` flag on init implies these should be included.

**v0.1.0 vs v0.14.0:** Same behavior in both versions. The `kata tax add` command and `--plugin` flags are available in v0.14.0.

---

## Finding 15: Bundled iac-terragrunt Template Uses `composite/terraform/` Convention

**What was done:**
After installing plugins, examined the bundled iac-terragrunt layer type template at `.global/taxonomy/layer_types/iac-terragrunt/`.

**What was expected:**
Documentation or convention for Terraform module directory naming.

**What actually happened:**
The bundled template uses `composite/terraform/` as the Terraform module directory, with the env-template `terragrunt.hcl` referencing `find_in_parent_folders("./composite/terraform")`. Our initial implementation (from v0.1.0 branch) used `base/terraform/` based on general Terragrunt patterns.

**What had to be done instead:**
Renamed `docs-site/iac/base/` to `docs-site/iac/composite/` and updated all `terragrunt.hcl` files to reference `./composite/terraform` to align with the Katalyst convention.

**v0.1.0 vs v0.14.0:** Same bundled template in both versions (discovered only after installing plugins in v0.14.0).

---

## Finding 16: Bundled AWS Provider Constraint Is `~> 6.0`

**What was done:**
Examined the bundled `context.hcl` template at `.global/taxonomy/layer_types/iac-terragrunt/global/iac/context.hcl`, which generates `versions.tf` via a `generate` block.

**What was expected:**
The bundled provider constraint would use the widely-adopted AWS provider v5.x (`~> 5.0`), which is what most production environments currently run.

**What actually happened:**
The generated `versions.tf` specifies `hashicorp/aws ~> 6.0`. AWS provider v6 was released in late 2025 and includes breaking changes from v5 (removed deprecated resources, changed argument names, stricter validation). Projects using v5-era Terraform code may hit compatibility issues if they adopt the bundled template without review.

**What had to be done instead:**
We kept `~> 6.0` to align with the bundled template convention and wrote our Terraform against the v6 API. Projects migrating existing infrastructure should be aware that the bundled template assumes v6 and may need to pin `~> 5.0` instead.

**v0.1.0 vs v0.14.0:** Same bundled template in both versions.

---

## Finding 17: Bundled Environment Templates Use Unprocessed Jinja2 Placeholders

**What was done:**
Examined the bundled env-template files at `.global/taxonomy/layer_types/iac-terragrunt/env-template/`, specifically `terragrunt.hcl` and `environment.yaml`.

**What was expected:**
Either ready-to-use files, or files processed by a `kata tax` command (e.g., `kata tax create layer --env dev` would render the templates for each environment).

**What actually happened:**
The env-template files contain Jinja2-style placeholders like `{{ environment }}` and `{{ remote_state_bucket }}`. These are NOT processed by any `kata tax` command — they are reference patterns only. The `kata tax create layer` command does not copy or render these templates into the layer's environment directories.

The bundled `env-template/terragrunt.hcl` also references a dynamic state bucket pattern `${local.account_id}-${local.system_name}-tf-state` which implies a naming convention but is not documented anywhere.

**What had to be done instead:**
Manually created `docs-site/iac/dev/terragrunt.hcl`, `docs-site/iac/dev/environment.yaml`, and equivalent prod files by hand, using the env-template as a visual reference rather than a functional template. The state bucket was hardcoded to the actual bucket name (`591639515130-prima-cicd-bootstrap-dev-tf-state`) rather than relying on the dynamic convention.

**v0.1.0 vs v0.14.0:** Same behavior in both versions. The env-template directory exists as a documentation-by-example pattern, not a functional scaffold.

---

## Finding 18: Bundled context.hcl Includes K8s/EKS-Specific Fields

**What was done:**
Examined the bundled `context.hcl` template at `.global/taxonomy/layer_types/iac-terragrunt/global/iac/context.hcl`.

**What was expected:**
A generic infrastructure context template that works for any AWS deployment pattern.

**What actually happened:**
The bundled template includes `admin_role`, `assume_role`, and `permissions_boundary` locals — all sourced from the environment YAML. The generated `context.yaml` constructs full IAM role ARNs. The corresponding environment templates (`global/iac/dev.yaml`, `global/iac/prod.yaml`) have placeholder values for `assume_role`, `admin_role`, and `permissions_boundary`.

These fields are oriented toward K8s/EKS deployments (cluster-admin roles, CICD bootstrap roles) and are unnecessary for a static site deployment. However, removing them would break alignment with the bundled template pattern.

**What had to be done instead:**
Kept the K8s-oriented fields in our `context.hcl` and environment YAML files for convention alignment. Added our custom fields (`domain_name`, `hosted_zone_id`) alongside the standard ones. The Terraform `variables.tf` context object type was updated to accept all fields.

**v0.1.0 vs v0.14.0:** Same bundled template in both versions.

---

## Summary of Changes: v0.1.0 vs v0.14.0

| Finding | v0.1.0 | v0.14.0 | Verdict |
|---------|--------|---------|---------|
| 1. Init doesn't scaffold `.global/iac/` | Same | Same | No change |
| 2. Init doesn't create `system.yaml` | Missing | **Now created** | **Fixed** |
| 3. Init doesn't create `version.yaml` | Same | Same | No change |
| 4. Create places nodes in namespaced dirs | Same | Same | No change |
| 5. Create only captures first `--env` | Same | Same | No change |
| 6. Create layer doesn't scaffold TF files | Same | Same | No change |
| 7. Create layer warns about missing config | No warning | **Warning added** | **Improved** |
| 8. Create library minimal output | Same | Same | No change |
| 9. environments.yaml defaults include staging | Same | Same | No change |
| 10. Justfile references non-existent path | Same | Same | No change |
| 11. No static site layer type | Same | Same | No change |
| 12. CI/CD templates are minimal | Same | Same | No change |
| 13. Lint reports error without detail | Not tested | Error without detail | New finding |
| 14. Plugins not installed by default | Same | Same | No change |
| 15. Bundled template uses `composite/` | Not discovered | Discovered | New finding |
| 16. Bundled AWS provider is `~> 6.0` | Not discovered | Discovered | New finding |
| 17. Env templates use unprocessed Jinja2 | Not discovered | Discovered | New finding |
| 18. Bundled context.hcl has K8s fields | Not discovered | Discovered | New finding |

**Key v0.14.0 improvements:**
1. `system.yaml` is now auto-generated during init (Finding 2)
2. Layer creation now warns about missing environment configuration (Finding 7)
3. `kata tax add` command available to install plugins post-init (Finding 14)

**Unchanged gaps requiring manual work:**
- All Terraform files, Terragrunt configs, and environment directories must be created manually
- `.global/iac/` directory structure must be created manually
- Node placement requires manual file moves for non-standard directory layouts
- CI/CD workflows must be written from scratch (bundled Jinja2 templates don't cover static site pattern)
- Plugins must be explicitly installed after init (`kata tax add --plugin ...`)
- Bundled env-template files are reference-only — not processed or copied by any CLI command
- Bundled AWS provider constraint (`~> 6.0`) may surprise teams still on v5.x
