import os
import serial.tools.list_ports
import mercury

BAUD = 115200

USB_VID = 0x1A86
USB_PID = 0x7523

# Working RF power determined on hkdaq01
DEFAULT_READ_POWER = 2600


def find_rfid_port():
    matches = [
        port.device
        for port in serial.tools.list_ports.comports()
        if port.vid == USB_VID and port.pid == USB_PID
    ]

    if not matches:
        raise RuntimeError(
            "RFID reader not found. "
            "Connect the M7E-Hecto and try again."
        )

    if len(matches) > 1:
        raise RuntimeError(
            f"Multiple CH340 devices found: {matches}"
        )

    return matches[0]


def create_reader():
    port = find_rfid_port()
    return mercury.Reader(
        f"tmr://{port}",
        baudrate=BAUD
    )


def get_tid(read_power=DEFAULT_READ_POWER):
    reader = create_reader()

    reader.set_region("NA")

    reader.set_read_plan(
        [1],
        "GEN2",
        bank=["tid"],
        read_power=read_power
    )

    tags = reader.read()

    if not tags:
        return None

    return tags[0].tid_mem_data.hex().upper()


if __name__ == "__main__":
    tid = get_tid()

    if tid:
        print(tid)
    else:
        print("No RFID tag detected.")
