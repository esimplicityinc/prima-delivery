# {{ system_name }}/{{ stack_name }}/{{ layer_name }} layer

Layer type: k8s-argocd

This scaffold creates an Argo CD Application for GitOps-based Kubernetes deployments.

## Structure

```
{{ layer_name }}/
├── layer.yaml                  # Taxonomy node descriptor
├── base/
│   └── app/
│       ├── kustomization.yaml
│       └── application.yaml    # Argo CD Application manifest
└── <environment>/              # Per-environment overlays
    ├── kustomization.yaml
    └── patch-argocd-application.yaml
```

## Getting Started

1. Copy `environment-template/` for each target environment:
   ```bash
   cp -r environment-template dev
   cp -r environment-template staging
   cp -r environment-template prod
   ```

2. Update the environment-specific values in `patch-argocd-application.yaml`:
   - Target namespace
   - Sync policy
   - Parameter overrides

3. Apply the Application to your Argo CD cluster:
   ```bash
   kubectl apply -k dev/
   ```

## Argo CD Application

The `base/app/application.yaml` defines the Application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ layer_name }}
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo
    targetRevision: HEAD
    path: path/to/{{ layer_name }}/base
  destination:
    server: https://kubernetes.default.svc
    namespace: {{ layer_name }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Environment Overlays

Each environment patches the base Application:

```yaml
# prod/patch-argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ layer_name }}
spec:
  destination:
    namespace: {{ layer_name }}-prod
  source:
    targetRevision: main
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Sync Patterns

### Manual Sync (Development)
```yaml
syncPolicy: {}  # No automated sync
```

### Auto-Sync (Production)
```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

### Sync Windows
```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
    - PruneLast=true
```

## Common Commands

```bash
# Check Application status
argocd app get {{ layer_name }}

# Manual sync
argocd app sync {{ layer_name }}

# View diff
argocd app diff {{ layer_name }}

# Rollback
argocd app rollback {{ layer_name }}
```

## CI/CD Integration

Argo CD automatically syncs when changes are pushed to the configured Git branch. For additional control:

```yaml
# Trigger sync after deployment
- name: Sync Argo CD
  run: argocd app sync {{ layer_name }} --prune
```

<!-- BEGIN AUTO-LAYER -->
<!-- This section is managed by scripts. Manual edits inside may be overwritten. -->
<!-- END AUTO-LAYER -->
