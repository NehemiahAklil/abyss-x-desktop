#!/usr/bin/env bash
##########################################
#   Abyss X — Linux Installer            #
#   Install / uninstall the AppImage     #
#                                         #
#   Usage:                               #
#     ./install_abyss_x.sh               #
#     then follow the on-screen menu     #
#     (Install / Uninstall).             #
#                                         #
#   Looks for the AppImage to install,   #
#   in order:                            #
#     1) next to this script             #
#     2) this script's ../dist/          #
#     3) the current directory           #
#   The first of those to contain a      #
#   match wins. Download the release     #
#   tarball, extract it, and run this    #
#   script from inside it, and it just   #
#   works with no extra flags.           #
##########################################

set -euo pipefail

APP_DISPLAY_NAME="Abyss X"
APP_ID="abyss-x-desktop"
BIN_FILENAME="AbyssX"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

USER_BIN_DIR="$HOME/.local/bin"
USER_ICON_BASE="$HOME/.local/share/icons/hicolor"
USER_APPS_DIR="$HOME/.local/share/applications"

SYS_BIN_DIR="/usr/local/bin"
SYS_ICON_BASE="/usr/share/icons/hicolor"
SYS_APPS_DIR="/usr/share/applications"

TMP_DIR=""
cleanup() { if [ -n "$TMP_DIR" ]; then rm -rf "$TMP_DIR"; fi; }
trap cleanup EXIT

banner() {
    echo "----------------------------------------------"
    echo "           $APP_DISPLAY_NAME Linux Installer"
    echo "----------------------------------------------"
}

USE_SUDO=0

run_priv() {
    if [ "$USE_SUDO" -eq 1 ] && [ "$(id -u)" -ne 0 ]; then
        command -v sudo >/dev/null 2>&1 || { echo "error: sudo is required for a system-wide install/uninstall" >&2; exit 1; }
        sudo "$@"
    else
        "$@"
    fi
}

# ---- locate the AppImage to install -------------------------------------

detect_host_arch() {
    case "$(uname -m)" in
        x86_64) echo "x64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) echo "unknown" ;;
    esac
}

find_appimage() {
    local candidates=()
    local dir
    # Priority order: next to this script, then this script's ../dist/ (the
    # electron-builder output dir when running from a source checkout), then
    # the current directory. The release tarball ships the AppImage already
    # renamed to $BIN_FILENAME (no .AppImage extension) sitting next to this
    # script, so that exact name is matched too. Stop at the first directory
    # that has any match — later directories are only consulted if it has none.
    for dir in "$SCRIPT_DIR" "$SCRIPT_DIR/../dist" "$PWD"; do
        [ -d "$dir" ] || continue
        while IFS= read -r -d '' f; do
            candidates+=("$f")
        done < <(find "$dir" -maxdepth 1 \( -iname "*.AppImage" -o -name "$BIN_FILENAME" \) -type f -print0 2>/dev/null)
        [ "${#candidates[@]}" -gt 0 ] && break
    done

    # de-duplicate while preserving order (defensive: a directory shouldn't
    # produce duplicate matches, but symlinks could)
    local unique=() c
    if [ "${#candidates[@]}" -gt 0 ]; then
        while IFS= read -r c; do
            unique+=("$c")
        done < <(printf '%s\n' "${candidates[@]}" | awk '!seen[$0]++')
    fi

    if [ "${#unique[@]}" -eq 1 ]; then
        APPIMAGE_PATH="${unique[0]}"
        return
    fi

    if [ "${#unique[@]}" -gt 1 ]; then
        local arch matched=()
        arch="$(detect_host_arch)"
        for c in "${unique[@]}"; do
            if [ "$arch" = "arm64" ]; then
                if [[ "$c" == *arm64* || "$c" == *aarch64* ]]; then
                    matched+=("$c")
                fi
            else
                if [[ "$c" != *arm64* && "$c" != *aarch64* ]]; then
                    matched+=("$c")
                fi
            fi
        done
        if [ "${#matched[@]}" -eq 1 ]; then
            APPIMAGE_PATH="${matched[0]}"
            return
        fi

        echo "Multiple AppImages found:"
        local i=1
        for c in "${unique[@]}"; do
            echo "  $i) $c"
            i=$((i + 1))
        done
        local choice
        read -r -p "Pick one [1-${#unique[@]}]: " choice
        APPIMAGE_PATH="${unique[$((choice - 1))]}"
        return
    fi

    read -e -r -p "Path to the $APP_DISPLAY_NAME AppImage: " APPIMAGE_PATH
}

