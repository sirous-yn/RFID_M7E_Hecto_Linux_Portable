# Troubleshooting

## RFID reader not found

Make sure the M7E-Hecto is connected by USB.

The reader uses:

    USB VID: 0x1A86
    USB PID: 0x7523

The Linux device may be:

    /dev/ttyUSB0

or:

    /dev/ttyUSB1

The exact number does not matter. The package detects the reader automatically.

## Permission denied on /dev/ttyUSB*

The user running the application needs permission to access the USB serial device.

Check your groups with:

    groups

On many Linux systems, the required group is:

    dialout

If you were recently added to the dialout group, log out and log back in before trying again.

## No module named mercury

The package contains the required compiled Mercury Python extension.

Make sure the RFID package was installed in the same Python environment that is running your application.

Check the installation with:

    .venv/bin/python -m pip show rfid-m7e-hecto

If the package is not listed, install the wheel again.

## RFID tag is not detected

Make sure:

- The M7E-Hecto is connected.
- An RFID tag is within the reader's range.
- The tag is compatible with the configured GEN2 protocol.
- The tag is positioned close enough to the antenna.

The default read power is 2600 (26 dBm).

## TID appears as unreadable characters

TID data is binary data.

The package converts it to an uppercase hexadecimal string automatically.

The application should use:

    tid = get_tid()

and should not try to decode the TID as normal text.

## Reader is /dev/ttyUSB1 instead of /dev/ttyUSB0

No change is required.

The package does not depend on a specific ttyUSB number.

## Multiple CH340 devices

If more than one device with the same USB VID/PID is connected, the package may report multiple matching devices.

Disconnect unrelated CH340 devices and try again.