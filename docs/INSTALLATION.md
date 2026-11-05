# Installation

## 1. Recommended installation

The easiest way to install and test the RFID package is to use the included setup script.

From the main package directory, run:

    ./setup.sh

The setup script creates a Python virtual environment and installs the RFID package and its required dependencies.

## 2. Test the RFID reader

Connect the M7E-Hecto RFID reader, then run:

    ./run_rfid.sh

If an RFID tag is detected, its TID is printed as an uppercase hexadecimal string.

For example:

    E28011052000778226410B2D000000000000000000000000

## 3. Manual wheel installation

If you want to install the RFID package into your own Python application environment, create a Python virtual environment first.

From the main package directory, run:

    python3 -m venv .venv

Then install the RFID package wheel:

    .venv/bin/python -m pip install dist/rfid_m7e_hecto-1.0.0-cp314-none-linux_x86_64.whl

This avoids installing packages into the system Python. Modern Ubuntu systems may prevent system-wide pip installations because of the externally managed Python environment.

The package includes the required MercuryAPI runtime libraries and the compiled Python extension.

No separate MercuryAPI installation is required for normal use.

## 4. Test from Python

After installing the wheel, an application can use:

    from rfid_reader import get_tid

    tid = get_tid()

    print(tid)

If an RFID tag is detected, its TID is returned as an uppercase hexadecimal string.

## 5. Using the package in another application

Any compatible Python application can use the RFID reader with:

    from rfid_reader import get_tid

    tid = get_tid()

The application does not need to configure the USB port manually.

The package automatically detects the M7E-Hecto using:

    USB VID: 0x1A86
    USB PID: 0x7523

Therefore, the reader can appear as /dev/ttyUSB0, /dev/ttyUSB1, or another device number.

## Supported environment

The current release has been tested on:

- Linux x86_64
- Python 3.14
- Ubuntu
- Fedora Linux 43
- SparkFun M7E-Hecto

The current package contains a Python 3.14 native extension, so it is intended for compatible Linux x86_64 systems using Python 3.14.
