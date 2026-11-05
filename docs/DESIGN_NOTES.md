# Design Notes

## Package structure

The project separates the RFID interface from applications that use it.

The main components are:

    src/
        rfid_reader.py
        test_rfid.py

    src/rfid_m7e_hecto/
        mercury Python extension
        MercuryAPI runtime libraries

    vendor/
        MercuryAPI SDK used for development and rebuilding

    docs/
        documentation

The RFID reader interface is designed to be independent of any particular main application.

## Python interface

Applications use the RFID reader through:

    from rfid_reader import get_tid

    tid = get_tid()

The application does not need to communicate directly with MercuryAPI.

## Reader configuration

The current working configuration is:

    Region: NA
    Protocol: GEN2
    Antenna: [1]
    Memory bank: TID
    Read power: 2600 (26 dBm)
    Baud rate: 115200

## RFID TID

The Python wrapper provides the tag TID through:

    tag.tid_mem_data

The TID is converted to an uppercase hexadecimal string before it is returned by get_tid().

The application therefore receives a value such as:

    E28011052000778226410B2D000000000000000000000000

## USB device detection

The package identifies the M7E-Hecto using its USB identifiers:

    VID: 0x1A86
    PID: 0x7523

This avoids depending on a fixed Linux device name such as /dev/ttyUSB0.