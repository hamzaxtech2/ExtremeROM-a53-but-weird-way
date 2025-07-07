#!/usr/bin/env bash
#
# Copyright (C) 2023 Salvo Giangreco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# shellcheck disable=SC2162

set -e

# [
GET_LATEST_FIRMWARE()
{
    curl -s --retry 5 --retry-delay 5 "https://dl.samfwpremium.cloud/d258e65fd3ddfa569d8f2ac69f1864eePFrPM_A_GYgmmIt9d1Z2tAo5MDPf3Ya6E8XWBClRdwUKkS-cxowIBhxf6PAucXwr6CP86_GezBz7Rr_cyGbRcqYvCTm8uksrL_0pRSbVGl9EyLoJRhi3Am9VcpdRb2mnSgGRu_dImSOuEtVzbuhIO4ZXQzQz_6dalYAil26R_6KWrRPXxILN5TYwGAzrMhCRIn276wY8aIjxHpN2ievwO13Tdx6FJuFeVsF5odw2zRIyVHpwvQ3pp_PYg6WDpbCgT157cDrET5U8_U8PhChqyLh3QqS6D3ndqFeIENukUAoBekpN8Us5kc7dLO1UnUqGShySanzMO30vs3QbORcwWiulQQJBZayO0dmuQbzqGK6H4tY_29pCUclIYqx_ahuvHx-HWeV_gEcmnTYybzJTMhH7lCZ9u515LwSTMQ0WqO_I1d2I1oIbIWdLpH3Z9NBTnlrSjxmpXFX4XNI2KHb43RVA6AbxquA8KIoJS06XGSuqYPs0iSP0tjv0-WL2ur_QUpfEMJMrm8qpFK-I1klcABqg7N2gBNzsKViZpdhPieWSv1mKeZQF8G5eM8O4TDZt6Rj05RKb-zAgHZpRCjSeXcnNsmJm8JdUvf71i91d9xNlUFKB50WXsF3IZ6UFVCywerc3_xAwHxpMqtTpzy_s3r6bi-Aj7K92eFFdMMM4lViHTvE-bjxgCd8yGaJxbHfSRtzcLFVcYFxoHu_IpSFbO2QQ_6NQPRz8bhHkhiHJPjoCsaOCwcIrfktIVbMANdgjlwPC0jpSpYHpftpEuvcJMlIjSfxpeTrRKdI3d0elCFbE9N5cgnk4eJ9n6i0BaImUX2IHudWG-AipJsfME5xQsvFGmgHheSGbHvRapH2Eir01ww7-wGRaDMxhNEPZrqTJnAk3RUPw8ioibv7KAn0usl8XYJRhzWlgNP7qnhIMNm1bV4vAjn4k0-6qgVDtxwDik_BGLt7k97tFs1m_-9JpIEsL8ZKsV-nMzBzeFAYjjqcwwD0qdBG_vVsmZE3NNpyVTRxmmY4YHpSh_pdiREB7ZJ0VpF-ANiuNe3He9crn-u9sSKsliSpVtSWJx4kOf1gvLVHBrNmFNxxS6-LC1K9O-A?file_name=SAMFW.COM_SM-A536E_XME_A536EXXSEEYD9_fac.zip" \
        | grep latest | sed 's/^[^>]*>//' | sed 's/<.*//'
}

DOWNLOAD_FIRMWARE()
{
    local PDR
    PDR="$(pwd)"

    cd "$ODIN_DIR"
    { samfirm -m "$MODEL" -r "$REGION" -i "$IMEI" > /dev/null; } 2>&1 \
        && touch "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" \
        || exit 1
    [ -f "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" ] && {
        echo -n "$(find "$ODIN_DIR/${MODEL}_${REGION}" -name "AP*" -exec basename {} \; | cut -d "_" -f 2)/"
        echo -n "$(find "$ODIN_DIR/${MODEL}_${REGION}" -name "CSC*" -exec basename {} \; | cut -d "_" -f 3)/"
        echo -n "$(find "$ODIN_DIR/${MODEL}_${REGION}" -name "CP*" -exec basename {} \; | cut -d "_" -f 2)"
    } >> "$ODIN_DIR/${MODEL}_${REGION}/.downloaded"

    echo ""
    cd "$PDR"
}

FIRMWARES=( "$SOURCE_FIRMWARE" "$TARGET_FIRMWARE" )
IFS=':' read -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"
if [ "${#SOURCE_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
    for i in "${SOURCE_EXTRA_FIRMWARES[@]}"
    do
        FIRMWARES+=( "$i" )
    done
fi
IFS=':' read -a TARGET_EXTRA_FIRMWARES <<< "$TARGET_EXTRA_FIRMWARES"
if [ "${#TARGET_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
    for i in "${TARGET_EXTRA_FIRMWARES[@]}"
    do
        FIRMWARES+=( "$i" )
    done
fi
# ]

FORCE=false

while [ "$#" != 0 ]; do
    case "$1" in
        "-f" | "--force")
            FORCE=true
            ;;
        *)
            echo "Usage: download_fw [options]"
            echo " -f, --force : Force firmware download"
            exit 1
            ;;
    esac

    shift
done

mkdir -p "$ODIN_DIR"

for i in "${FIRMWARES[@]}"
do
    MODEL=$(echo -n "$i" | cut -d "/" -f 1)
    REGION=$(echo -n "$i" | cut -d "/" -f 2)
    IMEI=$(echo -n "$i" | cut -d "/" -f 3)

    if [ -f "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" ]; then
        [ -z "$(GET_LATEST_FIRMWARE)" ] && continue
        if [[ "$(GET_LATEST_FIRMWARE)" != "$(cat "$ODIN_DIR/${MODEL}_${REGION}/.downloaded")" ]]; then
            if $FORCE; then
                echo "- Updating $MODEL firmware with $REGION CSC..."
                rm -rf "$ODIN_DIR/${MODEL}_${REGION}" && DOWNLOAD_FIRMWARE
            else
                echo    "- $MODEL firmware with $REGION CSC already downloaded"
                echo    "  A newer version of this device's firmware is available."
                echo -e "  To download, clean your Odin firmwares directory or run this cmd with \"--force\"\n"
                continue
            fi
        else
            echo -e "- $MODEL firmware with $REGION CSC already downloaded\n"
            continue
        fi
    else
        echo "- Downloading $MODEL firmware with $REGION CSC..."
        rm -rf "$ODIN_DIR/${MODEL}_${REGION}" && DOWNLOAD_FIRMWARE
    fi
done

exit 0
