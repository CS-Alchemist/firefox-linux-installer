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

ask_language() {
    echo "Select a Language."
    select _lang in "${LANGUAGE_LIST[@]}"; do
        language=$(echo $_lang | cut -d ':' -f 1)
        break
    done
}

prepare_debian() {
    apt install -y libc6 libgtk-3-common libdbus-glib-1-2 libglib2.0-0 libstdc++6 wget
}

prepare_common() {
    
    ask_language
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
prepare_common
install_firefox
set +e