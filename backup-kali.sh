#!/usr/bin/env bash
# Резервне копіювання домашніх папок Kali на зовнішній диск Data.
# Дзеркало: вміст Backup/Kali на диску = вміст домашніх папок.
# Оригінали лишаються на своєму місці. Запуск:  bash backup-kali.sh
set -uo pipefail

DEV=/dev/disk/by-label/Data

# --- 1. Перевірка, що диск підключений ---
if ! lsblk -lno LABEL | grep -qx Data; then
  echo "Диск Data не підключено. Підключи диск і запусти знову."
  exit 1
fi

# --- 2. Змонтувати, якщо ще не змонтовано ---
MNT=$(lsblk -lno MOUNTPOINT "$DEV" 2>/dev/null | head -1 | sed 's/ //g')
if [ -z "$MNT" ]; then
  MNT=$(udisksctl mount -b "$DEV" 2>/dev/null | sed 's/.* at //; s/\.\?$//')
fi
if [ -z "$MNT" ] || [ ! -d "$MNT" ]; then
  echo "Не вдалося змонтувати диск."
  exit 1
fi
echo "Диск: $MNT"

DST="$MNT/Backup/Kali"
mkdir -p "$DST"

# --- 3. Дзеркалювання папок ---
STATUS=0
for dir in Documents Downloads Pictures Videos Music Desktop; do
  if [ -d "$HOME/$dir" ]; then
    echo
    echo "=== $dir ==="
    rsync -a --delete --info=progress2 --no-inc-recursive \
      "$HOME/$dir/" "$DST/$dir/" || STATUS=1
  fi
done

sync
echo
if [ "$STATUS" -eq 0 ]; then
  echo "##############################################"
  echo "БЕКАП ЗАВЕРШЕНО. Копія в $DST"
  echo "Не забудь: «Від'єднати» диск перед витягуванням."
  echo "##############################################"
else
  echo "!!! Бекап завершено з ПОМИЛКАМИ — дивись повідомлення вище."
fi
exit "$STATUS"
