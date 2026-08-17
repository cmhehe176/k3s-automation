#!/usr/bin/env bash
# Root wrapper for K3s Automation Manager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/ansible/cluster.sh" "$@"
