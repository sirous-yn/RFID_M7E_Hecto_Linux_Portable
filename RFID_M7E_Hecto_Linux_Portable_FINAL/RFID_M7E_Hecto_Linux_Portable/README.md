# SparkFun M7E-Hecto RFID Reader — Linux Portable Project

This project is designed to install and run the SparkFun Simultaneous RFID Reader M7E-Hecto on common Linux distributions.

## What this package does

The project provides:

- automatic detection of the M7E-Hecto USB serial port
- no hard-coded `/dev/ttyUSB0` or `/dev/ttyUSB1`
- a local MercuryAPI SDK package supplied by the user
- automatic creation of a Python virtual environment
- installation of Python dependencies
- automatic building of MercuryAPI
- automatic preparation/build of the `python-mercuryapi` wrapper
- the compatibility patch required by MercuryAPI 1.37.6.17
- a simple RFID TID test program
- Jupyter support
- troubleshooting documentation

## Before running setup

Put your existing MercuryAPI ZIP in:

    vendor/mercuryapi-BILBO-1.37.6.17.zip

The package intentionally does not include the MercuryAPI ZIP.

## Quick start

From the project directory:

    chmod +x setup.sh run_rfid.sh
    ./setup.sh

After setup finishes:

    ./run_rfid.sh

The reader should be detected automatically, for example:

    RFID reader found at: /dev/ttyUSB1
    TID: E280...

The Linux device can be `/dev/ttyUSB0`, `/dev/ttyUSB1`, etc. The program identifies the reader by its CH340 USB VID/PID:

    VID = 0x1A86
    PID = 0x7523

## Important

This package is intended for Linux systems with a supported Python 3 installation and a working USB serial stack. The setup script supports common Debian/Ubuntu, Fedora/RHEL, Arch, and openSUSE-style package managers. Linux is highly diverse, so it cannot honestly guarantee compatibility with every distribution, kernel, CPU architecture, or Python release.

The MercuryAPI SDK is third-party/proprietary software and must be supplied separately.

## Project layout

    RFID_M7E_Hecto_Linux_Portable/
    ├── setup.sh
    ├── run_rfid.sh
    ├── requirements.txt
    ├── src/
    │   ├── rfid_reader.py
    │   └── test_rfid.py
    ├── vendor/
    │   └── mercuryapi-BILBO-1.37.6.17.zip
    └── docs/
        ├── INSTALLATION.md
        └── TROUBLESHOOTING.md
