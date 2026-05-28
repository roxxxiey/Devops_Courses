#!/usr/bin/env bash
set -euo pipefail

APP_SSH_USER="${APP_SSH_USER:-appuser}"
APP_PUBLIC_SSH_KEY="${APP_PUBLIC_SSH_KEY:-}"

if ! id "${APP_SSH_USER}" >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash "${APP_SSH_USER}"
fi

mkdir -p /run/sshd "/home/${APP_SSH_USER}/.ssh"

if [ -n "${APP_PUBLIC_SSH_KEY}" ]; then
    printf '%s\n' "${APP_PUBLIC_SSH_KEY}" > "/home/${APP_SSH_USER}/.ssh/authorized_keys"
    echo "Public SSH key for app user ${APP_SSH_USER} has been installed"
else
    : > "/home/${APP_SSH_USER}/.ssh/authorized_keys"
    echo "APP_PUBLIC_SSH_KEY is empty; SSH login to app is disabled"
fi

chown -R "${APP_SSH_USER}:${APP_SSH_USER}" "/home/${APP_SSH_USER}/.ssh"
chmod 700 "/home/${APP_SSH_USER}/.ssh"
chmod 600 "/home/${APP_SSH_USER}/.ssh/authorized_keys"

cat >/etc/ssh/sshd_config.d/app.conf <<EOF
Port 22
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
AllowUsers ${APP_SSH_USER}
EOF

ssh-keygen -A
/usr/sbin/sshd

cd /opt/webapp
exec python3 main.py
