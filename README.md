# SparkFun M7E-Hecto RFID Reader — Linux Python Package

A reusable Python package for reading RFID tags with the SparkFun Simultaneous RFID Reader M7E-Hecto on Linux.

The package provides a simple Python interface for applications that need to obtain the TID of an RFID tag.

## Supported hardware

- SparkFun Simultaneous RFID Reader M7E-Hecto
- USB connection through the onboard CH340 USB-to-serial interface
- USB VID: `0x1A86`
- USB PID: `0x7523`

The package identifies the reader by its USB VID/PID rather than assuming a fixed device such as `/dev/ttyUSB0`.

## Installation

For detailed installation instructions, see:

    docs/INSTALLATION.md

## Troubleshooting
If you encounter problems, see:

    docs/TROUBLESHOOTING.md

## Main interface

The primary interface is:

```python
from rfid_reader import get_tid

tid = get_tid()

if tid:
    print("RFID TID:", tid)
else:
    print("No RFID tag detected")