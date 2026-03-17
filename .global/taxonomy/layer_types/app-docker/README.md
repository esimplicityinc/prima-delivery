# {{ system_name }}/{{ stack_name }}/{{ layer_name }} layer

Layer type: app-docker

This scaffold creates a Docker-based application structure:

- `layer.yaml` - taxonomy node descriptor.
- `Dockerfile` - multi-stage Docker build.
- `docker-compose.yaml` - local development orchestration.
- `.dockerignore` - files excluded from Docker context.
- `<environment>/` - environment-specific configuration.

Copy `env-template/` for each environment and adjust the configuration files.

## Local Development

```bash
# Build the image
docker compose build

# Run locally
docker compose up

# Run with environment overrides
docker compose --env-file ./dev/.env up
```

## Building for Production

```bash
# Build with specific tag
docker build -t {{ layer_name }}:latest .

# Build for specific environment
docker build --build-arg ENVIRONMENT=prod -t {{ layer_name }}:prod .
```

<!-- BEGIN AUTO-LAYER -->
<!-- This section is managed by scripts. Manual edits inside may be overwritten. -->
<!-- END AUTO-LAYER -->
