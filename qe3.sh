#!/bin/bash
# ============================================================
# QE3 - SSH Bruteforce Auto Blocker (ALL IN ONE)
# Author : TerraNet / QE3
# Rule   : 3x gagal login -> block 24 jam
# Auto   : systemd + reboot persistence
# ============================================================

SERVICE_NAME="qe3-ssh"
INSTALL_PATH="/usr/local/bin/qe3.sh"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

BLOCK_TIME=86400
MAX_FAIL=3
DB="/var/lib/qe3"
LOG="/var/log/qe3-ssh-block.log"

mkdir -p $DB
touch $LOG

# ------------------------------------------------------------
# Detect SSH log
# ------------------------------------------------------------
if [ -f /var/log/auth.log ]; then
    SSH_LOG="/var/log/auth.log"
elif [ -f /var/log/secure ]; then
    SSH_LOG="/var/log/secure"
else
    echo "[QE3] SSH log not found"
    exit 1
fi

block_ip() {
    local IP=$1
    echo "$(date) BLOCK $IP" >> $LOG
    iptables -C INPUT -s $IP -j DROP 2>/dev/null || \
    iptables -I INPUT -s $IP -j DROP
    date +%s > $DB/$IP
}

unblock_ip() {
    local IP=$1
    iptables -D INPUT -s $IP -j DROP 2>/dev/null
    rm -f $DB/$IP
    echo "$(date) UNBLOCK $IP" >> $LOG
}

check_expired() {
    local NOW=$(date +%s)
    for FILE in $DB/*; do
        [ -e "$FILE" ] || continue
        IP=$(basename $FILE)
        TIME=$(cat $FILE)
        (( NOW - TIME > BLOCK_TIME )) && unblock_ip $IP
    done
}

monitor_ssh() {
    tail -Fn0 $SSH_LOG | while read LINE; do
        echo "$LINE" | grep -Ei \
        "Failed password|Invalid user|authentication failure" >/dev/null || continue

        IP=$(echo "$LINE" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
        [ -z "$IP" ] && continue

        COUNT_FILE="$DB/fail_$IP"
        COUNT=$(cat $COUNT_FILE 2>/dev/null || echo 0)
        COUNT=$((COUNT+1))
        echo $COUNT > $COUNT_FILE

        if [ "$COUNT" -ge "$MAX_FAIL" ]; then
            block_ip $IP
            rm -f $COUNT_FILE
        fi
    done
}

install_service() {
    echo "[QE3] Installing..."

    cp "$0" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"

    cat > "$SERVICE_FILE" << SERVICE_EOF
[Unit]
Description=QE3 SSH Bruteforce Protection
After=network.target

[Service]
Type=simple
ExecStart=${INSTALL_PATH} run
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl restart $SERVICE_NAME

    echo "[QE3] Installed & running"
    exit 0
}

case "$1" in
    install)
        install_service
        ;;
    run)
        while true; do
            check_expired
            monitor_ssh
            sleep 5
        done
        ;;
    status)
        systemctl status $SERVICE_NAME
        ;;
    unblock-all)
        for FILE in $DB/*; do
            IP=$(basename $FILE)
            unblock_ip $IP
        done
        ;;
    *)
        echo "Usage:"
        echo "  bash qe3.sh install"
        echo "  qe3.sh status"
        echo "  qe3.sh unblock-all"
        ;;
esac
