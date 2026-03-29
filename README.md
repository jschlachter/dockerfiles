# Dockerfiles Collection

A curated collection of container configurations for self-hosted applications and development tools I use in my day-to-day workflow.

## 📦 What's Inside

This repository contains both **Docker Compose** configurations and **Podman Quadlet** files for various applications, organized by service.

### Applications

| Application | Type | Description |
|------------|------|-------------|
| [**Authentik**](./authentik/) | Podman Quadlets | Identity provider and SSO platform for authentication and authorization |
| [**Kafka**](./kafka/) | Docker Compose | Apache Kafka with Confluent Control Center for event streaming |
| [**MSSQL**](./mssql/) | Docker Compose | Microsoft SQL Server for development and testing |
| [**Nginx Proxy Manager**](./nginx-proxy-manager/) | Docker Compose | Web-based reverse proxy management with SSL support |
| [**Plex**](./plex/) | Docker Compose | Media server for organizing and streaming personal media |
| [**RabbitMQ**](./rabbitmq/) | Podman Quadlets | Message broker for distributed systems |
| [**Registry Mirror**](./registry-mirror/) | Docker Compose | Docker registry caching proxy to speed up image pulls |
| [**Seq**](./seq/) | Docker Compose | Structured log server for application logging |
| [**Wiki.js**](./wikijs/) | Podman Quadlets | Modern wiki platform for documentation |

## 🚀 Getting Started

### Prerequisites

You'll need one or both of the following depending on which services you want to run:

- **Docker & Docker Compose**: For services using `docker-compose.yml`
  ```bash
  # macOS
  brew install docker docker-compose
  
  # Or use Docker Desktop
  ```

- **Podman**: For services using Quadlet files (`.container`, `.pod`, `.volume`)
  ```bash
  # macOS
  brew install podman
  podman machine init
  podman machine start
  ```

### Usage

#### Docker Compose Services

For services with `docker-compose.yml`:

```bash
cd <service-directory>
docker-compose up -d        # Start in detached mode
docker-compose logs -f      # View logs
docker-compose down         # Stop and remove containers
```

#### Podman Quadlet Services

For services with Quadlet files (authentik, rabbitmq, wikijs):

1. Copy quadlet files to systemd directory:
   ```bash
   mkdir -p ~/.config/containers/systemd
   cp <service>/*.{container,pod,volume} ~/.config/containers/systemd/
   ```

2. Reload systemd and start:
   ```bash
   systemctl --user daemon-reload
   systemctl --user start <service>.service
   ```

See individual service READMEs for detailed setup instructions and configuration options.

## 📁 Repository Structure

```
dockerfiles/
├── README.md                      # This file
├── enable-service.sh              # Helper script to reload/enable user services
├── authentik/                     # Podman Quadlets for Authentik SSO
│   ├── README.md
│   ├── authentik.pod
│   ├── authentik.network
│   ├── authentik-database.volume
│   ├── authentik-postgresql.container
│   ├── authentik-server.container
│   └── authentik-worker.container
├── kafka/                         # Kafka with Confluent
│   ├── README.md
│   └── docker-compose.yml
├── mssql/                         # SQL Server
│   ├── README.md
│   └── docker-compose.yml
├── nginx-proxy-manager/           # Reverse proxy manager
│   └── docker-compose.yml
├── plex/                          # Media server
│   └── docker-compose.yml
├── rabbitmq/                      # Podman Quadlets for RabbitMQ
│   ├── rabbitmq.pod
│   ├── rabbitmq.network
│   ├── rabbitmq.volume
│   └── rabbitmq.container
├── registry-mirror/               # Docker registry cache
│   ├── README.md
│   └── docker-compose.yml
├── seq/                           # Log server
│   ├── .env
│   └── docker-compose.yml
└── wikijs/                        # Podman Quadlets for Wiki.js
  ├── .env
  ├── wikijs.pod
  ├── wikijs.network
  ├── wikijs-database.volume
  ├── wikijs-postgresql.container
  └── wikijs.container
```

## 🔧 Configuration

Most services require environment variables or configuration files:

- Create `.env` files in the service directory as needed
- Update volume paths to match your local setup
- Check individual service READMEs for specific requirements

## 📝 Notes

- **Podman Quadlets** provide systemd integration for better service management on Linux/macOS
- **Docker Compose** offers simpler setup for traditional container deployments
- Some services may require additional configuration before first run
- Check individual service READMEs for detailed setup instructions

## 🤝 Contributing

Feel free to fork this repository and adapt the configurations for your own use. If you find improvements or issues, contributions are welcome!

## 📄 License

These configuration files are provided as-is for personal and educational use.
