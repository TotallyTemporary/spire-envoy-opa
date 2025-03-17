set -euo pipefail

SPIRE_DIRECTORY="spire-1.11.2"
SPIRE_INSTALL_PACKAGE="https://github.com/spiffe/spire/releases/download/v1.11.2/${SPIRE_DIRECTORY}-linux-arm64-musl.tar.gz"

TRUST_DOMAIN="paavo-rotsten.org"
SPIRE_SERVER_PORT="8081"

SPIRE_SERVER_DATA_DIR="/var/lib/spire-server"
SPIRE_SERVER_CONF_DIR="/etc/spire-server"
SPIRE_SERVER_SOCKET="/run/spire-server/private/api.sock"
SPIRE_SERVER_SERVICE="/etc/systemd/system/spire-server.service"

curl -s -N -L "${SPIRE_INSTALL_PACKAGE}" | tar xz
sudo cp "${SPIRE_DIRECTORY}/bin/spire-server" /usr/local/bin/

# Create directories
sudo mkdir -p "${SPIRE_SERVER_DATA_DIR}/data"
sudo mkdir -p "${SPIRE_SERVER_CONF_DIR}"

# Create trust bundle
sudo openssl req -subj "/C=/ST=/L=/O=/CN=${TRUST_DOMAIN}" -newkey rsa:2048 -nodes -keyout ./ca.key -x509 -days 365 -out ./ca.crt
sudo cp ./ca.key "${SPIRE_SERVER_CONF_DIR}/"
sudo cp ./ca.crt "${SPIRE_SERVER_CONF_DIR}/"

# Create x509pop key and cert
sudo openssl req -subj "/C=/ST=/L=/O=/CN=${TRUST_DOMAIN}" -newkey rsa:2048 -nodes -keyout ./x509pop.key -x509 -days 365 -out ./x509pop.crt
# sudo cp ./x509pop.key "${SPIRE_SERVER_CONF_DIR}/" # only needed for provisioning
sudo cp ./x509pop.crt "${SPIRE_SERVER_CONF_DIR}/"

# Create config file
sudo bash -c "cat > ${SPIRE_SERVER_CONF_DIR}/server.conf" <<EOF
server {
    bind_address = "0.0.0.0"
    bind_port = "${SPIRE_SERVER_PORT}"
    trust_domain = "${TRUST_DOMAIN}"
    data_dir = "${SPIRE_SERVER_DATA_DIR}/data"
    log_level = "DEBUG"
    ca_ttl = "168h"
    default_x509_svid_ttl = "48h"
    socket_path = "${SPIRE_SERVER_SOCKET}"
}

plugins {
    DataStore "sql" {
        plugin_data {
            database_type = "sqlite3"
            connection_string = "${SPIRE_SERVER_DATA_DIR}/data/datastore.sqlite3"
        }
    }

    UpstreamAuthority "disk" {
        plugin_data {
            cert_file_path = "${SPIRE_SERVER_CONF_DIR}/ca.crt"
            key_file_path = "${SPIRE_SERVER_CONF_DIR}/ca.key"
        }
    }

    KeyManager "disk" {
        plugin_data {
            keys_path = "${SPIRE_SERVER_DATA_DIR}/data/keys.json"
        }
    }

    NodeAttestor "join_token" {
        plugin_data {}
    }

    NodeAttestor "x509pop" {
        plugin_data {
            ca_bundle_path = "${SPIRE_SERVER_CONF_DIR}/x509pop.crt"
        }
    }
}
EOF

# Create user
if ! id -u "spire-server" >/dev/null 2>&1; then
    sudo groupadd spire-server
    sudo useradd -r -g spire-server -d "${SPIRE_SERVER_DATA_DIR}" -s /usr/sbin/nologin spire-server
fi



# Create systemd service
sudo bash -c "cat > ${SPIRE_SERVER_SERVICE}" << EOF
[Unit]
Description=SPIRE Server
After=network.target

[Service]
PermissionsStartOnly=true
User=spire-server
Group=spire-server
ExecStartPre=+mkdir -p /run/spire-server
ExecStartPre=+chown -R spire-server:spire-server /run/spire-server
ExecStartPre=+chmod -R 0700 /run/spire-server
ExecStart=/usr/local/bin/spire-server run -config ${SPIRE_SERVER_CONF_DIR}/server.conf
Restart=always
LimitNOFILE=65536
WorkingDirectory=${SPIRE_SERVER_DATA_DIR}

[Install]
WantedBy=multi-user.target
EOF

# Secure with proper permissions
sudo chown -R root:root "/usr/local/bin/spire-server"  
sudo chmod -R 755 "/usr/local/bin/spire-server"
sudo chown -R spire-server:spire-server "${SPIRE_SERVER_DATA_DIR}"
sudo chmod -R 750  "${SPIRE_SERVER_DATA_DIR}"
sudo chown -R root:spire-server "${SPIRE_SERVER_CONF_DIR}"
sudo chmod -R 750  "${SPIRE_SERVER_CONF_DIR}"
sudo chown root:root "${SPIRE_SERVER_SERVICE}"
sudo chmod -R 640 "${SPIRE_SERVER_SERVICE}"

# Check the server is healthy
sudo systemctl daemon-reload
sudo systemctl enable --now spire-server
sudo systemctl status spire-server
# A bit later...
# sudo -u spire-server spire-server healthcheck -socketPath "${SPIRE_SERVER_SOCKET}"