# ---- pull the .desktop entry + icon out of the AppImage itself ----------

extract_metadata() {
    local appimage_abs
    appimage_abs="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"

    TMP_DIR="$(mktemp -d)"
    DESKTOP_SRC=""
    ICON_SRC=""
    ICON_RES="256x256"

    if ( cd "$TMP_DIR" && "$appimage_abs" --appimage-extract >/dev/null 2>&1 ); then
        DESKTOP_SRC="$(find "$TMP_DIR/squashfs-root" -maxdepth 1 -iname "*.desktop" | head -n1)"

        # index every hicolor PNG the AppImage ships, keyed by its resolution folder
        local -A icon_by_res=()
        local p res
        while IFS= read -r p; do
            res="$(echo "$p" | grep -oE '/[0-9]+x[0-9]+/apps/' | grep -oE '[0-9]+x[0-9]+' | head -n1)"
            [ -n "$res" ] && icon_by_res["$res"]="$p"
        done < <(find "$TMP_DIR/squashfs-root" -path "*/icons/hicolor/*/apps/*.png" 2>/dev/null)

        # the local hicolor theme only scans resolutions listed in its own
        # index.theme (e.g. many systems stop at 512x512, not 1024x1024) —
        # picking the AppImage's largest icon regardless of that list means
        # it silently fails to show up. Prefer the largest size both sides
        # agree on, largest first.
        local declared
        declared="$(grep -oE '^\[[0-9]+x[0-9]+/apps\]' /usr/share/icons/hicolor/index.theme 2>/dev/null \
            | grep -oE '[0-9]+x[0-9]+' | sort -t x -k1,1 -n -r)"
        if [ -n "$declared" ]; then
            while IFS= read -r res; do
                if [ -n "${icon_by_res[$res]+_}" ]; then
                    ICON_RES="$res"
                    ICON_SRC="${icon_by_res[$res]}"
                    break
                fi
            done <<< "$declared"
        fi

        # nothing matched a declared size (or index.theme unreadable) — fall
        # back to 256x256, which every hicolor theme in practice declares
        if [ -z "$ICON_SRC" ] && [ -n "${icon_by_res[256x256]+_}" ]; then
            ICON_RES="256x256"
            ICON_SRC="${icon_by_res[256x256]}"
        fi

        # last resort: whatever .DirIcon points at, even if unlisted
        if [ -z "$ICON_SRC" ] && [ -f "$TMP_DIR/squashfs-root/.DirIcon" ]; then
            ICON_SRC="$(readlink -f "$TMP_DIR/squashfs-root/.DirIcon")"
        fi
    fi
}

write_desktop_entry() {
    # $1 = installed AppImage path, $2 = destination .desktop path
    local exec_args
    exec_args="$(sed -n 's/^Exec=AppRun *//p' "$DESKTOP_SRC" | head -n1)"
    sed -e "s|^Exec=.*|Exec=\"$1\" $exec_args|" "$DESKTOP_SRC" > "$TMP_DIR/entry.desktop"
    run_priv install -m 644 "$TMP_DIR/entry.desktop" "$2"
}

refresh_caches() {
    local apps_dir="$1" icon_theme_root="$2"
    command -v update-desktop-database >/dev/null 2>&1 && run_priv update-desktop-database "$apps_dir" 2>/dev/null || true
    command -v gtk-update-icon-cache >/dev/null 2>&1 && run_priv gtk-update-icon-cache -q -f -t "$icon_theme_root" 2>/dev/null || true
}

# ---- install --------------------------------------------------------------

