# FRP Server

[Fast Reverse Proxy](https://github.com/fatedier/frp.git) server that allows you to expose local servers located behind a NAT or firewall to the Internet.

## Quick Start

This repo provides a `frps` service definition that can be extended in your project's `compose.yml` using Docker Compose `extends`.

1. Add as submodule:
```bash
git submodule add https://github.com/hieupth/frpserver.git submodules/frpserver
```

2. Copy and edit config:
```bash
cp submodules/frpserver/config.toml ./config.toml
# Edit config.toml — at minimum, change auth.token from "changeme"
```

3. In your project's `compose.yml`:
```yaml
secrets:
  frps_config:
    file: ./config.toml

services:
  frps:
    extends:
      file: ./submodules/frpserver/compose.yml
      service: frps
    environment:
      - CONFIG_FILE=/run/secrets/frps_config
    secrets:
      - frps_config
    volumes:
      - /path/to/fullchain.pem:/run/secrets/ssl_cert:ro
      - /path/to/privkey.pem:/run/secrets/ssl_key:ro
```

4. Start:
```bash
docker compose up -d
```

> `extends` inherits all settings from the base service. Lists (volumes, environment) are appended; scalar values are overridden.

## Config File

The config file (`config.toml`) uses Go templates with environment variable support. All values have sensible defaults — you only need to change `auth.token`.

The intended workflow:

1. Copy `config.toml` from this submodule to your project
2. Edit values as needed (at minimum, set `auth.token`)
3. Mount the file as a Docker secret for security

You can also override any config value at runtime via environment variables (see below), without modifying the file.

## Environment Variables

All values in `config.toml` can be overridden via environment variables. When set, they take precedence over the file's default values.

| Variable | Default | Description |
|----------|---------|-------------|
| `BIND_ADDR` | `0.0.0.0` | Server bind address |
| `BIND_PORT` | `7000` | Server bind port |
| `KCP_BIND_PORT` | `7000` | KCP bind port |
| `TRANSPORT_MAX_POOL_COUNT` | `5` | Max pool count per proxy |
| `TRANSPORT_TLS_FORCE` | `true` | Force TLS connections |
| `TRANSPORT_TLS_CERT_FILE` | `/run/secrets/ssl_cert` | TLS certificate file path |
| `TRANSPORT_TLS_KEY_FILE` | `/run/secrets/ssl_key` | TLS key file path |
| `VHOST_HTTP_PORT` | `8080` | HTTP virtual host port |
| `VHOST_HTTPS_PORT` | `8443` | HTTPS virtual host port |
| `TCPMUX_HTTP_CONNECT_PORT` | `2095` | TCP multiplex HTTP connect port |
| `WEB_SERVER_ADDR` | `0.0.0.0` | Dashboard bind address |
| `WEB_SERVER_PORT` | `7500` | Dashboard port |
| `DASHBOARD_USER` | `admin` | Dashboard username |
| `DASHBOARD_PASSWORD` | `admin` | Dashboard password |
| `ENABLE_PROMETHEUS` | `true` | Enable Prometheus metrics |
| `LOG_TO` | `console` | Log output destination |
| `LOG_LEVEL` | `info` | Log level (trace, debug, info, warn, error) |
| `LOG_MAX_DAYS` | `3` | Log retention in days |
| `LOG_DISABLE_PRINT_COLOR` | `false` | Disable colored log output |
| `DETAILED_ERRORS_TO_CLIENT` | `false` | Send detailed errors to client |
| `MAX_PORTS_PER_CLIENT` | `0` | Max ports per client (0 = unlimited) |
| `SUBDOMAIN_HOST` | `localhost` | Base domain for virtual hosts |
| `UDP_PACKET_SIZE` | `1500` | UDP packet size |
| `NATHOLE_ANALYSIS_DATA_RESERVE_HOURS` | `168` | NAT hole punching data retention hours |

## TLS

TLS is enforced by default. Mount your certificates as volumes:

```yaml
volumes:
  - /path/to/fullchain.pem:/run/secrets/ssl_cert:ro
  - /path/to/privkey.pem:/run/secrets/ssl_key:ro
```

The config expects certificates at `/run/secrets/ssl_cert` and `/run/secrets/ssl_key`.

## Accessing Dashboard

After starting, access the dashboard at `https://your-server:7500`

## Multiple Instances

To run multiple frps instances, use separate config files:

```yaml
secrets:
  frps_config_prod:
    file: ./config-prod.toml
  frps_config_staging:
    file: ./config-staging.toml

services:
  frps-prod:
    extends:
      file: ./submodules/frpserver/compose.yml
      service: frps
    environment:
      - CONFIG_FILE=/run/secrets/frps_config_prod
    secrets:
      - frps_config_prod
    volumes:
      - /ssl/prod/fullchain.pem:/run/secrets/ssl_cert:ro
      - /ssl/prod/privkey.pem:/run/secrets/ssl_key:ro

  frps-staging:
    extends:
      file: ./submodules/frpserver/compose.yml
      service: frps
    environment:
      - CONFIG_FILE=/run/secrets/frps_config_staging
    secrets:
      - frps_config_staging
    volumes:
      - /ssl/staging/fullchain.pem:/run/secrets/ssl_cert:ro
      - /ssl/staging/privkey.pem:/run/secrets/ssl_key:ro
```

Note: When using `network_mode: host`, all ports are exposed directly on the host. For multiple instances, use separate config files with different bind ports.

## Ports

When using `network_mode: host`, these ports are exposed directly on the host:

| Port | Required | Description |
|------|----------|-------------|
| **7000** | Yes | FRP server port (TCP + KCP/UDP) |
| **7500** | Yes | Dashboard web UI (HTTPS) |
| **2095** | No | TCP multiplex HTTP connect |
| **8080** | No | HTTP virtual host |
| **8443** | No | HTTPS virtual host |

## Security

- Container runs as non-root user (UID:GID 999:999)
- Read-only root filesystem with tmpfs for `/tmp`
- All Linux capabilities dropped (`cap_drop: ALL`)
- No new privileges security option
- TLS enforcement enabled by default
- Config file mounted as Docker secret (not volume)
- Authentication token must be changed from default `changeme`

## License

[Apache License 2.0](LICENSE)

Copyright &copy; 2025-2026 [Hieu Pham](https://github.com/hieupth). All rights reserved.
