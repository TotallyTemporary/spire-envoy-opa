# wget https://github.com/open-policy-agent/opa-envoy-plugin/releases/download/v1.2.0-envoy-2/opa_envoy_linux_amd64_static
# sudo chmod +x opa_envoy_linux_amd64_static
# sudo mv opa_envoy_linux_amd64_static /usr/local/bin/opa_envoy

set -euo pipefail

# Provided files
OPA_CONFIG="./opa-config.yaml"
OPA_POLICY="./edge_node_policy.rego"

USER="edge-service-opa"
SERVICE_NAME="edge-service"
OPA_ALL_CONFS_DIR="/etc/opa"
OPA_CONF_DIR="${OPA_ALL_CONFS_DIR}/${SERVICE_NAME}"
OPA_SERVICE="/etc/systemd/system/${SERVICE_NAME}-opa.service"

sudo mkdir -p "${OPA_CONF_DIR}"
sudo cp "${OPA_CONFIG}" "${OPA_CONF_DIR}/opa-config.yaml"
sudo cp "${OPA_POLICY}" "${OPA_CONF_DIR}/opa-policy.rego"

# Create user
if ! id -u "${USER}" >/dev/null 2>&1; then
    sudo groupadd "${USER}"
    sudo useradd -g "${USER}" -r -s /usr/sbin/nologin "${USER}"
fi

# Create systemd service
sudo bash -c "cat > ${OPA_SERVICE}" << EOF
[Unit]
Description=OPA Service
After=network.target

[Service]
User=${USER}
Group=${USER}
ExecStart=/usr/local/bin/opa_envoy run --server --config-file="${OPA_CONF_DIR}/opa-config.yaml" "${OPA_CONF_DIR}/opa-policy.rego"
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Secure with proper permissions
sudo chown -R "root:root" "${OPA_ALL_CONFS_DIR}"
sudo chmod -R 755  "${OPA_ALL_CONFS_DIR}"
sudo chown -R "root:${USER}" "${OPA_CONF_DIR}"
sudo chmod -R 750  "${OPA_CONF_DIR}"
sudo chown root:root "${OPA_SERVICE}"
sudo chmod -R 640 "${OPA_SERVICE}"

# Check the agent is healthy
sudo systemctl daemon-reload
sudo systemctl enable --now "${SERVICE_NAME}-opa"
sudo systemctl status "${SERVICE_NAME}-opa"
