#!/bin/bash
# Omarchy Dynamic Wallpaper Script
# Rotates wallpapers using Omarchy's native swaybg flow.

set -u

CURRENT_THEME_NAME_FILE="$HOME/.config/omarchy/current/theme.name"
CURRENT_THEME_DIR="$HOME/.config/omarchy/current/theme"
CURRENT_BACKGROUND_LINK="$HOME/.config/omarchy/current/background"
USER_WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
LEGACY_USER_WALLPAPERS_DIR="$HOME/Picture/Wallpapers"
INTERVAL="${1:-300}"
LOCK_FILE="$HOME/.cache/omarchy/dynamic-wallpaper.lock"
LOG_FILE="$HOME/.cache/omarchy/dynamic-wallpaper.log"
LAST_CHANGE_FILE="$HOME/.cache/omarchy/last-wallpaper-change"
OMARCHY_SET_BIN="${OMARCHY_SET_BIN:-$HOME/.local/share/omarchy/bin/omarchy-theme-bg-set}"

mkdir -p "$(dirname "$LOCK_FILE")"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "dynamic-wallpaper: another instance is already running" >> "$LOG_FILE"
    exit 0
fi

log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$LOG_FILE"
}

touch_last_change() {
    date +%s > "$LAST_CHANGE_FILE"
}

get_last_change() {
    local last_change=""

    if [[ -f "$LAST_CHANGE_FILE" ]]; then
        read -r last_change < "$LAST_CHANGE_FILE" || true
    fi

    if [[ "$last_change" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "$last_change"
    else
        printf '0\n'
    fi
}

sleep_until_next_rotation() {
    local now last_change elapsed remaining

    while true; do
        now=$(date +%s)
        last_change=$(get_last_change)

        if (( last_change <= 0 )); then
            return 0
        fi

        elapsed=$(( now - last_change ))
        remaining=$(( INTERVAL - elapsed ))

        if (( remaining <= 0 )); then
            return 0
        fi

        sleep "$remaining"
    done
}

get_current_theme_name() {
    [[ -f "$CURRENT_THEME_NAME_FILE" ]] && cat "$CURRENT_THEME_NAME_FILE"
}

load_wallpapers() {
    local theme_name
    local wallpaper_dirs=(
        "$CURRENT_THEME_DIR/backgrounds"
        "$HOME/.config/omarchy/backgrounds/$(get_current_theme_name)"
        "$USER_WALLPAPERS_DIR"
        "$LEGACY_USER_WALLPAPERS_DIR"
    )

    mapfile -d '' -t WALLPAPERS < <(
        find -L "${wallpaper_dirs[@]}" -maxdepth 1 -type f \
            \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) \
            -print0 2>/dev/null | sort -z
    )
}

set_next_wallpaper() {
    local current_background="" current_resolved="" new_background="" candidate=""
    local -a candidates=()

    if [[ -L "$CURRENT_BACKGROUND_LINK" ]]; then
        current_background="$(readlink "$CURRENT_BACKGROUND_LINK")"
        current_resolved="$(readlink -f "$CURRENT_BACKGROUND_LINK" 2>/dev/null || true)"
    fi

    if (( ${#WALLPAPERS[@]} > 1 )); then
        for candidate in "${WALLPAPERS[@]}"; do
            if [[ "$candidate" != "$current_background" && "$(readlink -f "$candidate" 2>/dev/null || true)" != "$current_resolved" ]]; then
                candidates+=("$candidate")
            fi
        done
    fi

    if (( ${#candidates[@]} > 0 )); then
        new_background="${candidates[RANDOM % ${#candidates[@]}]}"
    else
        new_background="${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"
    fi

    if ( exec 9>&-; "$OMARCHY_SET_BIN" "$new_background" ); then
        touch_last_change
        log "wallpaper set to $(basename "$new_background")"
    else
        log "failed to set wallpaper to $new_background"
    fi
}

if [[ ! -x "$OMARCHY_SET_BIN" ]]; then
    log "missing executable: $OMARCHY_SET_BIN"
    exit 1
fi

CURRENT_THEME_NAME="$(get_current_theme_name)"
load_wallpapers

if (( ${#WALLPAPERS[@]} == 0 )); then
    log "no wallpapers found in configured wallpaper directories"
    exit 1
fi

touch_last_change
log "starting wallpaper rotation for theme '${CURRENT_THEME_NAME:-unknown}' every ${INTERVAL}s"

while true; do
    sleep_until_next_rotation

    NEW_THEME_NAME="$(get_current_theme_name)"
    if [[ "$NEW_THEME_NAME" != "$CURRENT_THEME_NAME" ]]; then
        CURRENT_THEME_NAME="$NEW_THEME_NAME"
        load_wallpapers
        log "theme changed to '${CURRENT_THEME_NAME:-unknown}', reloaded ${#WALLPAPERS[@]} wallpapers"
    fi

    if (( ${#WALLPAPERS[@]} == 0 )); then
        log "no wallpapers found in configured wallpaper directories"
        sleep "$INTERVAL"
        continue
    fi

    set_next_wallpaper
done
