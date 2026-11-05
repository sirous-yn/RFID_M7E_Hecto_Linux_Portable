import ctypes
import subprocess
import sys
from pathlib import Path

_HERE = Path(__file__).resolve().parent

# When running from the source tree.
_SOURCE_LIB_DIR = (
    _HERE.parent
    / "vendor"
    / "python-mercuryapi"
    / "build"
    / "mercuryapi"
    / "lib"
)

# When installed with pip, the libraries are packaged here.
_INSTALLED_LIB_DIR = (
    _HERE
    / "rfid_m7e_hecto"
    / "libs"
)

if _SOURCE_LIB_DIR.is_dir():
    _MERCURY_LIB_DIR = _SOURCE_LIB_DIR
elif _INSTALLED_LIB_DIR.is_dir():
    _MERCURY_LIB_DIR = _INSTALLED_LIB_DIR
else:
    raise RuntimeError("MercuryAPI libraries were not found.")

# Load MercuryAPI dependencies before importing the mercury extension.
for _lib_name in ("libltkc.so.1", "libltkctm.so.1"):
    _lib_path = _MERCURY_LIB_DIR / _lib_name

    if not _lib_path.exists():
        raise RuntimeError(
            f"Required MercuryAPI library not found: {_lib_path}"
        )

    ctypes.CDLL(str(_lib_path), mode=ctypes.RTLD_GLOBAL)

import importlib.util
import serial.tools.list_ports


# Load the bundled mercury extension.
_MERCURY_EXTENSION = (
    _HERE
    / "rfid_m7e_hecto"
    / "mercury.cpython-314-x86_64-linux-gnu.so"
)

if not _MERCURY_EXTENSION.exists():
    raise RuntimeError(
        f"Bundled mercury extension not found: {_MERCURY_EXTENSION}"
    )

_spec = importlib.util.spec_from_file_location(
    "mercury",
    _MERCURY_EXTENSION,
)

if _spec is None or _spec.loader is None:
    raise RuntimeError("Could not load the bundled mercury extension.")

mercury = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(mercury)


BAUD = 115200
USB_VID = 0x1A86
USB_PID = 0x7523

DEFAULT_READ_POWER = 2600

# Maximum time allowed to identify one candidate device.
PROBE_TIMEOUT_SECONDS = 5

EXPECTED_MODEL = "m7e hecto"


def _is_m7e_hecto(port):
    """
    Test a serial port in an isolated Python process.

    Returns True only when MercuryAPI identifies an M7E-Hecto.
    """

    probe_code = """
import sys

sys.path.insert(0, sys.argv[1])

import rfid_reader

reader = None

try:
    reader = rfid_reader.mercury.Reader(
        f"tmr://{sys.argv[2]}",
        baudrate=rfid_reader.BAUD,
    )

    model = str(reader.get_model()).strip()
    print("RFID_MODEL=" + model)

finally:
    if reader is not None:
        try:
            reader.destroy()
        except Exception:
            pass
"""

    try:
        result = subprocess.run(
            [
                sys.executable,
                "-c",
                probe_code,
                str(_HERE),
                port,
            ],
            capture_output=True,
            text=True,
            timeout=PROBE_TIMEOUT_SECONDS,
        )

    except (subprocess.TimeoutExpired, OSError):
        return False

    if result.returncode != 0:
        return False

    for line in result.stdout.splitlines():
        if line.startswith("RFID_MODEL="):
            model = line.split("=", 1)[1].strip().casefold()
            return model == EXPECTED_MODEL

    return False


def find_rfid_port():
    """Automatically identify the connected M7E-Hecto reader."""

    candidates = [
        port.device
        for port in serial.tools.list_ports.comports()
        if port.vid == USB_VID and port.pid == USB_PID
    ]

    if not candidates:
        raise RuntimeError(
            "RFID reader not found. Connect the M7E-Hecto and try again."
        )

    valid_readers = [
        port
        for port in candidates
        if _is_m7e_hecto(port)
    ]

    if not valid_readers:
        raise RuntimeError(
            "No responding M7E-Hecto reader was found."
        )

    if len(valid_readers) > 1:
        raise RuntimeError(
            "Multiple M7E-Hecto readers found. "
            "Automatic identification is ambiguous."
        )

    return valid_readers[0]


def create_reader():
    """Connect to the automatically identified RFID reader."""

    port = find_rfid_port()

    return mercury.Reader(
        f"tmr://{port}",
        baudrate=BAUD,
    )


def get_tid(read_power=DEFAULT_READ_POWER):
    """
    Read an RFID tag TID.

    Returns:
        str: Uppercase hexadecimal TID if a tag is read.
        None: If no tag is detected.
    """

    reader = create_reader()

    reader.set_region("NA")

    reader.set_read_plan(
        [1],
        "GEN2",
        bank=["tid"],
        read_power=read_power,
    )

    tags = reader.read()

    if not tags:
        return None

    return tags[0].tid_mem_data.hex().upper()
