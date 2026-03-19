#!/bin/bash

set -e

REQUIRED_PYTHON="3.9"
VENV_DIR="/opt/django-venv"

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

# Додаємо поточного користувача до групи docker (щоб не потрібен sudo для контейнерів)
REAL_USER="${SUDO_USER:-$USER}"
if id -nG "$REAL_USER" | grep -qw docker; then
    echo "[Docker] користувач '$REAL_USER' вже у групі docker."
else
    echo "[Docker] додаємо користувача '$REAL_USER' до групи docker..."
    usermod -aG docker "$REAL_USER"
    echo "[Docker] користувач доданий. Зміни набудуть чинності після перелогіну."
fi

# --- Docker Compose ---
if command -v docker-compose &>/dev/null || docker compose version &>/dev/null; then
    echo "[Docker Compose] вже встановлений."
else
    echo "[Docker Compose] встановлення..."
    apt-get install -y docker-compose-plugin
    echo "[Docker Compose] встановлено: $(docker compose version)"
fi

# Порівняння версій через sort -V
version_gte() {
    # Повертає 0 (true), якщо $1 >= $2
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# --- Python 3.9+ ---
PYTHON_BIN=""
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')

    if version_gte "$PYTHON_VERSION" "$REQUIRED_PYTHON"; then
        echo "[Python] вже встановлений: Python $PYTHON_VERSION"
        PYTHON_BIN="python3"
    else
        echo "[Python] версія $PYTHON_VERSION застаріла (потрібна >= $REQUIRED_PYTHON), встановлення Python 3.11..."
        apt-get update
        apt-get install -y python3.11 python3.11-venv python3-pip
        PYTHON_BIN="python3.11"
        echo "[Python] встановлено: $($PYTHON_BIN --version)"
    fi
else
    echo "[Python] встановлення Python 3.11..."
    apt-get update
    apt-get install -y python3.11 python3.11-venv python3-pip
    PYTHON_BIN="python3.11"
    echo "[Python] встановлено: $($PYTHON_BIN --version)"
fi

# Перевіряємо, що pip прив'язаний до правильної версії Python
if ! "$PYTHON_BIN" -m pip --version &>/dev/null; then
    echo "[pip] встановлення для $PYTHON_BIN..."
    apt-get install -y python3-pip
fi
echo "[pip] використовується: $($PYTHON_BIN -m pip --version)"

# --- Django (у віртуальному середовищі) ---
if [[ -d "$VENV_DIR" ]] && "$VENV_DIR/bin/python" -m pip show django &>/dev/null; then
    DJANGO_VERSION=$("$VENV_DIR/bin/python" -m pip show django | grep "^Version:" | awk '{print $2}')
    echo "[Django] вже встановлений у $VENV_DIR: версія $DJANGO_VERSION"
else
    echo "[Django] створення віртуального середовища у $VENV_DIR..."
    "$PYTHON_BIN" -m venv "$VENV_DIR"
    echo "[Django] встановлення..."
    "$VENV_DIR/bin/pip" install django
    DJANGO_VERSION=$("$VENV_DIR/bin/pip" show django | grep "^Version:" | awk '{print $2}')
    echo "[Django] встановлено у $VENV_DIR: версія $DJANGO_VERSION"
fi

echo ""
echo "=== Всі інструменти встановлені ==="
echo "Django доступний через: source $VENV_DIR/bin/activate"
