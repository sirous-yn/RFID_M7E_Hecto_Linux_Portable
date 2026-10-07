# RFID M7E-Hecto Linux Portable

Standalone Linux package for reading RFID tag TIDs using the SparkFun Simultaneous RFID Reader M7E-Hecto.

The package is designed to provide a simple and portable RFID interface for Linux systems. It includes the required MercuryAPI components, the Python interface, installation scripts, and a test program.

## Hardware

- SparkFun Simultaneous RFID Reader M7E-Hecto
- USB connection
- USB-to-UART interface based on the CH340
- RFID tag compatible with EPC Gen2 / ISO 18000-63

The reader is connected to the Linux computer through USB.

## Tested Environment

The package has been tested on:

- Fedora Linux 43
- x86_64
- Python 3.14
- M7E-Hecto firmware 2.01.06.08

The USB device is identified using:

```text
VID: 1A86
PID: 7523
