#!/usr/bin/env bash

# Refined from the banner in lumen-rsg/init_setup at commit
# 5a43afb6cf9c9bfaad2deeda1bba4868fb22ca21. This file intentionally contains
# presentation only: it never launches first-boot setup or modifies the system.

[[ $- == *i* ]] || return
shopt -q login_shell || return
[[ -t 1 ]] || return
[[ -z "${LUMINA_BANNER_SHOWN:-}" ]] || return
export LUMINA_BANNER_SHOWN=1

lumina_zero3_banner()
{
    local distro_name="1T Lumina"
    local distro_version="26.08"
    local board="Orange Pi Zero 3"
    local load="n/a"
    local uptime_value="n/a"
    local memory="n/a"
    local address="offline"
    local temperature="n/a"
    local disk="n/a"
    local columns=80
    local value
    local index
    local -a colors=(
        '38;2;0;255;255' '38;2;0;230;255' '38;2;0;200;255'
        '38;2;50;160;255' '38;2;100;110;255' '38;2;150;60;255'
        '38;2;190;30;255' '38;2;220;0;245' '38;2;255;0;220'
        '38;2;255;0;190' '38;2;255;0;165' '38;2;255;0;140'
    )
    local -a logo_compact=(
        "           .,ok;      'lkc"
        "        .,o0NMNc   'lONMWd"
        "      ..dNMMMMNc..lNMMMMWd"
        "   'lOd:OMMMMMNc.,xMMMMMWd  .;dOc"
        " ;ONMMk:OMMMMMNc.'xMMMMMWo.l0WMWl"
        ".xMMMMk:OMMMMMNc.,xMMMMMWd;0MMMNl"
        ".xMWKx,,OMMMMMNc.,xMMMMMWd;0MN0o."
        " cd:.  .OMMMMMNc.,xMMMMMWd,oo,."
        "       .OMMMMMNc.,xMMMMMWo."
        "       .OMMMMMNc.,xMMMMMWo"
        "       .OMWXx:. .,xMWXkc."
        "       .dkc.    ..lkl'"
    )
    local -a logo_wide=(
        "           .,ok;      'lkc"
        "        .,o0NMNc   'lONMWd"
        "      ..dNMMMMNc..lNMMMMWd"
        "   'lOd:OMMMMMNc.,xMMMMMWd  .;dOc    _ _____    _     _  _      _    ___  _"
        " ;ONMMk:OMMMMMNc.'xMMMMMWo.l0WMWl   / Y__ __\\  / \\   / \\/ \\  /|/ \\ /\\  \\//"
        ".xMMMMk:OMMMMMNc.,xMMMMMWd;0MMMNl   | | / \\    | |   | || |\\ ||| | || \\  /"
        ".xMWKx,,OMMMMMNc.,xMMMMMWd;0MN0o.   | | | |    | |_/\\| || | \\||| \\_/| /  \\"
        " cd:.  .OMMMMMNc.,xMMMMMWd,oo,.     \\_/ \\_/    \\____/\\_/\\_/  \\|\\____//__/\\"
        "       .OMMMMMNc.,xMMMMMWo."
        "       .OMMMMMNc.,xMMMMMWo"
        "       .OMWXx:. .,xMWXkc."
        "       .dkc.    ..lkl'"
    )
    local -a logo=()
    local reset=$'\033[0m'
    local border=$'\033[38;2;100;100;255m'
    local label=$'\033[1;37m'
    local data=$'\033[1;36m'
    local command=$'\033[1;32m'

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        distro_name="${NAME:-${distro_name}}"
        distro_version="${VERSION_ID:-${distro_version}}"
    fi
    if [[ -r /sys/firmware/devicetree/base/model ]]; then
        board="$(tr -d '\0' </sys/firmware/devicetree/base/model | cut -c1-40)"
    fi
    read -r load _ </proc/loadavg || true
    uptime_value="$(uptime -p 2>/dev/null | sed 's/^up //' || true)"
    memory="$(awk '
        /^MemTotal:/ { total=$2 }
        /^MemAvailable:/ { available=$2 }
        END {
            if (total > 0)
                printf "%.0f%% of %.0f MiB", 100 * (total - available) / total, total / 1024
        }
    ' /proc/meminfo)"
    value="$(ip -brief -4 address show scope global 2>/dev/null |
        awk 'NR == 1 { print $3 }')"
    [[ -z "${value}" ]] || address="${value}"
    value="$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || true)"
    if [[ "${value}" =~ ^[0-9]+$ ]]; then
        temperature="$(awk -v value="${value}" 'BEGIN { printf "%.1f C", value / 1000 }')"
    fi
    disk="$(df -hP / 2>/dev/null | awk 'NR == 2 { print $5 " of " $2 }')"
    value="$(tput cols 2>/dev/null || true)"
    [[ "${value}" =~ ^[0-9]+$ ]] && columns="${value}"
    if (( columns >= 92 )); then
        logo=("${logo_wide[@]}")
    else
        logo=("${logo_compact[@]}")
    fi

    printf '\n'
    for index in "${!logo[@]}"; do
        printf '\033[%sm  %s%s\n' "${colors[index]}" "${logo[index]}" "${reset}"
    done
    printf '\n  %bWelcome to %b%s %s%b on %b%s%b\n\n' \
        "${label}" "${data}" "${distro_name}" "${distro_version}" \
        "${label}" "${data}" "${board}" "${reset}"

    if (( columns >= 92 )); then
        printf '  %b╭──────────────────────────────────────────┬──────────────────────────────────────────╮%b\n' "${border}" "${reset}"
        printf '  %b│ %b%-13s %b%-26s %b│ %b%-13s %b%-26s %b│%b\n' \
            "${border}" "${label}" 'Load average:' "${data}" "${load}" \
            "${border}" "${label}" 'Up time:' "${data}" "${uptime_value}" "${border}" "${reset}"
        printf '  %b│ %b%-13s %b%-26s %b│ %b%-13s %b%-26s %b│%b\n' \
            "${border}" "${label}" 'Memory usage:' "${data}" "${memory}" \
            "${border}" "${label}" 'IP:' "${data}" "${address}" "${border}" "${reset}"
        printf '  %b│ %b%-13s %b%-26s %b│ %b%-13s %b%-26s %b│%b\n' \
            "${border}" "${label}" 'CPU temp:' "${data}" "${temperature}" \
            "${border}" "${label}" 'Usage of /:' "${data}" "${disk}" "${border}" "${reset}"
        printf '  %b╰──────────────────────────────────────────┴──────────────────────────────────────────╯%b\n' "${border}" "${reset}"
    else
        printf '  %b╭──────────────────────────────────────────────────────────────╮%b\n' "${border}" "${reset}"
        printf '  %b│ %b%-14s %b%-45s %b│%b\n' "${border}" "${label}" 'Load average:' "${data}" "${load}" "${border}" "${reset}"
        printf '  %b│ %b%-14s %b%-45s %b│%b\n' "${border}" "${label}" 'Up time:' "${data}" "${uptime_value}" "${border}" "${reset}"
        printf '  %b│ %b%-14s %b%-45s %b│%b\n' "${border}" "${label}" 'Memory usage:' "${data}" "${memory}" "${border}" "${reset}"
        printf '  %b│ %b%-14s %b%-45s %b│%b\n' "${border}" "${label}" 'IP:' "${data}" "${address}" "${border}" "${reset}"
        printf '  %b│ %b%-14s %b%-45s %b│%b\n' "${border}" "${label}" 'CPU temp:' "${data}" "${temperature}" "${border}" "${reset}"
        printf '  %b│ %b%-14s %b%-45s %b│%b\n' "${border}" "${label}" 'Usage of /:' "${data}" "${disk}" "${border}" "${reset}"
        printf '  %b╰──────────────────────────────────────────────────────────────╯%b\n' "${border}" "${reset}"
    fi

    if (( columns >= 92 )); then
        printf '\n  %b[ %bBoard setup: %bsudo orangepi-config%b | %bOverview: %bfastfetch%b | %bMonitor: %bbtop%b ]%b\n\n' \
            "${border}" "${label}" "${command}" "${label}" "${label}" \
            "${command}" "${label}" "${label}" "${command}" "${border}" "${reset}"
    else
        printf '\n  %b[ %bSetup: %bsudo orangepi-config%b | %bInfo: %bfastfetch%b | %bMonitor: %bbtop%b ]%b\n\n' \
            "${border}" "${label}" "${command}" "${label}" "${label}" \
            "${command}" "${label}" "${label}" "${command}" "${border}" "${reset}"
    fi
}

lumina_zero3_banner
unset -f lumina_zero3_banner
