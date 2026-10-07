#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$SCRIPT_DIR/.venv/bin/activate" ]]; then
    echo "The project is not installed yet." >&2
    echo "Run:" >&2
    echo "  ./setup.sh" >&2
    exit 1
fi

source "$SCRIPT_DIR/.venv/bin/activate"

export PYTHONPATH="$SCRIPT_DIR/src"
export LD_LIBRARY_PATH="$SCRIPT_DIR/vendor/python-mercuryapi/build/mercuryapi/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

exec python "$SCRIPT_DIR/src/test_rfid.py"
