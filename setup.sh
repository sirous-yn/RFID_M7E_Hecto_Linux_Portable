#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SDK_ZIP="$SCRIPT_DIR/vendor/mercuryapi-BILBO-1.37.6.17.zip"
SDK_ROOT="$SCRIPT_DIR/vendor/mercuryapi-1.37.6.17"
WRAPPER_DIR="$SCRIPT_DIR/vendor/python-mercuryapi"

PACKAGE_DIR="$SCRIPT_DIR/src/rfid_m7e_hecto"
VENV="$SCRIPT_DIR/.venv"
DIST_DIR="$SCRIPT_DIR/dist"

log() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

die() {
    echo
    echo "ERROR: $1"
    exit 1
}

cd "$SCRIPT_DIR"

log "Checking operating system"

if [[ ! -f /etc/os-release ]]; then
    die "Cannot identify Linux distribution."
fi

. /etc/os-release
echo "Detected: ${PRETTY_NAME:-$ID}"

command -v sudo >/dev/null 2>&1 || die "sudo is required."
command -v python3 >/dev/null 2>&1 || die "python3 is required."

install_deps_apt() {
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        unzip \
        patch \
        xsltproc \
        gcc \
        g++ \
        make \
        libreadline-dev \
        python3-dev \
        python3-venv \
        git
}

install_deps_dnf() {
    sudo dnf install -y \
        gcc \
        gcc-c++ \
        make \
        patch \
        unzip \
        xsltproc \
        readline-devel \
        python3-devel \
        python3-pip \
        python3-virtualenv \
        git
}

install_deps_yum() {
    sudo yum install -y \
        gcc \
        gcc-c++ \
        make \
        patch \
        unzip \
        readline-devel \
        python3-devel \
        python3-pip \
        git
}

install_deps_pacman() {
    sudo pacman -Sy --needed --noconfirm \
        base-devel \
        unzip \
        patch \
        libxslt \
        readline \
        python \
        python-pip \
        python-virtualenv \
        git
}

install_deps_zypper() {
    sudo zypper --non-interactive install \
        gcc \
        gcc-c++ \
        make \
        unzip \
        patch \
        libxslt-tools \
        readline-devel \
        python3-devel \
        python3-pip \
        git
}

log "Installing Linux build dependencies"

if command -v apt-get >/dev/null 2>&1; then
    install_deps_apt
elif command -v dnf >/dev/null 2>&1; then
    install_deps_dnf
elif command -v yum >/dev/null 2>&1; then
    install_deps_yum
elif command -v pacman >/dev/null 2>&1; then
    install_deps_pacman
elif command -v zypper >/dev/null 2>&1; then
    install_deps_zypper
else
    die "Unsupported package manager."
fi

log "Checking MercuryAPI SDK"

if [[ ! -f "$SDK_ZIP" ]]; then
    die "Missing MercuryAPI SDK:

$SDK_ZIP

Place:
mercuryapi-BILBO-1.37.6.17.zip

inside:
$SCRIPT_DIR/vendor/"
fi

if [[ ! -f "$SDK_ROOT/c/src/api/tm_reader.h" ]]; then

    find "$SCRIPT_DIR/vendor" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -name 'mercuryapi-*' \
        -exec rm -rf {} +

    unzip -q "$SDK_ZIP" -d "$SCRIPT_DIR/vendor"

    FOUND_SDK=""

    while IFS= read -r -d '' candidate; do
        FOUND_SDK="$candidate"
        break
    done < <(
        find "$SCRIPT_DIR/vendor" \
            -mindepth 1 \
            -maxdepth 5 \
            -type d \
            -path "*/c/src/api" \
            -print0
    )

    if [[ -z "$FOUND_SDK" ]]; then
        die "Could not locate c/src/api inside MercuryAPI SDK."
    fi

    EXTRACTED_ROOT="$(dirname "$(dirname "$(dirname "$FOUND_SDK")")")"

    if [[ "$EXTRACTED_ROOT" != "$SDK_ROOT" ]]; then
        rm -rf "$SDK_ROOT"
        mv "$EXTRACTED_ROOT" "$SDK_ROOT"
    fi
fi

[[ -f "$SDK_ROOT/c/src/api/tm_reader.h" ]] ||
    die "MercuryAPI SDK layout is invalid."

log "Building MercuryAPI core library"

pushd "$SDK_ROOT/c/src/api" >/dev/null

make clean >/dev/null 2>&1 || true

make CWARN="-Wall" libmercuryapi.a libmercuryapi.so.1

popd >/dev/null

[[ -f "$SDK_ROOT/c/src/api/libmercuryapi.a" ]] ||
    die "libmercuryapi.a was not built."

[[ -f "$SDK_ROOT/c/src/api/libmercuryapi.so.1" ]] ||
    die "libmercuryapi.so.1 was not built."

log "Preparing Python MercuryAPI wrapper"

