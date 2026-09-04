# Keyboard Backlight for Omarchy on Apple Silicon

An [Omarchy](https://omarchy.org) shell plugin that makes the keyboard backlight behave the way it does under macOS:

- **Only in the dark.** The ambient light sensor (`aop-sensors-als`, exposed by the Asahi kernel through IIO) decides whether the keys light up. Above the bright threshold they stay off.
- **Off when idle.** Ten seconds without a key press or trackpad touch turns the keys off. The first touch brings them back.
- **Your level wins.** Changing the brightness with the Touch Bar, `Shift + F1/F2`, or `omarchy brightness keyboard` becomes the new preferred level. Setting it to zero keeps it off until you raise it again.

The policy lives in one bash script, `bin/omarchy-keyboard-backlight`; the QML service only feeds it idle events from the compositor and a two-second tick.

## Install

```bash
git clone https://github.com/DataKnox/omarchy-keyboard-backlight ~/.config/omarchy/plugins/io.github.dataknox.keyboard-backlight
omarchy plugin enable io.github.dataknox.keyboard-backlight
```

Or `omarchy plugin add https://github.com/DataKnox/omarchy-keyboard-backlight --enable`.

On hardware without an ambient light sensor or `kbd_backlight` LED the service logs one line and does nothing.

## Remove

```bash
omarchy plugin remove io.github.dataknox.keyboard-backlight
rm -rf ~/.local/state/omarchy/keyboard-backlight ~/.config/omarchy/keyboard-backlight.conf
```

The keyboard backlight keeps whatever level it had when the plugin was removed; adjust it with the brightness keys as usual.

## Dependencies

Everything used is already part of an Omarchy install:

- `brightnessctl` to write the LED level (Omarchy's own `omarchy brightness keyboard` uses it too)
- Quickshell's `IdleMonitor`, provided by the Omarchy shell
- An ambient light sensor exposed through IIO with `als` in its name. On Apple Silicon MacBooks that is `aop-sensors-als` from the Asahi kernel; no extra driver or package is needed.

The plugin needs no sudo and touches no system files. It writes only its own state under `~/.local/state/omarchy/keyboard-backlight/` and reads the optional config file above.

## Settings

`~/.config/omarchy/keyboard-backlight.conf` (all optional):

```bash
DARK_LUX=40        # keys come on below this
BRIGHT_LUX=80      # keys go off above this (hysteresis)
DEFAULT_LEVEL=100  # 0-255, until you set a level yourself
IDLE_SECONDS=10    # off after this much inactivity
POLL_SECONDS=2
```

`omarchy-keyboard-backlight status` prints the live lux reading and state, which is the easiest way to pick thresholds for your room.

## Without the shell plugin

`bin/omarchy-keyboard-backlight daemon` runs the ambient loop on its own, and any idle daemon (hypridle, swayidle) can call `idle` / `active` on timeout and resume.

## License

MIT
