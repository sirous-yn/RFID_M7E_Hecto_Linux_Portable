# Design notes

The portable package deliberately separates:

- `src/` — application code
- `vendor/` — third-party SDK supplied locally
- `.venv/` — generated per computer
- `docs/` — instructions

Do not copy `.venv/` between Linux computers. Python virtual environments can contain machine-specific paths and binaries.

The current reader test uses:

- region: `NA`
- protocol: `GEN2`
- antenna: `[1]`
- read bank: `tid`
- read power: `1000`

These values reproduce the working setup developed for the M7E-Hecto.

The application uses `tag.tid_mem_data`, not `tag.tid`, because that is the attribute exposed by the installed Python wrapper in the working environment.
