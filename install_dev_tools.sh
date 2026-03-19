#!/bin/bash

set -e

# Перевірка, що скрипт запущений від root
if [[ $EUID -ne 0 ]]; then
    echo "Цей скрипт потрібно запускати з правами root (sudo)."
    exit 1
fi

echo "=== Встановлення інструментів розробки ==="

# --- Docker ---
if command -v docker &>/dev/null; then
    echo "[Docker] вже встановлений: $(docker --version)"
else
    echo "[Docker] встановлення..."
    apt-get update
    apt-get install -y ca-certificates curl gnupg

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    echo "[Docker] встановлено: $(docker --version)"
fi

# --- Docker Compose ---
if command -v docker-compose &>/dev/null || docker compose version &>/dev/null; then
    echo "[Docker Compose] вже встановлений."
else
    echo "[Docker Compose] встановлення..."
    apt-get install -y docker-compose-plugin
    echo "[Docker Compose] встановлено: $(docker compose version)"
fi

# --- Python 3.9+ ---
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
    PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

    if [[ "$PYTHON_MAJOR" -ge 3 && "$PYTHON_MINOR" -ge 9 ]]; then
        echo "[Python] вже встановлений: Python $PYTHON_VERSION"
    else
        echo "[Python] версія $PYTHON_VERSION застаріла, встановлення Python 3.11..."
        apt-get update
        apt-get install -y python3.11 python3.11-venv python3-pip
        echo "[Python] встановлено: $(python3.11 --version)"
    fi
else
    echo "[Python] встановлення Python 3.11..."
    apt-get update
    apt-get install -y python3.11 python3.11-venv python3-pip
    echo "[Python] встановлено: $(python3.11 --version)"
fi

# --- pip ---
if ! command -v pip3 &>/dev/null; then
    echo "[pip] встановлення..."
    apt-get install -y python3-pip
fi

# --- Django ---
if pip3 show django &>/dev/null; then
    DJANGO_VERSION=$(pip3 show django | grep "^Version:" | awk '{print $2}')
    echo "[Django] вже встановлений: версія $DJANGO_VERSION"
else
    echo "[Django] встановлення..."
    pip3 install django --break-system-packages
    echo "[Django] встановлено: $(pip3 show django | grep '^Version:' | awk '{print $2}')"
fi

echo ""
echo "=== Всі інструменти встановлені ==="
