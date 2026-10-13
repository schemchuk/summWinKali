#!/usr/bin/env bash
# Повне прибирання «ПОІМЕННО» і підготовка зовнішнього диска як єдиного
# сховища exFAT на весь об'єм (читається і Windows 11, і Kali).
# Запуск:  sudo bash prepare-disk-full.sh
set -euo pipefail

# Увесь вивід — і в термінал, і в лог (щоб можна було діагностувати)
exec > >(tee /tmp/prepare-disk.log) 2>&1
set -x

[ "$(id -u)" -eq 0 ] || { echo "Запустіть через sudo."; exit 1; }

DISK=/dev/sda

# --- Запобіжник: переконатися, що це саме зовнішній Expansion HDD ---
MODEL=$(lsblk -dn -o MODEL "$DISK")
SIZE=$(lsblk -dn -o SIZE  "$DISK")
echo "Знайдено диск: $DISK | модель: $MODEL | об'єм: $SIZE"
case "$MODEL" in
  *Expansion*) ;;
  *) echo "!!! Це НЕ зовнішній Expansion HDD — перервано для безпеки."; exit 1 ;;
esac
read -r -p "УВАГА: усі дані на $DISK будуть ВИДАЛЕНІ. Введіть «так» для підтвердження: " ANS
[ "$ANS" = "так" ] || { echo "Скасовано."; exit 0; }

# --- 1. Демонтувати всі розділи диска ---
for p in $(lsblk -n -r -o PATH "$DISK" | tail -n +2); do
  udisksctl unmount -b "$p" 2>/dev/null || umount "$p" 2>/dev/null || true
done
sync

# --- 2. Видалити компоненти «ПОІМЕННО» з цієї ОС ---
rm -f /usr/local/bin/vault /usr/local/bin/vault-workstart.sh /usr/local/bin/poimenno-icon
rm -rf /usr/local/share/poimenno
rm -f /etc/udev/rules.d/99-poimenno.rules
udevadm control --reload
rmdir /mnt/vault 2>/dev/null || true
echo "Компоненти «ПОІМЕННО» видалено з системи."

# --- 3. Один розділ на весь диск (GPT, тип Microsoft basic data) ---
sfdisk --wipe always "$DISK" <<'EOF'
label: gpt
type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
EOF
udevadm settle
sleep 2

# --- 4. Форматування в exFAT ---
PART=$(lsblk -n -r -o PATH "$DISK" | tail -n +2 | head -1)
echo "Форматування $PART у exFAT..."
mkfs.exfat -L Data "$PART"
sync

echo
echo "##############################################"
echo "Готово. Витягніть диск і підключіть знову —"
echo "він з'явиться як «Data» на весь об'єм (931 ГБ),"
echo "однаково доступний у Windows 11 і Kali."
echo "##############################################"
