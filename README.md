# FRP Server

Fast Reverse Proxy server that allows you to expose local servers located behind a NAT or firewall to the Internet.

## Features

- Multi-architecture support (linux/amd64, linux/arm64)
- Security-hardened container (non-root user, read-only filesystem, dropped capabilities)
- Configurable via environment variables
- TLS support
- Web dashboard
- Prometheus metrics

## Quick Start

```bash
docker compose up -d
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTH_TOKEN` | `change-me` | Authentication token for frpc connections |
| `DASHBOARD_USER` | `admin` | Dashboard username |
| `DASHBOARD_PASSWORD` | `1234` | Dashboard password |
| `SUBDOMAIN_HOST` | `frps.com` | Base domain for virtual hosts |
| `LOG_LEVEL` | `info` | Log level (trace, debug, info, warn, error) |
| `SSL_CERT_FILE` | `/ssl/fullchain.pem` | Path to SSL certificate |
| `SSL_KEY_FILE` | `/ssl/privkey.pem` | Path to SSL private key |
| `SSL_TRUST_FILE` | - | Optional: Path to trusted CA file |

## Usage

### Basic Usage

Create a `.env` file:

```bash
AUTH_TOKEN=your-secure-token-here
DASHBOARD_USER=admin
DASHBOARD_PASSWORD=your-secure-password
SUBDOMAIN_HOST=yourdomain.com
LOG_LEVEL=info
```

Then start:

```bash
docker compose up -d
```

### Accessing Dashboard

After starting, access the dashboard at `http://your-server:7500`

### Using as Submodule

To include this frpserver in another project:

1. Add as submodule:
```bash
git submodule add https://github.com/hieupth/frpserver.git submodules/frpserver
```

2. In your project's `compose.yml`:
```yaml
include:
  - path: ./submodules/frpserver/compose.yml

services:
  frps:
    ports:
      - "7000:7000"    # Required: FRP server
      - "7500:7500"    # Required: Dashboard
    environment:
      - AUTH_TOKEN=${MY_AUTH_TOKEN}
      - DASHBOARD_PASSWORD=${MY_DASHBOARD_PASSWORD}
      - SUBDOMAIN_HOST=example.com
```

**Important**: When using as submodule, you **must define all required ports** in your override. The ports from the base service are not inherited.

### Multiple Instances

To run multiple frps instances with different configurations, use the `x-frps-service` template:

```yaml
include:
  - path: ./submodules/frpserver/compose.yml

services:
  # Instance 1 - Production
  frps-prod:
    <<: *frps-service
    ports:
      - "7000:7000"
      - "7500:7500"
    environment:
      - AUTH_TOKEN=${PROD_AUTH_TOKEN}
      - DASHBOARD_PASSWORD=${PROD_DASHBOARD_PASSWORD}
      - SUBDOMAIN_HOST=prod.example.com

  # Instance 2 - Staging
  frps-staging:
    <<: *frps-service
    ports:
      - "7001:7000"
      - "7501:7500"
    environment:
      - AUTH_TOKEN=${STAGING_AUTH_TOKEN}
      - DASHBOARD_PASSWORD=${STAGING_DASHBOARD_PASSWORD}
      - SUBDOMAIN_HOST=staging.example.com
```

Note: Extension fields (`x-`) are preserved during include, making `*frps-service` available for reuse.

## Ports

| Internal Port | Required | Description |
|---------------|----------|-------------|
| **7000** | Yes | FRP server port - for client connections |
| **7500** | Yes | Dashboard web UI |
| **2095** | No | TCP multiplex HTTP connect |
| **8080** | No | HTTP virtual host |
| **8443** | No | HTTPS virtual host |

**Port Mapping Example**:
```yaml
ports:
  - "7000:7000"   # host:container - expose FRP server on host port 7000
  - "7500:7500"   # host:container - expose dashboard on host port 7500
```

## Security

- Container runs as non-root user (UID:GID 999:999)
- Read-only root filesystem
- All capabilities dropped
- No new privileges security option
- TLS enforcement enabled by default

## License

[Apache License 2.0](LICENSE)

Copyright &copy; 2025 [Hieu Pham](https://github.com/hieupth). All rights reserved.
