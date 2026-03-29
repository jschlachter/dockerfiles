#!/usr/bin/env zsh

# Script to reload systemd, enable a service, and display its status

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <service-name>"
    echo "Example: $0 docker"
    exit 1
fi

SERVICE_NAME="$1"

echo "==> Reloading systemd daemon..."
systemctl --user daemon-reload

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to reload systemd daemon"
    exit 1
fi

echo "\n==> Enabling service: $SERVICE_NAME..."
systemctl --user enable --now "$SERVICE_NAME"

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to enable service $SERVICE_NAME"
    exit 1
fi

echo "\n==> Service status for: $SERVICE_NAME"
sudo systemctl status "$SERVICE_NAME"
