# Podman Quadlets for Authentik

This directory contains Podman Quadlet files that replace the Docker Compose configuration.

## What are Quadlets?

Quadlets are systemd unit files that Podman uses to manage containers. They provide better integration with systemd and allow containers to be managed as system services.

## Benefits of Pod Architecture

Using a pod to group the containers provides several advantages:

- **Simplified management**: Start, stop, and restart all services with a single command
- **Shared network namespace**: Containers communicate via `localhost` (faster and simpler)
- **Atomic operations**: All containers start and stop together as a unit
- **Better resource management**: Systemd treats the pod as a single service
- **Easier monitoring**: View logs and status for all containers at once

## Files

- `authentik.pod` - Pod definition that groups all containers together
- `authentik-database.volume` - Persistent volume for PostgreSQL data
- `authentik-postgresql.container` - PostgreSQL database service
- `authentik-server.container` - Authentik server service
- `authentik-worker.container` - Authentik worker service

**Note:** The pod file groups all containers together, allowing them to share the same network namespace and be managed as a single unit.

## Installation

### 1. Install Podman (if not already installed)

```bash
brew install podman
```

### 2. Initialize Podman machine (macOS/Windows only)

```bash
podman machine init
podman machine start
```

### 3. Copy quadlet files to systemd directory

For user services (recommended):

```bash
mkdir -p ~/.config/containers/systemd
cp quadlets/*.{container,pod,volume} ~/.config/containers/systemd/
```

For system services:

```bash
sudo mkdir -p /etc/containers/systemd
sudo cp quadlets/*.{container,pod,volume} /etc/containers/systemd/
```

### 4. Update file paths in quadlets

The quadlet files use `%h` (home directory) for volume paths. If you want to use absolute paths or different locations, edit the `.container` files and replace:

- `%h/git/yarp-proxy-manager/.env` with the absolute path to your `.env` file
- `%h/git/yarp-proxy-manager/data` with the absolute path to your data directory
- `%h/git/yarp-proxy-manager/certs` with the absolute path to your certs directory
- `%h/git/yarp-proxy-manager/custom-templates` with the absolute path to your custom-templates directory

### 5. Reload systemd daemon

```bash
systemctl --user daemon-reload
```

Or for system services:

```bash
sudo systemctl daemon-reload
```

### 6. Start services

Starting the pod automatically starts all containers:

```bash
systemctl --user start authentik.service
```

Or enable it to start on boot:

```bash
systemctl --user enable --now authentik.service
```

**Alternative:** You can still start individual containers if needed:

```bash
systemctl --user start authentik-postgresql.service
systemctl --user start authentik-server.service
systemctl --user start authentik-worker.service
```

## Managing Services

### Check status

Check the entire pod:

```bash
systemctl --user status authentik.service
```

Or check individual containers:

```bash
systemctl --user status authentik-postgresql.service
systemctl --user status authentik-server.service
systemctl --user status authentik-worker.service
```

### View logs

View pod logs:

```bash
journalctl --user -u authentik.service -f
```

Or view individual container logs:

```bash
journalctl --user -u authentik-postgresql.service -f
journalctl --user -u authentik-server.service -f
journalctl --user -u authentik-worker.service -f
```

You can also use Podman directly:

```bash
podman pod logs -f authentik
```

### Stop services

Stop the entire pod:

```bash
systemctl --user stop authentik.service
```

Or stop individual containers:

```bash
systemctl --user stop authentik-postgresql.service
systemctl --user stop authentik-server.service
systemctl --user stop authentik-worker.service
```

### Restart services

Restart the entire pod:

```bash
systemctl --user restart authentik.service
```

Or restart individual containers:

```bash
systemctl --user restart authentik-postgresql.service
systemctl --user restart authentik-server.service
systemctl --user restart authentik-worker.service
```

## Environment Variables

The quadlets use the same `.env` file as the Docker Compose configuration. Make sure it contains:

- `PG_DB` - PostgreSQL database name (default: authentik)
- `PG_USER` - PostgreSQL user (default: authentik)
- `PG_PASS` - PostgreSQL password (required)
- `AUTHENTIK_SECRET_KEY` - Authentik secret key (required)
- `AUTHENTIK_IMAGE` - Authentik image (default: ghcr.io/goauthentik/server)
- `AUTHENTIK_TAG` - Authentik version tag (default: 2025.12.4)
- `COMPOSE_PORT_HTTP` - HTTP port (default: 9000)
- `COMPOSE_PORT_HTTPS` - HTTPS port (default: 9443)

## Differences from Docker Compose

1. **Pod architecture**: All containers run in a single pod, sharing the same network namespace
2. **Simplified networking**: Containers communicate via `localhost` instead of container names
3. **Single unit management**: Start/stop all services with one command using the pod
4. **Health checks**: Podman Quadlets support health checks natively using `HealthCmd`, `HealthInterval`, etc.
5. **Dependencies**: Service dependencies are managed using systemd's `After=` and `Requires=`
6. **Docker socket**: The worker mounts `/run/podman/podman.sock` instead of `/var/run/docker.sock`
7. **Variable substitution**: Environment variable defaults (like `${PG_DB:-authentik}`) need to be handled in the `.env` file or by systemd

## Troubleshooting

### Services won't start

Check the systemd journal for errors:

```bash
journalctl --user -xe
```

### Can't connect to Podman

Make sure the Podman machine is running (macOS/Windows):

```bash
podman machine list
podman machine start
```

### Environment variables not working

Make sure the `.env` file path is correct and readable. You can also set environment variables directly in the quadlet files using `Environment=KEY=value`.

### Pod or container issues

Check the pod status:

```bash
podman pod ps
podman ps -a --pod
```

Inspect the pod:

```bash
podman pod inspect authentik
```

## Direct Pod Management (Alternative)

While systemd is the recommended way to manage quadlets, you can also use Podman commands directly:

### List pods

```bash
podman pod ps
```

### List containers in the pod

```bash
podman ps -a --pod --filter pod=authentik
```

### Start/stop the pod

```bash
podman pod start authentik
podman pod stop authentik
podman pod restart authentik
```

### Remove the pod (stops and removes all containers)

```bash
podman pod rm -f authentik
```

### View pod logs

```bash
podman pod logs authentik
podman pod logs -f authentik  # Follow logs
```

## Additional Resources

- [Podman Quadlet Documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
- [systemd Unit Files](https://www.freedesktop.org/software/systemd/man/systemd.unit.html)
