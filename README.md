# displaylink-ddc

Control an external monitor over DDC/CI when it is connected through a
**DisplayLink dock** on Linux. Brightness, contrast, colour, input and power,
plus an optional service that makes the monitor follow your laptop
brightness keys.

## Why

`ddcutil` does not work on most DisplayLink docks. The `evdi` driver
(1.14 and later) does create an I2C bus named `DisplayLink I2C Adapter`, and
DDC/CI commands pass through it. But the EDID read on that bus fails, so
`ddcutil` reports "No monitor detected" and stops before it sends any DDC
command.

This tool skips the EDID step. It talks DDC/CI directly to address `0x37`
on the DisplayLink bus.

## Requirements

- Linux with the DisplayLink driver (`evdi` 1.14 or later)
- DDC/CI turned on in the monitor menu
- Python 3 (standard library only)
- GNOME, for the brightness sync service only

Tested on Ubuntu with GNOME 46, `evdi` 1.14.15, a Lenovo ThinkPad Hybrid
USB-C dock and a Samsung monitor.

## Install

```bash
git clone https://github.com/RickyMillar/displaylink-ddc.git
cd displaylink-ddc
./install.sh            # or ./install.sh --no-sync for the command only
```

The installer:

1. loads the `i2c-dev` kernel module now and at boot
2. adds a udev rule that gives the logged-in user access to the DisplayLink
   I2C bus (with the `uaccess` tag, so you do not need to log out)
3. copies `monitor` and `monitor-brightness-sync` to `~/.local/bin`
4. enables the `monitor-brightness-sync` systemd user service

Remove everything with `./uninstall.sh`.

## Usage

```text
monitor                       show brightness, contrast, RGB gain
monitor brightness 60         set an absolute value
monitor brightness +10        relative change, clamped to 0..max
monitor contrast|red|green|blue [VALUE]
monitor preset [6500k|9300k|user1|user2]
monitor mode [standard|mixed|movie|games]
monitor input [dp1|dp2|hdmi]
monitor power [on|standby|off]
monitor caps                  show the capabilities string of the monitor
```

The named values for `preset`, `mode` and `input` come from one Samsung
monitor. Other monitors can use other values. Run `monitor caps` and look at
the values in brackets after each code, for example `60( 12 0F 10)`. You can
always give a raw value, for example `monitor input 0x11`.

> **Caution:** Before you change the input, make sure that you can get back
> to the dock input with the monitor buttons.

## Brightness sync

`monitor-brightness-sync` listens for changes to the GNOME screen brightness
(`org.gnome.SettingsDaemon.Power.Screen.Brightness` on D-Bus). It sets the
external monitor to the same percentage. It waits 0.15 s after the last
change, so one held key press gives one DDC write.

```bash
systemctl --user status monitor-brightness-sync
systemctl --user disable --now monitor-brightness-sync   # turn it off
```

The sync is one-way. A change with the monitor buttons stays until the next
laptop brightness change.

## Troubleshooting

| Symptom | Check |
|---------|-------|
| `no 'DisplayLink I2C Adapter' bus found` | Is the dock connected? Is `evdi` 1.14 or later? Run `cat /sys/bus/i2c/devices/i2c-*/name`. |
| `Permission denied` | Run `getfacl /dev/i2c-N` for the DisplayLink bus. Your user must be in the list. If not, run `./install.sh` again. |
| `no valid reply for feature 0x..` | The monitor does not support that feature (see `monitor caps`), or DDC/CI is off in the monitor menu. |

## License

MIT