if [[ ! -f "$WRAPPER_DIR/setup.py" ]]; then
    rm -rf "$WRAPPER_DIR"

    git clone \
        --depth 1 \
        https://github.com/gotthardp/python-mercuryapi.git \
        "$WRAPPER_DIR"
fi

SETUP_PY="$WRAPPER_DIR/setup.py"
MERCURY_C="$WRAPPER_DIR/mercury.c"

[[ -f "$SETUP_PY" ]] ||
    die "python-mercuryapi setup.py not found."

[[ -f "$MERCURY_C" ]] ||
    die "python-mercuryapi mercury.c not found."

log "Patching python-mercuryapi"

python3 - "$SETUP_PY" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

old = 'os.system("make mercuryapi")'

if old in s:
    s = s.replace(old, '# os.system("make mercuryapi")')

p.write_text(s)
PY

python3 - "$MERCURY_C" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

old = (
    'TMR_writeTagMemBytes(&self->reader, tag_filter, bank, address, '
    'PyByteArray_Size(data), '
    '(uint8_t *)PyByteArray_AsString(data))'
)

new = (
    'TMR_writeTagMemBytes(&self->reader, tag_filter, bank, address, '
    'PyByteArray_Size(data), '
    '(uint8_t *)PyByteArray_AsString(data), NULL)'
)

if old in s:
    s = s.replace(old, new)
elif 'TMR_writeTagMemBytes(&self->reader' in s:
    print("TMR_writeTagMemBytes already patched.")
else:
    raise SystemExit(
        "Could not find TMR_writeTagMemBytes call in mercury.c"
    )

p.write_text(s)
PY

log "Preparing MercuryAPI headers and libraries"

rm -rf "$WRAPPER_DIR/build/mercuryapi"

mkdir -p \
    "$WRAPPER_DIR/build/mercuryapi/include" \
    "$WRAPPER_DIR/build/mercuryapi/lib"

find "$SDK_ROOT/c/src/api" \
    -maxdepth 1 \
    -type f \
    -name '*.h' \
    -exec cp {} "$WRAPPER_DIR/build/mercuryapi/include/" \;

cp "$SDK_ROOT/c/src/api/libmercuryapi.a" \
   "$WRAPPER_DIR/build/mercuryapi/lib/"

cp "$SDK_ROOT/c/src/api/libmercuryapi.so.1" \
   "$WRAPPER_DIR/build/mercuryapi/lib/"

find "$SDK_ROOT/c/src/api/lib/LTK/LTKC/Library" \
    -maxdepth 1 \
    -type f \
    -name '*.h' \
    -exec cp {} "$WRAPPER_DIR/build/mercuryapi/include/" \;

LLRPC_DIR="$SDK_ROOT/c/src/api/lib/LTK/LTKC/Library/LLRP.org"

for header in \
    tm_ltkc.h \
    out_tm_ltkc_wrapper.h \
    out_tm_ltkc.h
do
    if [[ -f "$LLRPC_DIR/$header" ]]; then
        cp "$LLRPC_DIR/$header" \
           "$WRAPPER_DIR/build/mercuryapi/include/"
    fi
done

for lib in \
    libltkc.so.1 \
    libltkctm.so.1
do
    FOUND_LIB="$(find "$SDK_ROOT/c/src/api" -type f -name "$lib" | head -n 1)"

    if [[ -z "$FOUND_LIB" ]]; then
        die "Could not find $lib in MercuryAPI SDK."
    fi

    cp "$FOUND_LIB" \
       "$WRAPPER_DIR/build/mercuryapi/lib/"
done

ln -sf libltkc.so.1 \
    "$WRAPPER_DIR/build/mercuryapi/lib/libltkc.so"

ln -sf libltkctm.so.1 \
    "$WRAPPER_DIR/build/mercuryapi/lib/libltkctm.so"

log "Creating Python virtual environment"

if [[ ! -d "$VENV" ]]; then
    python3 -m venv "$VENV"
fi

PYTHON="$VENV/bin/python"

"$PYTHON" -m pip install --upgrade \
    pip \
    setuptools \
    wheel \
    build

"$PYTHON" -m pip install \
    -r "$SCRIPT_DIR/requirements.txt"

log "Installing python-mercuryapi"

cd "$WRAPPER_DIR"

"$PYTHON" -m pip install .

cd "$SCRIPT_DIR"

log "Copying compiled MercuryAPI runtime into package"

mkdir -p "$PACKAGE_DIR/libs"

export LD_LIBRARY_PATH="$WRAPPER_DIR/build/mercuryapi/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

MERCURY_EXTENSION="$(
    "$PYTHON" -c \
        "import mercury; print(mercury.__file__)"
)"

[[ -f "$MERCURY_EXTENSION" ]] ||
    die "Could not locate compiled MercuryAPI Python extension."

cp "$MERCURY_EXTENSION" "$PACKAGE_DIR/"

for lib in \
    libltkc.so.1 \
    libltkctm.so.1
