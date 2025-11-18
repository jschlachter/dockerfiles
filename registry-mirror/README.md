# Registry Mirror

A Docker Compose configuration for running a Docker registry mirror locally.

This setup allows you to cache Docker images from Docker Hub and other registries, reducing bandwidth usage and improving pull speeds for frequently used images.

## Usage

Start the registry mirror:

```bash
docker-compose up -d
```

Stop the registry mirror:

```bash
docker-compose down
```

Configure your Docker daemon to use this mirror by adding the following to `/etc/docker/daemon.json`:

```json
{
  "registry-mirrors": ["http://localhost:5000"]
}
```

Then restart the Docker daemon.
