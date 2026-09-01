#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR
readonly KICKSTART="${TEST_DIR}/../lumina-jetson.ks"

fail()
{
    echo "FAIL: $*" >&2
    exit 1
}

grep -Fqx 'rootpw --plaintext root' "${KICKSTART}" ||
    fail "temporary console password is not configured"
grep -Fqx '/usr/bin/chage --lastday 0 root' "${KICKSTART}" ||
    fail "root password is not expired for first login"
grep -Fq 'PermitRootLogin prohibit-password' "${KICKSTART}" ||
    fail "SSH root access is not restricted to keys"
grep -Fq 'PasswordAuthentication no' "${KICKSTART}" ||
    fail "SSH password authentication is not disabled"

echo "PASS: Kickstart first-login and SSH policy"
