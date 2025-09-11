#!/bin/bash
#
# generate-manpages.sh
#
# (C) Copyright 2025 AtlantisOS Project
# by @NachtsternBuild
#
# License: GNU GENERAL PUBLIC LICENSE Version 3
#
# genrating manpages

generate_manpages() {
    local debian_dir="$1"
    local pkg_name="$2"
    local man_dir="$3"

    echo "[INFO] Generating manpages..."
	
    for conf in $man_dir/man.*.conf; do
    	[[ -f "$conf" ]] || continue

        lang="${conf#atl_man.}"
        lang="${lang%.conf}"

        # define the output file
        if [[ "$lang" == "en" ]]; then
            man_out="${debian_dir}/${pkg_name}.1"
        else
            man_out="${debian_dir}/${pkg_name}.${lang}.1"
        fi

        echo "[INFO] $conf → $man_out"

        # read the config file
        source "$conf"

        {
            echo ".TH ${PKG_NAME} 1 \"${DATE}\" \"Version ${VERSION}\" \"${MANUAL}\""

            [[ -n "${SECTION_NAME:-}" ]] && {
                echo ".SH NAME"
                echo "${PKG_NAME} \\- ${SECTION_NAME}"
            }

            [[ -n "${SECTION_SYNOPSIS:-}" ]] && {
                echo ".SH SYNOPSIS"
                echo ".B ${SECTION_SYNOPSIS}"
            }

            [[ -n "${SECTION_DESCRIPTION:-}" ]] && {
                echo ".SH DESCRIPTION"
                echo "${SECTION_DESCRIPTION}"
            }

            [[ -n "${SECTION_FILES:-}" ]] && {
                echo ".SH FILES"
                printf "%b\n" "${SECTION_FILES}"
            }

            [[ -n "${SECTION_AUTHOR:-}" ]] && {
                echo ".SH AUTHOR"
                echo "${SECTION_AUTHOR}"
            }

            [[ -n "${SECTION_LICENSE:-}" ]] && {
                echo ".SH LICENSE"
                echo "${SECTION_LICENSE}"
            }
        } > "$man_out"
    done
}

