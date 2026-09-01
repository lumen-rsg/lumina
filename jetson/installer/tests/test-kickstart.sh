#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR
readonly KICKSTART="${TEST_DIR}/../lumina-jetson.ks"
readonly BUILD_SCRIPT="${TEST_DIR}/../build-iso.sh"

fail()
{
    echo "FAIL: $*" >&2
    exit 1
}

grep -Fqx 'rootpw --plaintext root' "${KICKSTART}" ||
    fail "temporary console password is not configured"
grep -Fqx '/usr/bin/chage --lastday 0 root' "${KICKSTART}" ||
    fail "root password is not expired for first login"
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

echo "PASS: Kickstart first-login and SSH policy"
