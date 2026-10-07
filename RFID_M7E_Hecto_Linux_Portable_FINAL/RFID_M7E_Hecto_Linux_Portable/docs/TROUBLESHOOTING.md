# Troubleshooting

## `RFID reader not found`

Check:

    lsusb

You should see:

    1a86:7523 QinHeng Electronics CH340 serial converter

Then check:

    ls /dev/ttyUSB*

The number may be `/dev/ttyUSB0`, `/dev/ttyUSB1`, or another value. This is normal.

## Permission denied on `/dev/ttyUSB*`

Check:

    groups

You should see:

    dialout

If setup just added you to `dialout`, log out and log back in (or reboot).

## `No module named mercury`

Activate the project environment:

    source .venv/bin/activate

Then:

    python -c "import mercury; print('Mercury OK')"

If it fails, rerun:

    ./setup.sh

## MercuryAPI build failure involving `-Werror`

The project deliberately builds MercuryAPI with:

    make CWARN="-Wall"

This avoids the GCC warning-as-error issue encountered with MercuryAPI 1.37.6.17 on the development system.

## TID appears as unreadable characters

TID data is binary. Do not use `.decode()`.

Use:

    tag.tid_mem_data.hex().upper()

## Reader is `/dev/ttyUSB1` instead of `/dev/ttyUSB0`

No change is required. The program identifies the reader using:

    VID = 0x1A86
    PID = 0x7523

## Multiple CH340 devices

If another CH340 device is connected, automatic detection may find more than one. Disconnect unrelated CH340 devices or modify the detection logic to use a more specific USB serial identity.
