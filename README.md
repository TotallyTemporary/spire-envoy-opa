# Notes
This repository incorrectly refers to an end device as an 'edge device'.


# Cloud server

Installed both server and agent
Node CN=cloud-server.paavo-rotsten.org

## Entries
sudo -u spire-server spire-server entry create -node -spiffeID spiffe://paavo-rotsten.org/cloud-server -selector x509pop:subject:cn:cloud-server.paavo-rotsten.org -socketPath /run/spire-server/private/api.sock

sudo -u spire-server spire-server entry create -spiffeID spiffe://paavo-rotsten.org/cloud-service -parentID spiffe://paavo-rotsten.org/cloud-server -selector unix:user:cloud-service -socketPath /run/spire-server/private/api.sock

## User
sudo useradd -r -g spire-services -d "/var/lib/cloud-service" -s /usr/sbin/nologin cloud-service

## Test
sudo -u cloud-service spire-agent api fetch x509 -socketPath /run/spire-agent/public/api.sock

# Edge node 1
Installed agent
Node CN=edge-node-1.paavo-rotsten.org

## Entries
sudo -u spire-server spire-server entry create -node -spiffeID spiffe://paavo-rotsten.org/edge-node-1 -selector x509pop:subject:cn:edge-node-1.paavo-rotsten.org -socketPath /run/spire-server/private/api.sock

sudo -u spire-server spire-server entry create -spiffeID spiffe://paavo-rotsten.org/edge-service -parentID spiffe://paavo-rotsten.org/edge-node-1 -selector unix:user:edge-service -socketPath /run/spire-server/private/api.sock

## User
sudo useradd -r -g spire-services -d "/var/lib/edge-service" -s /usr/sbin/nologin edge-service

## Test
sudo -u edge-service spire-agent api fetch x509 -socketPath /run/spire-agent/public/api.sock

# Edge device 1
Installed agent
Node CN=edge-device-1.paavo-rotsten.org

## Entries
sudo -u spire-server spire-server entry create -node -spiffeID spiffe://paavo-rotsten.org/edge-device-1 -selector x509pop:subject:cn:edge-device-1.paavo-rotsten.org -socketPath /run/spire-server/private/api.sock

sudo -u spire-server spire-server entry create -spiffeID spiffe://paavo-rotsten.org/edge-device -parentID spiffe://paavo-rotsten.org/edge-device-1 -selector unix:user:edge-device -socketPath /run/spire-server/private/api.sock

## User
sudo useradd -r -g spire-services -d "/var/lib/edge-device" -s /usr/sbin/nologin edge-device

## Test
sudo -u edge-device spire-agent api fetch x509 -socketPath /run/spire-agent/public/api.sock
