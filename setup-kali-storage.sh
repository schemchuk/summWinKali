#!/usr/bin/env bash
# Підключення Kali до спільного сховища на зовнішньому диску Data (exFAT).
#   1) автомонтування диска у фіксовану точку /mnt/data
#   2) перенесення домашніх папок на диск + симлінки
# Запуск:  sudo bash setup-kali-storage.sh
set -euo pipefail
exec > >(tee /tmp/setup-kali-storage.log) 2>&1
set -x

[ "$(id -u)" -eq 0 ] || { echo "Запустіть через sudo."; exit 1; }

U="${SUDO_USER:-woshe}"
H=$(getent passwd "$U" | cut -d: -f6)
UID_N=$(id -u "$U")
GID_N=$(id -g "$U")

# --- 1. Точка монтування + fstab ---
mkdir -p /mnt/data
if ! grep -q ' /mnt/data ' /etc/fstab; then
  cat >> /etc/fstab <<EOF
# Зовнішній диск Data — спільне сховище Windows/Kali
LABEL=Data /mnt/data exfat defaults,nofail,noatime,x-systemd.device-timeout=5,uid=$UID_N,gid=$GID_N 0 0
EOF
fi

# --- 2. Змонтувати зараз, якщо диск підключений ---
if lsblk -lno LABEL | grep -qx Data; then
  mountpoint -q /mnt/data || mount /mnt/data
  echo "Диск змонтовано в /mnt/data"
else
  echo "Диск Data НЕ підключено. fstab готовий — перезапусти скрипт з підключеним диском."
  exit 1
fi

# --- 3. Перенесення домашніх папок на диск + симлінки ---
link_folder() {
  local local_name="$1" disk_dir="$2"
  mkdir -p "/mnt/data/$disk_dir"

  if [ -d "$H/$local_name" ] && [ ! -L "$H/$local_name" ]; then
    echo "Переношу ~/$local_name → /mnt/data/$disk_dir (може тривати)..."
    cp -a "$H/$local_name/." "/mnt/data/$disk_dir/"
    rm -rf "$H/$local_name"
  fi

  if [ ! -e "$H/$local_name" ]; then
    sudo -u "$U" ln -s "/mnt/data/$disk_dir" "$H/$local_name"
    echo "  ~/$local_name → /mnt/data/$disk_dir"
  fi
}

link_folder Documents 01_Documents
link_folder Downloads 04_Downloads
link_folder Pictures  05_Media/Pictures
link_folder Videos    05_Media/Videos
link_folder Music     05_Media/Music
link_folder Projects  02_Projects

sync
echo
echo "##############################################"
echo "Готово. Тепер ~/Documents, ~/Downloads і т.д."
echo "живуть на диску Data. Якщо диск відключений —"
echo "ці папки тимчасово недоступні."
echo "##############################################"
