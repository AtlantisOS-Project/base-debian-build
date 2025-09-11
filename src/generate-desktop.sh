#!/bin/bash
#
# generate-desktop.sh
#
# (C) Copyright 2025 AtlantisOS Project
# by @NachtsternBuild
#
# License: GNU GENERAL PUBLIC LICENSE Version 3
#
# genrating desktop files

generate_desktop_file() {
    local desktop_dir="$1"
    local pkg_name="$2"
    local exec="${3:-$pkg_name}"        # Default: Exec = PKG_NAME
    local icon="${4:-$pkg_name}"        # Default: Icon = PKG_NAME
    local comment="${5:-}"              # comment

    mkdir -p "$desktop_dir"

    local desktop_file="${desktop_dir}/${pkg_name}.desktop"

    cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$pkg_name
Comment=$comment
Exec=$exec
Icon=$icon
Terminal=false
Categories=Utility;
StartupNotify=true
EOF

    echo "[✓] Desktop file created: $desktop_file"
}

