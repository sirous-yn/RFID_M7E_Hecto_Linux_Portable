# Installation

## 1. Put the MercuryAPI ZIP in the vendor folder

Copy:

    mercuryapi-BILBO-1.37.6.17.zip

to:

    vendor/mercuryapi-BILBO-1.37.6.17.zip

## 2. Make the scripts executable

    chmod +x setup.sh run_rfid.sh

## 3. Run the installer

    ./setup.sh

The installer:

1. detects a common Linux package manager
2. installs required build tools
3. extracts the local MercuryAPI SDK
4. builds MercuryAPI
5. downloads the open-source Python wrapper
6. prepares the wrapper to use MercuryAPI 1.37.6.17
7. applies the known API-signature compatibility patch
8. creates `.venv`
9. installs Python packages
10. installs the `mercury` Python module
11. checks USB serial permissions
12. checks whether the RFID reader is visible

## 4. Run the RFID test

    ./run_rfid.sh

The program searches for USB VID 1A86 / PID 7523 and therefore does not depend on a particular `/dev/ttyUSB*` number.

## Internet requirement

The MercuryAPI SDK is local. The installer still needs network access to:

- install Linux packages
- clone the open-source Python wrapper
- install Python packages with pip

If the target computer has no internet access, this package needs an additional offline dependency bundle.
