#!/bin/bash

echo "==> Creating Postgres Secret"
echo -n "$(openssl rand -base64 36 | tr -d '\n')" | podman secret create authentik-db-pass -
echo "postgres db secret created...\n"

echo "==> Create Authentik Secret Key"
echo -n "$(openssl rand -base64 60 | tr -d '\n')" | podman secret create authentik-secret-key -
echo "authentik secret key created...\n"
