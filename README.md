# Hazard Detection Unit — RTL-to-GDS (SKY130)

Standalone hazard detection block for a RISC-V pipeline, taken through a full RTL-to-GDS physical design flow on the SkyWater SKY130 PDK using OpenLane/OpenROAD.

## What it does

Detects load-use hazards between the ID/EX and IF/ID pipeline stages and generates `stall`/`flush` control signals:

- **Load-use hazard**: instruction in ID/EX is a LOAD (`id_ex_mem_read = 1`) and its destination register (`id_ex_rd`) matches either source register (`if_id_rs1` / `if_id_rs2`) of the instruction currently in IF/ID.
- **stall = 1** → freeze PC and IF/ID register for one cycle.
- **flush = 1** → insert a NOP bubble into the ID/EX register.

## Repository contents

| File | Description |
|---|---|
| `src/hazard_unit.v` | RTL source — exact file used as OpenLane synthesis input (`VERILOG_FILES: dir::src/*.v`) |
| `tb_hazard_unit.v` | Standalone self-checking testbench, 11 directed test cases covering all hazard / no-hazard combinations |
| `results/signoff/hazard_unit.klayout.gds` | Final signed-off GDSII layout |
| `results/signoff/` | DRC and signoff reports |

## Verification

Simulated with QuestaSim against `tb_hazard_unit.v`:

- **11/11 directed tests passing**
- Covers: no-hazard baseline, `mem_read=0` suppression, `rd=x0` guard, hazard on `rs1` match, hazard on `rs2` match, hazard on simultaneous `rs1`/`rs2` match, non-matching `rd`, boundary register index (`x31`), and hazard-clear-on-deassert transition.

```
============================================
 hazard_unit — Unit Verification
============================================
[PASS] Test 1  ... 
[PASS] Test 2  ...
...
[PASS] Test 11 ...
============================================
 RESULTS: 11 PASSED  0 FAILED
============================================
 ** ALL TESTS PASSED **
```

## Physical implementation (RTL-to-GDS)

Full flow run through **OpenLane / OpenROAD** on the **SKY130 PDK**:

- Synthesis → Floorplan → Placement → CTS → Global/Detailed Routing → DRC/LVS signoff (KLayout)
- Run ID: `RUN_2026.06.21_10.47.52`
- **Final GDS size: 247 KB** (`hazard_unit.klayout.gds`)
- **DRC signoff: 167 DRC violations** reported in this run. These are disclosed as-is; if you're evaluating this repo, treat the layout as a completed signoff *run* rather than a zero-violation clean signoff — see `results/signoff/` for the full DRC report.

## RTL provenance note

The RTL in `src/hazard_unit.v` was verified to be byte-identical (whitespace-only differences) to the copy independently maintained during development, confirming no drift between the version simulated/verified and the version physically implemented.

## Tools

- **RTL / Simulation**: Verilog, QuestaSim
- **Physical Design**: OpenLane, OpenROAD, KLayout, SKY130 PDK (Docker/WSL2)

## Status

Standalone block only — not integrated into a full CPU pipeline signoff. A separate integration attempt (`cpu_top`) was abandoned at the physical design stage due to register-file/data-memory flop count driving excessive routing congestion; this hazard_unit block was carried forward as an independent, fully signed-off deliverable.
