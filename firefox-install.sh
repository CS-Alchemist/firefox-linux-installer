#!/bin/bash
#################################################
#                                               #
# SPDX-License-Identifier: GPL-2.0-or-later     #
# Author: CS-Alchemist                          #
#                                               #
#################################################

error_handler() {
    echo "ERROR: execution of $0 failed"
    echo "returned $1 in line $2."
    exit 0
}
trap 'error_handler $? $LINENO' ERR

print_usage() {
    echo "Usage: $(basename $0) [language_code]"
    echo
    echo "Optional argument:"
    echo "  language_code    One of the supported language codes (e.g. 'de', 'en-US', 'fr', etc.)"
    echo
    echo "Options:"
    echo "  -h, --help       Show this help message and exit"
    echo
    echo "If no language_code is given, a language selection menu will be shown."
}

launch_in_terminal() {
    local terminal_cmd=""
    local script_path="$(readlink -f "$0")"

    for term in gnome-terminal x-terminal-emulator xterm konsole xfce4-terminal lxterminal tilix mate-terminal; do
        if command -v "$term" >/dev/null 2>&1; then
            terminal_cmd="$term"
            break
        fi
    done

    if [ -n "$terminal_cmd" ]; then
        "$terminal_cmd" -e "bash \"$script_path\""
        exit 0
    else
        echo "No supported terminal emulator found. Please run this script from a terminal." >&2
        exit 1
    fi
}

OS_ID="$(grep "^ID=" /etc/os-release | cut -d '=' -f 2)"
ARCH="$(uname -m)"
LANGUAGE_LIST=(
    "en-US: English (US) - English (US)"
    "de: German - Deutsch"
    "it: Italian - Italiano"
    "fr: French - Français"
    "el: Greek - Ελληνικά"
    "fi: Finnish - suomi"
    "pl: Polish - Polski"
    "pt-PT: Portuguese (Portugal) - Português (Europeu)"
    "ja: Japanese - 日本語"
    "ko: Korean - 한국어"
    "zh-CN: Chinese (Simplified) - 中文 (简体)"
    "zh-TW: Chinese (Traditional) - 正體中文 (繁體)"
    "es-ES: Spanish (Spain) - Español (de España)"
    "sv-SE: Swedish - Svenska"
    "tr: Turkish - Türkçe"
    "uK: Ukrainian - Українська"
)

get_language_from_arg() {
    local input="$1"
    for entry in "${LANGUAGE_LIST[@]}"; do
        lang_code=$(echo "$entry" | cut -d ':' -f 1)
        if [[ "$input" == "$lang_code" ]]; then
            language="$input"
            return 0
        fi
    done
    return 1
}

ask_language() {
    echo "Select a Language:"
    select _lang in "${LANGUAGE_LIST[@]}"; do
        language=$(echo $_lang | cut -d ':' -f 1)
        break
    done
}

prepare_debian() {
    apt install -y libc6 libgtk-3-common libdbus-glib-1-2 libglib2.0-0 libstdc++6 wget
}

prepare_common() {
    if ! get_language_from_arg "$1"; then
        ask_language
    fi

    groupadd -f -g 800 firefox

    if [[ "$ARCH" == "x86_64" ]]; then
        ARCH=64
    elif [[ "$ARCH" == "i686" ]]; then
        ARCH=""
    else
        echo "ARCH=$ARCH is not supported" >&2
        return 1
    fi

    if [[ "$OS_ID" == "debian" ]]; then
        prepare_debian
    fi

    return 0
}

install_firefox() {
    local URL_FIREFOX
    URL_FIREFOX="https://download.mozilla.org/?product=firefox-latest-ssl&os=linux$ARCH&lang=$language"

    wget $URL_FIREFOX -O /tmp/latest-firefox.tar.bz2
    tar -xf /tmp/latest-firefox.tar.bz2 -C /opt/
    rm /tmp/latest-firefox.tar.bz2
    ln -sf /opt/firefox/firefox /usr/local/bin/firefox > /dev/null
    wget "https://raw.githubusercontent.com/mozilla/sumo-kb/main/install-firefox-linux/firefox.desktop" \
            -P /usr/local/share/applications

    chown -R root:firefox /opt/firefox/
    chmod -R 775 /opt/firefox/
}

### MAIN ###

set -e

# Relaunch if not running in a terminal
if ! [ -t 0 ]; then
    launch_in_terminal
fi

# Check for --help or invalid arguments
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    print_usage
    exit 0
elif [[ -n "$1" && "$1" =~ ^- && "$1" != -*[a-zA-Z]* ]]; then
    echo "Unknown option: $1" >&2
    print_usage
    exit 1
fi

# Ensure the script is running as root
if [[ "$EUID" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
        echo "This script requires root privileges. Trying to elevate using sudo..."
        exec sudo "$0" "$@"
    else
        echo "This script must be run as root. Please run with sudo." >&2
        sleep 10
        exit 1
    fi
fi

prepare_common $1
install_firefox
set +e