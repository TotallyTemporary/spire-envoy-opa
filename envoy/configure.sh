set -euo pipefail

# Provided files
ENVOY_CONFIG="./envoy-edge-device.yaml"

USER="edge-device"
SERVICE_NAME="edge-device"
ENVOY_ALL_CONFS_DIR="/etc/envoy"
ENVOY_CONF_DIR="${ENVOY_ALL_CONFS_DIR}/${SERVICE_NAME}"
ENVOY_DATA_DIR="/var/lib/envoy/${SERVICE_NAME}"
ENVOY_SERVICE="/etc/systemd/system/${SERVICE_NAME}-envoy.service"

sudo mkdir -p "${ENVOY_CONF_DIR}"
sudo mkdir -p "${ENVOY_DATA_DIR}"
sudo cp "${ENVOY_CONFIG}" "${ENVOY_CONF_DIR}/config.yaml"

# Create user
if ! id -u "${USER}" >/dev/null 2>&1; then
    sudo groupadd envoy
    sudo useradd -r -g envoy -G spire-services -d "${ENVOY_DATA_DIR}" -s /usr/sbin/nologin "${USER}"
fi

# Create systemd service
sudo bash -c "cat > ${ENVOY_SERVICE}" << EOF
[Unit]
Description=Envoy Service
After=network.target

[Service]
User=${USER}
Group=envoy
ExecStart=/usr/bin/envoy -c "${ENVOY_CONF_DIR}/config.yaml"
Restart=always
LimitNOFILE=65536
WorkingDirectory=${ENVOY_DATA_DIR}

[Install]
WantedBy=multi-user.target
EOF

# Secure with proper permissions
sudo chown -R "root:envoy" "${ENVOY_ALL_CONFS_DIR}"
sudo chmod -R 750  "${ENVOY_ALL_CONFS_DIR}"
sudo chown -R "${USER}:envoy" "${ENVOY_DATA_DIR}"
sudo chmod -R 750  "${ENVOY_DATA_DIR}"
sudo chown root:root "${ENVOY_SERVICE}"
sudo chmod -R 640 "${ENVOY_SERVICE}"

# Check the agent is healthy
sudo systemctl daemon-reload
sudo systemctl enable --now "${SERVICE_NAME}-envoy"
sudo systemctl status "${SERVICE_NAME}-envoy"
