#!/bin/bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMARCHY_SCRIPTS_DIR="$HOME/.local/share/omarchy/scripts"
WAYBAR_SCRIPTS_DIR="$HOME/.config/waybar/scripts"
AUTOSTART_FILE="$HOME/.config/hypr/autostart.conf"
WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"

log() {
    printf '[install] %s\n' "$*"
}

err() {
    printf '[error] %s\n' "$*" >&2
}

check_file() {
    [[ -f "$1" ]]
}

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
        log "backed up $file"
    fi
}

install_omarchy_script() {
    local src="$SCRIPT_DIR/scripts/dynamic-wallpaper.sh"
    if [[ ! -f "$src" ]]; then
        err "source script not found: $src"
        return 1
    fi

    mkdir -p "$OMARCHY_SCRIPTS_DIR"
    cp "$src" "$OMARCHY_SCRIPTS_DIR/"
    chmod +x "$OMARCHY_SCRIPTS_DIR/dynamic-wallpaper.sh"
    log "installed dynamic-wallpaper.sh to $OMARCHY_SCRIPTS_DIR"
}

install_waybar_script() {
    local src="$SCRIPT_DIR/scripts/wallpaper-next.sh"
    if [[ ! -f "$src" ]]; then
        err "source script not found: $src"
        return 1
    fi

    mkdir -p "$WAYBAR_SCRIPTS_DIR"
    cp "$src" "$WAYBAR_SCRIPTS_DIR/"
    chmod +x "$WAYBAR_SCRIPTS_DIR/wallpaper-next.sh"
    log "installed wallpaper-next.sh to $WAYBAR_SCRIPTS_DIR"
}

install_autostart() {
    local marker="# dynamic-wallpaper"

    if [[ ! -f "$AUTOSTART_FILE" ]]; then
        mkdir -p "$(dirname "$AUTOSTART_FILE")"
        touch "$AUTOSTART_FILE"
        log "created new autostart.conf"
    fi

    if grep -q "$marker" "$AUTOSTART_FILE" 2>/dev/null; then
        log "dynamic-wallpaper already in autostart.conf, skipping"
        return 0
    fi

    backup_file "$AUTOSTART_FILE"
    echo "" >> "$AUTOSTART_FILE"
    echo "exec-once = bash -lc '~/.local/share/omarchy/scripts/dynamic-wallpaper.sh 300 >/dev/null 2>&1 &'" >> "$AUTOSTART_FILE"
    log "added dynamic-wallpaper to autostart.conf"
}

install_waybar_config() {
    local marker="custom/wallpaper"

    if [[ ! -f "$WAYBAR_CONFIG" ]]; then
        err "waybar config not found, skipping module installation"
        return 1
    fi

    if grep -q "$marker" "$WAYBAR_CONFIG" 2>/dev/null; then
        log "wallpaper module already in waybar config, skipping"
        return 0
    fi

    log "please add wallpaper module to waybar config manually"
    log "add this to your modules center section:"
    echo '    "custom/wallpaper": {'
    echo '        "format": "󰸉",'
    echo '        "on-click": "~/.config/waybar/scripts/wallpaper-next.sh",'
    echo '        "tooltip-format": "Change Wallpaper\n\nClick to cycle to next wallpaper"'
    echo '    }'
}

install_waybar_style() {
    local marker="custom-wallpaper"

    if [[ ! -f "$WAYBAR_STYLE" ]]; then
        err "waybar style not found, skipping"
        return 1
    fi

    if grep -q "$marker" "$WAYBAR_STYLE" 2>/dev/null; then
        log "wallpaper style already in waybar style.css, skipping"
        return 0
    fi

    backup_file "$WAYBAR_STYLE"
    echo "" >> "$WAYBAR_STYLE"
    echo "#custom-wallpaper {" >> "$WAYBAR_STYLE"
    echo "    color: @accent;" >> "$WAYBAR_STYLE"
    echo "    border: 1px solid @accent;" >> "$WAYBAR_STYLE"
    echo "    border-radius: 4px;" >> "$WAYBAR_STYLE"
    echo "    padding: 0 8px;" >> "$WAYBAR_STYLE"
    echo "}" >> "$WAYBAR_STYLE"
    log "added wallpaper styling to waybar style.css"
}

main() {
    log "starting wallpaper-scripts installation"

    install_omarchy_script || err "failed to install omarchy script"
    install_waybar_script || err "failed to install waybar script"
    install_autostart || err "failed to install autostart"
    install_waybar_config || true
    install_waybar_style || err "failed to install waybar style"

    log "installation complete"
    log "restart waybar or run 'hyprctl reload' to apply changes"
}

main