do_install() {
    find_appimage
    [ -f "$APPIMAGE_PATH" ] || { echo "error: '$APPIMAGE_PATH' not found" >&2; exit 1; }

    echo ""
    echo "Install for:"
    echo "  1) Just me          (recommended, no admin password)"
    echo "  2) All users        (requires sudo)"
    local scope
    read -r -p "Choice [1]: " scope
    scope="${scope:-1}"

    extract_metadata "$APPIMAGE_PATH"

    local bin_dir icon_base apps_dir
    if [ "$scope" = "2" ]; then
        bin_dir="$SYS_BIN_DIR"; icon_base="$SYS_ICON_BASE"; apps_dir="$SYS_APPS_DIR"
        USE_SUDO=1
    else
        bin_dir="$USER_BIN_DIR"; icon_base="$USER_ICON_BASE"; apps_dir="$USER_APPS_DIR"
        USE_SUDO=0
    fi
    local icon_dir="$icon_base/$ICON_RES/apps"

    echo ""
    run_priv mkdir -p "$bin_dir" "$icon_dir" "$apps_dir"

    local bin_path="$bin_dir/$BIN_FILENAME"
    run_priv rm -f "$bin_path"
    run_priv cp "$APPIMAGE_PATH" "$bin_path"
    run_priv chmod +x "$bin_path"
    echo "Copied App Executable ....... $bin_path"

    if [ -n "$ICON_SRC" ] && [ -n "$DESKTOP_SRC" ]; then
        # remove any icon left behind by a previous install at a different resolution
        if [ -d "$icon_base" ]; then
            run_priv find "$icon_base" -maxdepth 3 -type f -name "$APP_ID.png" -not -path "$icon_dir/$APP_ID.png" -delete
        fi
        run_priv cp "$ICON_SRC" "$icon_dir/$APP_ID.png"
        echo "Copied App Icon ............. $icon_dir/$APP_ID.png"

        write_desktop_entry "$bin_path" "$apps_dir/$APP_ID.desktop"
        echo "Created Desktop Entry ....... $apps_dir/$APP_ID.desktop"

        refresh_caches "$apps_dir" "$icon_base"
    else
        echo "warning: could not read icon/menu info from the AppImage — skipped menu integration" >&2
    fi

    echo "----------------------------------------------"
    echo "            Install complete"
    echo "----------------------------------------------"
    echo ""

    local launch
    read -r -p "Launch $APP_DISPLAY_NAME now? [y/N]: " launch
    if [[ "$launch" =~ ^[Yy]$ ]]; then
        nohup "$bin_path" --no-sandbox >/dev/null 2>&1 &
        disown
    fi
}

# ---- uninstall --------------------------------------------------------------

do_uninstall() {
    local found_user=0 found_sys=0
    if [ -f "$USER_BIN_DIR/$BIN_FILENAME" ]; then found_user=1; fi
    if [ -f "$SYS_BIN_DIR/$BIN_FILENAME" ]; then found_sys=1; fi

    if [ "$found_user" -eq 0 ] && [ "$found_sys" -eq 0 ]; then
        echo "$APP_DISPLAY_NAME does not appear to be installed."
        return
    fi

    local scope
    if [ "$found_user" -eq 1 ] && [ "$found_sys" -eq 1 ]; then
        echo ""
        echo "$APP_DISPLAY_NAME is installed for both this user and system-wide."
        echo "  1) Just me"
        echo "  2) All users     (requires sudo)"
        echo "  3) Both"
        read -r -p "Remove which? [3]: " scope
        scope="${scope:-3}"
    elif [ "$found_user" -eq 1 ]; then
        scope=1
    else
        scope=2
    fi

    local confirm
    read -r -p "This will remove $APP_DISPLAY_NAME. Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; return; }

    if [ "$scope" = "1" ] || [ "$scope" = "3" ]; then
        USE_SUDO=0
        run_priv rm -f "$USER_BIN_DIR/$BIN_FILENAME" "$USER_APPS_DIR/$APP_ID.desktop"
        if [ -d "$USER_ICON_BASE" ]; then
            run_priv find "$USER_ICON_BASE" -maxdepth 3 -type f -name "$APP_ID.png" -delete
        fi
        refresh_caches "$USER_APPS_DIR" "$USER_ICON_BASE"
        echo "Removed user install."
    fi
    if [ "$scope" = "2" ] || [ "$scope" = "3" ]; then
        USE_SUDO=1
        run_priv rm -f "$SYS_BIN_DIR/$BIN_FILENAME" "$SYS_APPS_DIR/$APP_ID.desktop"
        if [ -d "$SYS_ICON_BASE" ]; then
            run_priv find "$SYS_ICON_BASE" -maxdepth 3 -type f -name "$APP_ID.png" -delete
        fi
        refresh_caches "$SYS_APPS_DIR" "$SYS_ICON_BASE"
        echo "Removed system-wide install."
    fi

    echo "----------------------------------------------"
    echo "            Uninstall complete"
    echo "----------------------------------------------"
    echo ""
}

# ---- entry point ------------------------------------------------------------

banner
echo ""
echo "  1) Install"
echo "  2) Uninstall"
echo "  3) Exit"
read -r -p "Choice [1]: " action
action="${action:-1}"

case "$action" in
    1) do_install ;;
    2) do_uninstall ;;
    *) echo "Bye." ;;
esac
