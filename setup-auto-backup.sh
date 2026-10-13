#!/usr/bin/env bash
# Автоматичний бекап Kali на диск Data:
#   - при кожному завантаженні (через 3 хв)
#   - щодня о 10:00
# Запуск:  sudo bash setup-auto-backup.sh
set -euo pipefail
exec > >(tee /tmp/setup-auto-backup.log) 2>&1
set -x

[ "$(id -u)" -eq 0 ] || { echo "Запустіть через sudo."; exit 1; }

U=woshe
SCRIPT="/home/$U/VS_Code_projects/summWinKali/backup-kali.sh"
[ -f "$SCRIPT" ] || { echo "Не знайдено $SCRIPT"; exit 1; }

# --- 1. Фіксована точка монтування для диска ---
mkdir -p /mnt/data
if ! grep -q ' /mnt/data ' /etc/fstab; then
  cat >> /etc/fstab <<'EOF'
# Зовнішній диск Data — резервне сховище
LABEL=Data /mnt/data exfat defaults,nofail,noatime,x-systemd.device-timeout=5,uid=1000,gid=1000 0 0
EOF
fi
systemctl daemon-reload

# --- 2. Служба бекапу ---
cat > /etc/systemd/system/backup-kali.service <<EOF
[Unit]
Description=Backup Kali home folders to Data drive
# Якщо диск не примонтований (не підключений) — пропустити без помилок
RequiresMountsFor=/mnt/data

[Service]
Type=oneshot
User=$U
ExecStart=$SCRIPT
Nice=10
IOSchedulingClass=idle
EOF

# --- 3. Таймер: після кожного завантаження ---
cat > /etc/systemd/system/backup-kali-boot.timer <<'EOF'
[Unit]
Description=Backup to Data drive after boot

[Timer]
OnBootSec=3min
Unit=backup-kali.service

[Install]
WantedBy=timers.target
EOF

# --- 4. Таймер: щодня о 10:00 ---
cat > /etc/systemd/system/backup-kali-daily.timer <<'EOF'
[Unit]
Description=Backup to Data drive daily at 10:00

[Timer]
OnCalendar=Mon-Sun 10:00
Persistent=true
Unit=backup-kali.service

[Install]
WantedBy=timers.target
EOF

# --- 5. Активація ---
systemctl daemon-reload
systemctl enable --now backup-kali-boot.timer
systemctl enable --now backup-kali-daily.timer

echo
echo "##############################################"
echo "Готово. Активні таймери:"
systemctl list-timers backup-kali-* --no-pager
echo "##############################################"
