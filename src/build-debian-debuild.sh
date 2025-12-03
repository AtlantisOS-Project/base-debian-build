#!/bin/bash
#
# build-deb-debuild.sh
#
# (C) Copyright 2025 AtlantisOS Project
# by @NachtsternBuild
#
# License: GNU GENERAL PUBLIC LICENSE Version 3
#
# universal debian package builder

set -euo pipefail

# get parameter for building deb
BUILD_PARAM=$1

# main dirs
home_dir="$HOME"
source_dir="$(pwd)"

# the config file
CONF_DIR="${source_dir}/config"
CONF_FILE="$CONF_DIR/package.conf"
CONF_FILE_UBUNTU="$CONF_DIR/package_ubuntu.conf"
GENERATE_MAN="${source_dir}/deb/generate-manpages.sh"
DESKTOP_DIR="${source_dir}/deb/desktop"
GENERATE_DESKTOP="${source_dir}/deb/generate-desktop.sh"

# load the config file
if [[ $BUILD_PARAM == "ubuntu" ]]; then
	if [[ ! -f "$CONF_FILE_UBUNTU" ]]; then
    	echo "[ERROR] Config file $CONF_FILE_UBUNTU not found!"
    	exit 1
	fi
	source "$CONF_FILE_UBUNTU"
else 
	if [[ ! -f "$CONF_FILE" ]]; then
    	echo "[ERROR] Config file $CONF_FILE not found!"
    	exit 1
	fi
	source "$CONF_FILE"
fi

# add the man file
source "$GENERATE_MAN"
# add desktop file
source "$GENERATE_DESKTOP"

# replace var in the templates
replace_vars() {
    local input="$1"
    local output="$2"

    cp "$input" "$output"

    # read from package.conf
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^# ]] && continue
        # replace @key@ with var from the config file
        sed -i "s|@$key@|$value|g" "$output"
    done < <(grep -v '^#' "$CONF_FILE")
}

# set date and the main debian dir
export LC_TIME=C
DATE=$(date --date='today' +"%a, %d %b %Y %H:%M:%S %z")
debian_dir="${source_dir}/debian"

# create the debian package structure
echo "[INFO] Create /debian structure..."
rm -rf "$debian_dir"
mkdir -p "$debian_dir/source"
echo "[INFO] Create /desktop structure..."
rm -rf "$DESKTOP_DIR"
mkdir -p "$DESKTOP_DIR"

# create .desktop file
generate_desktop_file "$DESKTOP_DIR" "$PKG_NAME" "$PKG_NAME" "$ICON_NAME" "$DESCRIPTION"


# create the control file
cat > "${debian_dir}/control" <<EOF
Source: $PKG_NAME
Section: $SECTION
Priority: $PRIORITY
Maintainer: $MAINTAINER
Build-Depends: $BUILD_DEPENDS
Standards-Version: 4.6.2
Homepage: $HOMEPAGE

Package: $PKG_NAME
Architecture: $ARCHITECTURE
Depends: $DEPENDS
Description: $DESCRIPTION
 $LONG_DESCRIPTION
EOF

if [[ $CHANGE_TYPE == "ubuntu" ]]; then
	# create the changelog file
	cat > "${debian_dir}/changelog" <<EOF
$PKG_NAME (${VERSION}ubuntu${PATCH}) $BRANCH; urgency=medium

  * $CONTENT

 -- $MAINTAINER  $DATE
EOF
else
	# create the changelog file
	cat > "${debian_dir}/changelog" <<EOF
$PKG_NAME (${VERSION}-{$PATCH}) $BRANCH; urgency=medium

  * $CONTENT

 -- $MAINTAINER  $DATE
EOF
fi

# create the copyright file
cat > "${debian_dir}/copyright" <<EOF
Copyright: $(date +%Y) $MAINTAINER_NAME

License: $LICENSE
EOF

# create the format file
echo "3.0 (native)" > "${debian_dir}/source/format"

# add manpages
generate_manpages "${debian_dir}" "$PKG_NAME" "$CONF_DIR"

# install file
if [[ -f "$CONF_DIR/debian.install.extra" ]]; then
    echo "[⧗] Using custom install rules..."
    replace_vars "$CONF_DIR/debian.install.extra" "${debian_dir}/install"
else
    echo "[⧗] No custom install file found, using default template..."
    # creating default template 
    cat > "$CONF_DIR/debian.install.default.in" <<'EOF'
build/@PKG_NAME@ usr/bin/
desktop/@DESKTOP_NAME@ usr/share/applications/
icons/@ICON_NAME@ usr/share/icons/hicolor/256x256/apps/
icons/@ICON_NAME@ usr/share/@PKG_NAME@/
build/po/en/LC_MESSAGES/@PKG_NAME@.mo /usr/share/locale/en/LC_MESSAGES/@PKG_NAME@.mo
build/po/de/LC_MESSAGES/@PKG_NAME@.mo /usr/share/locale/de/LC_MESSAGES/@PKG_NAME@.mo
debian/@PKG_NAME@.1 usr/share/man/man1/
debian/@PKG_NAME@.de.1 usr/share/man/de/man1/
EOF
    replace_vars "$CONF_DIR/debian.install.default.in" "${debian_dir}/install"
fi

# rules file
if [[ -f "$CONF_DIR/debian.rules.extra" ]]; then
    echo "[⧗] Using custom rules..."
    replace_vars "$CONF_DIR/debian.rules.extra" "${debian_dir}/rules"
else
    echo "[⧗] Using default rules template..."
    cat > "$CONF_DIR/debian.rules.default.in" <<'EOF'
#!/usr/bin/make -f

%:
	dh $@

override_dh_auto_build:
	export CCACHE_DISABLE=1
	rm -rf build
	mkdir -p build
	cp -r po/* build/po
	$(MAKE) -C build
	$(MAKE) mo-all
EOF
    replace_vars "$CONF_DIR/debian.rules.default.in" "${debian_dir}/rules"
fi

chmod +x "${debian_dir}/rules"
