#!/bin/bash

set -e

# Configuration
REALITY_DOMAIN="www.apple.com"  # Used only as handshake server
HY2_DOMAIN="www.apple.com"
CONFIG_DIR="/etc/singbox-dual"
VLESS_PORT=2445
HY2_PORT=2446
SERVICE_NAME="sing-box-dual"
REMARK_HY2_ENC="hy2"
REMARK_VLESS_ENC="vless"

# self tls
CERT_DIR="$CONFIG_DIR/cert"
mkdir -p "$CERT_DIR"
CERT_FILE="$CERT_DIR/hy2.crt"
KEY_FILE="$CERT_DIR/hy2.key"

openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout "$KEY_FILE" \
  -out "$CERT_FILE" \
  -subj "/C=US/ST=CA/L=SanFrancisco/O=MyOrg/OU=MyUnit/CN=$HY2_DOMAIN"


# Install sing-box using official script
curl -fsSL https://sing-box.app/install.sh | sh

# Generate UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# Create custom config directory
mkdir -p "$CONFIG_DIR"

# Generate Reality key pair
REALITY_KEYS=$(sing-box generate reality-keypair)
PRIV_KEY=$(echo "$REALITY_KEYS" | grep "PrivateKey" | awk -F": " '{print $2}')
PUB_KEY=$(echo "$REALITY_KEYS" | grep "PublicKey" | awk -F": " '{print $2}')
SHORT_ID=$(openssl rand -hex 8)

# Generate config.json
cat > "$CONFIG_DIR/config.json" <<EOF
{
  "log": {
    "level": "info"
  },
  "dns": {
    "servers": [
      {
        "type": "local",
        "tag": "local"
      }
    ]
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": $VLESS_PORT,
      "users": [
        {
          "uuid": "$UUID"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "$REALITY_DOMAIN",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "$REALITY_DOMAIN",
            "server_port": 443
          },
          "private_key": "$PRIV_KEY",
          "short_id": ["$SHORT_ID"]
        }
      }
    },
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": $HY2_PORT,
      "users": [
        {
          "password": "$UUID"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "$HY2_DOMAIN",
        "certificate_path": "$CERT_FILE",
        "key_path": "$KEY_FILE"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    },
  ]
}
EOF

# Create systemd service
cat > "/etc/systemd/system/$SERVICE_NAME.service" <<EOF
[Unit]
Description=Sing-box Dual Protocol Service (Reality + Hysteria2)
After=network.target

[Service]
ExecStart=/usr/bin/sing-box run -c $CONFIG_DIR/config.json
Restart=always
User=root
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

# Output connection info
echo "===================================="
echo "Sing-box deployment completed."
echo ""
echo "UUID: $UUID"
echo "Reality public key: $PUB_KEY"
echo "Reality short_id: $SHORT_ID"
echo "Reality handshake domain: $REALITY_DOMAIN"
echo "Reality port: $VLESS_PORT"
echo ""
echo "Hysteria2 domain: $HY2_DOMAIN"
echo "Hysteria2 port: $HY2_PORT"
echo "Password: $UUID"
echo ""
echo "Configuration directory: $CONFIG_DIR"
echo "Systemd service: $SERVICE_NAME"
echo "===================================="

# hysteria2 subscription link

PUBLIC_IP=$(curl -s https://api.ipify.org)

echo "Using public IP: $PUBLIC_IP"

HY2_LINK="hysteria2://${UUID}@${PUBLIC_IP}:${HY2_PORT}?alpn=h3&insecure=1#${REMARK_HY2_ENC}"

# vless + reality subscription link
VLESS_LINK="vless://${UUID}@${PUBLIC_IP}:${VLESS_PORT}?encryption=none&security=reality&sni=${REALITY_DOMAIN}&pbk=${PUB_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#${REMARK_VLESS_ENC}"

echo "subscription link:"
echo "$HY2_LINK"
echo "$VLESS_LINK"