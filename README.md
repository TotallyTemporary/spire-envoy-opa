## Cloud server

Installed both server and agent
Node CN=cloud-server.paavo-rotsten.org

# Entries
sudo -u spire-server spire-server entry create -node -spiffeID spiffe://paavo-rotsten.org/cloud-server -selector x509pop:subject:cn:cloud-server.paavo-rotsten.org -socketPath /run/spire-server/private/api.sock

sudo -u spire-server spire-server entry create -spiffeID spiffe://paavo-rotsten.org/cloud-service -parentID spiffe://paavo-rotsten.org/cloud-server -selector unix:user:cloud-service -socketPath /run/spire-server/private/api.sock

# User
sudo useradd -r -g spire-services -d "/var/lib/cloud-service" -s /usr/sbin/nologin cloud-service

## Edge node 1

Installed agent
Node CN=edge-node-1.paavo-rotsten.org


## Edge device 1

Installed agent
Node CN=edge-device-1.paavo-rotsten.org