do
    [[ -f "$WRAPPER_DIR/build/mercuryapi/lib/$lib" ]] ||
        die "Missing compiled runtime library: $lib"

    cp "$WRAPPER_DIR/build/mercuryapi/lib/$lib" \
       "$PACKAGE_DIR/libs/"
done

log "Checking package contents"

[[ -f "$PACKAGE_DIR/__init__.py" ]] ||
    die "Package __init__.py is missing."

[[ -f "$PACKAGE_DIR/libs/libltkc.so.1" ]] ||
    die "libltkc.so.1 is missing from package."

[[ -f "$PACKAGE_DIR/libs/libltkctm.so.1" ]] ||
    die "libltkctm.so.1 is missing from package."

find "$PACKAGE_DIR" -maxdepth 2 -type f -printf '%P\n' | sort

log "Configuring USB serial permissions"

if getent group dialout >/dev/null 2>&1; then

    if id -nG "$USER" | tr ' ' '\n' | grep -qx dialout; then
        echo "User $USER is already in dialout."
    else
        sudo usermod -aG dialout "$USER"

        echo "Added $USER to dialout."
        echo "A logout/login or reboot may be required."
    fi

else
    echo "WARNING: dialout group not found."
fi

log "Checking Mercury Python module"

export LD_LIBRARY_PATH="$WRAPPER_DIR/build/mercuryapi/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

"$PYTHON" -c \
    "import mercury; print('Mercury Python module: OK')"

log "Building RFID wheel"

mkdir -p "$DIST_DIR"

# The user maintains backups separately; remove old build outputs.
rm -f "$DIST_DIR"/*.whl

"$PYTHON" -m build --wheel --no-isolation

WHEEL_FILES=("$DIST_DIR"/*.whl)

if [[ ! -f "${WHEEL_FILES[0]}" ]]; then
    die "Wheel build failed: no wheel was produced."
fi

WHEEL_PATH="${WHEEL_FILES[0]}"

echo
echo "Created wheel:"
echo "$WHEEL_PATH"

log "Installing wheel into project virtual environment"

"$PYTHON" -m pip install \
    --force-reinstall \
    --no-deps \
    "$WHEEL_PATH"

log "Testing wheel in a clean temporary environment"

WHEEL_TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/rfid-wheel-test.XXXXXX")"

cleanup() {
    if [[ -n "${WHEEL_TEST_DIR:-}" && -d "$WHEEL_TEST_DIR" ]]; then
        rm -rf "$WHEEL_TEST_DIR"
    fi
}

trap cleanup EXIT

python3 -m venv "$WHEEL_TEST_DIR/venv"

TEST_PYTHON="$WHEEL_TEST_DIR/venv/bin/python"

"$TEST_PYTHON" -m pip install --upgrade pip

"$TEST_PYTHON" -m pip install "$WHEEL_PATH"

cd "$WHEEL_TEST_DIR"

"$TEST_PYTHON" - <<'PY'
from pathlib import Path
import rfid_reader
import rfid_m7e_hecto

print("rfid_reader import: OK")
print("rfid_m7e_hecto import: OK")

package_dir = Path(rfid_m7e_hecto.__file__).resolve().parent

required_files = [
    package_dir / "mercury.cpython-314-x86_64-linux-gnu.so",
    package_dir / "libs" / "libltkc.so.1",
    package_dir / "libs" / "libltkctm.so.1",
]

for path in required_files:
    if not path.is_file():
        raise RuntimeError(f"Wheel is missing required file: {path}")
    print(f"Package file: {path.name} OK")

if not callable(rfid_reader.get_tid):
    raise RuntimeError("get_tid() is not available.")

if not callable(rfid_reader.find_rfid_port):
    raise RuntimeError("find_rfid_port() is not available.")

print("Public RFID API: OK")
PY

log "Checking RFID reader using the installed wheel"

"$TEST_PYTHON" - <<'PY'
from rfid_reader import find_rfid_port

try:
    port = find_rfid_port()
    print(f"RFID reader detected at: {port}")
except Exception as exc:
    print(f"Reader check: {exc}")
    print("This is not necessarily an installation failure.")
    print("Connect the reader and run ./run_rfid.sh later.")
PY

cd "$SCRIPT_DIR"

log "Checking source-tree RFID reader"

export PYTHONPATH="$SCRIPT_DIR/src"

"$PYTHON" - <<'PY'
from rfid_reader import find_rfid_port

try:
    port = find_rfid_port()
    print(f"RFID reader detected at: {port}")
except Exception as exc:
    print(f"Reader check: {exc}")
    print("This is not necessarily an installation failure.")
PY

log "Installation and wheel tests completed"

echo
echo "Wheel:"
echo "    $WHEEL_PATH"
echo
echo "Project virtual environment:"
echo "    $VENV"
echo
echo "To test the RFID reader:"
echo
echo "    ./run_rfid.sh"
echo
