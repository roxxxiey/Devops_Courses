#!/usr/bin/env bash
set -euo pipefail

TESTER_SSH_USER="${TESTER_SSH_USER:-tester}"
KEY_SOURCE_DIR="/opt/tester_keys"
KEY_OUTPUT_DIR="/work/ssh/generated"
PRIVATE_KEY="${KEY_OUTPUT_DIR}/tester_ed25519"
PUBLIC_KEY="${PRIVATE_KEY}.pub"

if ! id "${TESTER_SSH_USER}" >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash "${TESTER_SSH_USER}"
fi

mkdir -p /run/sshd "${KEY_OUTPUT_DIR}" "/home/${TESTER_SSH_USER}/.ssh" /work/logs
cp "${KEY_SOURCE_DIR}/tester_ed25519" "${PRIVATE_KEY}"
cp "${KEY_SOURCE_DIR}/tester_ed25519.pub" "${PUBLIC_KEY}"
cp "${PUBLIC_KEY}" "/home/${TESTER_SSH_USER}/.ssh/authorized_keys"

chown -R "${TESTER_SSH_USER}:${TESTER_SSH_USER}" "/home/${TESTER_SSH_USER}/.ssh"
chmod 700 "/home/${TESTER_SSH_USER}/.ssh"
chmod 600 "/home/${TESTER_SSH_USER}/.ssh/authorized_keys"
chmod 600 "${PRIVATE_KEY}"

cat >/etc/ssh/sshd_config.d/tester.conf <<EOF
Port 22
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
AllowUsers ${TESTER_SSH_USER}
EOF

ssh-keygen -A
/usr/sbin/sshd

echo "Tester SSH private key is available at ${PRIVATE_KEY}"
echo "Tester SSH public key is available at ${PUBLIC_KEY}"

cd /work
exec python3 -m http.server 3000
