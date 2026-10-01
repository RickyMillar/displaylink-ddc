#!/usr/bin/env bash
# Remove displaylink-ddc. The i2c-dev module config stays, because other tools use it.
set -euo pipefail

UNIT=monitor-brightness-sync.service

systemctl --user disable --now "$UNIT" 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/$UNIT"
systemctl --user daemon-reload

rm -f "$HOME/.local/bin/monitor" "$HOME/.local/bin/monitor-brightness-sync"

sudo rm -f /etc/udev/rules.d/61-displaylink-ddc.rules
sudo udevadm control --reload

echo "Removed. To also stop loading i2c-dev at boot: sudo rm /etc/modules-load.d/i2c-dev.conf"
