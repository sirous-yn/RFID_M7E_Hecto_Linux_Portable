from rfid_reader import get_tid

tid = get_tid()

if tid:
    print(tid)
else:
    print("No RFID tag detected.")
