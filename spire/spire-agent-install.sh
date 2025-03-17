set -euo pipefail

SPIRE_DIRECTORY="spire-1.11.2"
SPIRE_INSTALL_PACKAGE="https://github.com/spiffe/spire/releases/download/v1.11.2/${SPIRE_DIRECTORY}-linux-amd64-musl.tar.gz"

TRUST_DOMAIN="paavo-rotsten.org"
SPIRE_SERVER_IP="158.180.45.228"
SPIRE_SERVER_PORT="8081"
COMMON_NAME="edge-node-1.paavo-rotsten.org"

# Provided files
SPIRE_SERVER_TRUST_CERT="./ca.crt"
SPIRE_SERVER_X509_KEY="./x509pop.key"
SPIRE_SERVER_X509_CERT="./x509pop.crt"
# ---

SPIRE_AGENT_DATA_DIR="/var/lib/spire-agent"
SPIRE_AGENT_CONF_DIR="/etc/spire-agent"
SPIRE_AGENT_SOCKET="/run/spire-agent/public/api.sock"
SPIRE_AGENT_SERVICE="/etc/systemd/system/spire-agent.service"

curl -s -N -L "${SPIRE_INSTALL_PACKAGE}" | tar xz
sudo cp "${SPIRE_DIRECTORY}/bin/spire-agent" /usr/local/bin/

# Create directories
sudo mkdir -p "${SPIRE_AGENT_DATA_DIR}/data"
sudo mkdir -p "${SPIRE_AGENT_CONF_DIR}"

# Make config file for key generation
sudo bash -c "cat > agent_cert.cnf" <<EOF
[req]
x509_extensions = x509_ext

[x509_ext]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
EOF

# Create x509pop attestation key and certificate
openssl genpkey -algorithm RSA -out agent.key.pem -pkeyopt rsa_keygen_bits:2048
openssl req -new -key agent.key.pem -out agent.csr.pem -subj "/C=/ST=/L=/O=/CN=${COMMON_NAME}" -config agent_cert.cnf
sudo openssl x509 -req -in agent.csr.pem -CA ${SPIRE_SERVER_X509_CERT} -CAkey ${SPIRE_SERVER_X509_KEY} -CAcreateserial -out agent.crt.pem -days 365 -extfile agent_cert.cnf -extensions x509_ext
sudo cp ./agent.key.pem "${SPIRE_AGENT_CONF_DIR}/"
sudo cp ./agent.crt.pem "${SPIRE_AGENT_CONF_DIR}/"

# Copy SPIRE server CA bundle
sudo cp "${SPIRE_SERVER_TRUST_CERT}" "${SPIRE_AGENT_CONF_DIR}/ca.crt"

# Create config file
sudo bash -c "cat > ${SPIRE_AGENT_CONF_DIR}/agent.conf" <<EOF
agent {
    data_dir = "${SPIRE_AGENT_DATA_DIR}/data"
    log_level = "DEBUG"
    trust_domain = "${TRUST_DOMAIN}"
    server_address = "${SPIRE_SERVER_IP}"
    server_port = ${SPIRE_SERVER_PORT}
    trust_bundle_path = "${SPIRE_AGENT_CONF_DIR}/ca.crt"
    socket_path = "${SPIRE_AGENT_SOCKET}"
}

plugins {
   KeyManager "disk" {
        plugin_data {
            directory = "${SPIRE_AGENT_DATA_DIR}/data"
        }
    }

    NodeAttestor "x509pop" {
        plugin_data {
            private_key_path = "${SPIRE_AGENT_CONF_DIR}/agent.key.pem"
            certificate_path = "${SPIRE_AGENT_CONF_DIR}/agent.crt.pem"
        }
    }

    WorkloadAttestor "unix" {
        plugin_data {}
    }
}
EOF

# Create user
if ! id -u "spire-agent" >/dev/null 2>&1; then
    sudo groupadd spire-services
    sudo groupadd spire-agent
    sudo useradd -r -g spire-agent -d "${SPIRE_AGENT_DATA_DIR}" -s /usr/sbin/nologin spire-agent
fi



# Create systemd service
sudo bash -c "cat > ${SPIRE_AGENT_SERVICE}" << EOF
[Unit]
Description=SPIRE Agent
After=network.target

[Service]
PermissionsStartOnly=true
User=spire-agent
Group=spire-agent
ExecStartPre=+mkdir -p /run/spire-agent
ExecStartPre=+chown -R spire-agent:spire-services /run/spire-agent
ExecStartPre=+chmod -R 0750 /run/spire-agent
ExecStart=/usr/local/bin/spire-agent run -config ${SPIRE_AGENT_CONF_DIR}/agent.conf
Restart=always
LimitNOFILE=65536
WorkingDirectory=${SPIRE_AGENT_DATA_DIR}

[Install]
WantedBy=multi-user.target
EOF

# Secure with proper permissions
sudo chown -R root:root "/usr/local/bin/spire-agent"  
sudo chmod -R 755 "/usr/local/bin/spire-agent"
sudo chown -R spire-agent:spire-agent "${SPIRE_AGENT_DATA_DIR}"
sudo chmod -R 750  "${SPIRE_AGENT_DATA_DIR}"
sudo chown -R root:spire-agent "${SPIRE_AGENT_CONF_DIR}"
sudo chmod -R 750  "${SPIRE_AGENT_CONF_DIR}"
sudo chown root:root "${SPIRE_AGENT_SERVICE}"
sudo chmod -R 640 "${SPIRE_AGENT_SERVICE}"

# Check the agent is healthy
sudo systemctl daemon-reload
sudo systemctl enable --now spire-agent
sudo systemctl status spire-agent
# A bit later...
# sudo -u spire-agent spire-agent healthcheck -socketPath "${SPIRE_AGENT_SOCKET}"