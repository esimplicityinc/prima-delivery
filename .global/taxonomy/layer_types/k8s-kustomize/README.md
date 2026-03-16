# {{ system_name }}/{{ stack_name }}/{{ layer_name }} layer

Layer type: k8s-kustomize

This scaffold creates a Kubernetes deployment using Kustomize for environment overlays.

## Structure

```
{{ layer_name }}/
├── layer.yaml              # Taxonomy node descriptor
├── base/                   # Shared manifests
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── <environment>/          # Per-environment overlays
    ├── kustomization.yaml
    └── patch-deployment.yaml
```

## Getting Started

1. Copy `environment-template/` for each target environment:
   ```bash
   cp -r environment-template dev
   cp -r environment-template staging
   cp -r environment-template prod
   ```

2. Update the placeholders in each environment's `patch-deployment.yaml`

3. Apply to your cluster:
   ```bash
   kubectl apply -k dev/
   ```

## Base Resources

The `base/` directory contains shared manifests:

- **namespace.yaml** - Kubernetes namespace for isolation
- **deployment.yaml** - Application deployment spec
- **service.yaml** - Service for internal/external access

## Environment Overlays

Each environment directory patches the base:

```yaml
# dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../base
patches:
  - path: patch-deployment.yaml
```

Common overlay patterns:
- Replica counts (1 for dev, 3 for prod)
- Resource limits
- Environment variables
- Image tags

## Common Commands

```bash
# Preview manifests
kubectl kustomize dev/

# Apply to cluster
kubectl apply -k dev/

# Dry-run
kubectl apply -k dev/ --dry-run=client

# Delete resources
kubectl delete -k dev/
```

## CI/CD Integration

```yaml
# GitHub Actions example
- name: Deploy to dev
  run: kubectl apply -k {{ layer_name }}/dev/
  
- name: Deploy to prod
  run: kubectl apply -k {{ layer_name }}/prod/
```

<!-- BEGIN AUTO-LAYER -->
<!-- This section is managed by scripts. Manual edits inside may be overwritten. -->
<!-- END AUTO-LAYER -->
