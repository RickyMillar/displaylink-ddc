#!/usr/bin/env bash
# Install displaylink-ddc for the current user.
# Needs sudo for the udev rule and the i2c-dev module config.
set -euo pipefail

cd "$(dirname "$(realpath "$0")")"

BIN_DIR="$HOME/.local/bin"
UNIT_DIR="$HOME/.config/systemd/user"
UNIT=monitor-brightness-sync.service

for cmd in python3 gdbus systemctl; do
    command -v "$cmd" >/dev/null || { echo "Missing: $cmd" >&2; exit 1; }
done

echo "==> Load the i2c-dev kernel module now and at boot"
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
sudo modprobe i2c-dev

echo "==> Give the active desktop user access to the DisplayLink I2C bus"
sudo install -m 644 udev/61-displaylink-ddc.rules /etc/udev/rules.d/
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=i2c-dev

echo "==> Install commands to $BIN_DIR"
install -Dm 755 bin/monitor "$BIN_DIR/monitor"
install -Dm 755 bin/monitor-brightness-sync "$BIN_DIR/monitor-brightness-sync"

if [[ "${1:-}" != "--no-sync" ]]; then
    echo "==> Install and start the brightness sync service"
    install -Dm 644 "systemd/$UNIT" "$UNIT_DIR/$UNIT"
    systemctl --user daemon-reload
    systemctl --user enable --now "$UNIT"
fi

echo
echo "Done. Test with: monitor"
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "Note: $BIN_DIR is not on your PATH." ;;
esac
