# Wallpaper Scripts

A collection of wallpaper management scripts for Hyprland with Waybar integration.

## Features

- **Dynamic Wallpaper Rotation**: Automatically cycles wallpapers at configurable intervals
- **Manual Wallpaper Cycling**: Click the Waybar module to change wallpaper immediately
- **Theme-Aware**: Integrates with Omarchy theme system
- **Multiple Sources**: Supports wallpapers from theme backgrounds, user directories, and custom paths

## Scripts

### `dynamic-wallpaper.sh`

Rotates wallpapers automatically at a configurable interval (default: 5 minutes).

**Usage:**
```bash
./dynamic-wallpaper.sh [interval_seconds]
```

**Example:**
```bash
# Rotate every 10 minutes
./dynamic-wallpaper.sh 600

# Rotate every 30 minutes
./dynamic-wallpaper.sh 1800
```

### `wallpaper-next.sh`

Manually cycles to the next wallpaper. Integrates with Waybar for one-click changes.

**Usage:**
```bash
./wallpaper-next.sh
```

## Installation

### Option 1: Automated Install (Recommended)

```bash
./install.sh
```

### Option 2: Manual Installation

1. Copy scripts to your config directory:
```bash
mkdir -p ~/.config/waybar/scripts
cp scripts/dynamic-wallpaper.sh ~/.local/share/omarchy/scripts/
cp scripts/wallpaper-next.sh ~/.config/waybar/scripts/

# Make executable
chmod +x ~/.local/share/omarchy/scripts/dynamic-wallpaper.sh
chmod +x ~/.config/waybar/scripts/wallpaper-next.sh
```

2. Add to Hyprland autostart (`~/.config/hypr/autostart.conf`):
```
exec-once = bash -lc '~/.local/share/omarchy/scripts/dynamic-wallpaper.sh 300 >/dev/null 2>&1 &'
```

3. Add Waybar module (`~/.config/waybar/config.jsonc`):
```jsonc
"custom/wallpaper": {
    "format": "󰸉",
    "on-click": "~/.config/waybar/scripts/wallpaper-next.sh",
    "tooltip-format": "Change Wallpaper\n\nClick to cycle to next wallpaper"
}
```

4. Add Waybar styling (`~/.config/waybar/style.css`):
```css
#custom-wallpaper {
    /* Keep it generic so it matches Omarchy's default module styling */
    padding: 0 6px;
    min-width: 16px;
}
```

## Configuration

### Wallpaper Directories

The scripts search for wallpapers in this order:
1. Current theme backgrounds: `~/.config/omarchy/current/theme/backgrounds`
2. Theme-specific backgrounds: `~/.config/omarchy/backgrounds/<theme_name>`
3. User wallpapers: `~/.Pictures/Wallpapers`
4. Legacy path: `~/Picture/Wallpapers`

### Adding Your Own Wallpapers

Create a directory with your wallpapers and either:
- Copy it to `~/.Pictures/Wallpapers`
- Symlink it to `~/.config/omarchy/backgrounds/<your-theme>`

## Dependencies

- `swaybg` or equivalent wallpaper setter
- `flock` (for locking mechanism)
- Omarchy's `omarchy-theme-bg-set` binary (for dynamic rotation)

## License

MIT
