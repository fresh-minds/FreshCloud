#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/postgres-restore-test.sh"
"${SCRIPT_DIR}/minio-restore-test.sh"
