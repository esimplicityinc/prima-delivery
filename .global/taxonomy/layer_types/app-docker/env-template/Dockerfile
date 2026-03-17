# Runtime overlay for {{ environment_name | default("dev") }}
ARG BASE_IMAGE
FROM ${BASE_IMAGE:-{{ layer_name }}:base}

ENV NODE_ENV={{ environment_name | default("dev") }}

# Environment-specific configuration can be added here.
# For example, copy environment-specific config files:
# COPY ./config/ /app/config/
