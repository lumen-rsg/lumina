#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR
readonly KICKSTART="${TEST_DIR}/../lumina-jetson.ks"
readonly BUILD_SCRIPT="${TEST_DIR}/../build-iso.sh"
readonly GRUB_CONFIG="${TEST_DIR}/../grub.cfg.fragment"

fail()
{
    echo "FAIL: $*" >&2
    exit 1
}

grep -Fqx 'rootpw --plaintext root' "${KICKSTART}" ||
    fail "temporary console password is not configured"
if grep -Fq '/usr/bin/chage --lastday 0 root' "${KICKSTART}"; then
    fail "hard password expiry can lock the operator out"
fi
grep -Fq '/var/lib/lumina/temporary-root-password' "${KICKSTART}" ||
    fail "first-shell password reminder is not configured"
grep -Fq '/usr/sbin/restorecon -RF' "${KICKSTART}" ||
    fail "authentication paths are not explicitly relabeled"
grep -Fq 'clock_seed=/run/install/repo/jetson/build.env' "${KICKSTART}" ||
    fail "offline installer clock seed is not loaded"
grep -Fq "printf 'LUMINA_INSTALLER_MIN_EPOCH=%s\\n'" "${BUILD_SCRIPT}" ||
    fail "ISO builder does not emit the offline clock seed"
# shellcheck disable=SC2016
grep -Fq 'date -u --set="@${LUMINA_INSTALLER_MIN_EPOCH}"' "${KICKSTART}" ||
    fail "stale installer clocks are not advanced"
grep -Fq 'PermitRootLogin prohibit-password' "${KICKSTART}" ||
    fail "SSH root access is not restricted to keys"
grep -Fq 'PasswordAuthentication no' "${KICKSTART}" ||
    fail "SSH password authentication is not disabled"

rescue_entry=$(sed -n \
    '/^menuentry "Rescue installed 1T Lumina/,/^}/p' "${GRUB_CONFIG}")
grep -Fq 'inst.rescue' <<<"${rescue_entry}" ||
    fail "non-destructive rescue entry is missing"
if grep -Fq 'lumina.jetson.erase' <<<"${rescue_entry}"; then
    fail "rescue entry contains a destructive erase argument"
fi

echo "PASS: Kickstart first-login and SSH policy"
