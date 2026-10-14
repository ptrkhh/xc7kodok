# Charger review — 2026-10-11

## Moderator frame

Scope: the supplied seven files, treated as a prototype for one battery and one TP4056 module. Requirements come from README.md: printable cradle and plate, aligned battery contacts, space for the specified connector and module, and usable assembly instructions. Success means supported geometry, matching exports, reproducible checks, and explicit limits on hardware claims. Physical fit and charging cannot be established from CAD alone.

The Moderator consulted [Ponytail](https://github.com/DietrichGebert/ponytail) and its installed skill: use the smallest complete fix, preserve validation and physical calibration, and test risky changes. No Git metadata existed in this directory at review time; originals were copied to `/tmp/xc7kodok-review-orMBNE/original/` before editing.

## Issue ledger

| ID | Severity | Evidence and dependency | Disposition | Remaining risk |
|---|---|---|---|---|
| I1 | HIGH | BC-25 drawing maps DIM A to housing height, not tip protrusion. Original pocket intersects the actual nominal housing. Affects SCAD, connector CSV, instructions, cradle export and preview. | Fixed; housing and nominal leaf clearance regressions pass. Cradle and preview regenerated. | Drawing tolerances, working stroke, force and actual fit require measurement. |
| I2 | MED | Assembly specifies two-wire charging without module/pack electrical prerequisites. TP4056 datasheet distinguishes battery sensing from chip thermal regulation. Depends on actual module and pack data, not I1. | Fixed documentation; electrical validation remains a documented risk. | Actual polarity, settings, protection, charge behavior and temperatures are untested. |

## Sequential debate

### I1 — BC-25 dimensions and orientation

**Critic:** The default connector cannot fit as documented. The [manufacturer drawing](https://datasheet.lcsc.com/datasheet/pdf/8153bae77de8ce951813d5d88903037f.pdf?productCode=C707322), sheet 1, gives housing height DIM A = 1.7/2.0 mm, total height DIM B = 3.05/3.35 mm, and free protrusion 1.35 ± 0.2 mm. The original source used 1.7 mm as protrusion, 4.2 mm as housing height and 5 mm as installed vertical depth. Its prescribed PCB-face-back orientation also contradicts the drawing. An OpenSCAD intersection with the nominal 7.5 x 5 x 1.7 mm housing, aligned for tips at Z=10.5 mm, produces 22.46625 mm³ of interference. The repository regression test fails against the original source.

**Writer:** Conceded. Keep the existing parameter names but define them in installed coordinates: `con_h=5.0` along Y, `con_d=1.7` along Z, `con_tip=1.35`, and nominal `con_tip_y=3.75`. Mount the PCB face down. Correct the CSV and instructions and regenerate affected artifacts. No new connector abstraction is needed.

**Critic:** Accepted. The nominal floor becomes 0.85 mm, which meets the existing 0.8 mm guard. The ±0.2 mm tip tolerance changes actual protrusion to 0.3–0.7 mm; document it. The drawing does not establish working stroke or force.

**Moderator:** Apply the correction and retain those hardware limits. Reopen the previous abstract housing clearance check because its dimensions were wrong. Require a test based on the manufacturer's housing dimensions and a fresh export before settling as fixed.

**Critic, dependent clearance check:** The housing correction moves the free apex away from the housing center. With the existing 3 mm window, its near edge is Y=2.25 mm relative to the housing. The drawn leaf ramp rises above the housing near Y=2.19 mm. That coordinate is scaled from the drawing, not a manufacturing dimension; the housing-only test cannot establish leaf clearance.

**Writer:** Widen the existing `win_y` from 3 to 4 mm, moving the near edge to Y=1.75 mm. Add a regression for an approximate free-leaf envelope, housing-relative Y=2.0–4.3 mm. Require inspection of the actual compressed spring.

**Critic:** Accepted. The added clearance addresses the nominal drawing without claiming a verified working stroke.

**Moderator:** Include the window correction within I1. No independent settled issue needs reopening.

### I2 — Electrical prerequisites missing from assembly instructions

**Critic:** The instructions do not establish whether the unspecified module and battery are compatible. The [TP4056 manufacturer datasheet](https://www.toppwr.com/uploadfile/file/20230304/640301eae1260.pdf), pages 7–10, specifies 4.2 V regulation, resistor-programmed current, and disabled battery-temperature sensing when TEMP is grounded. Die thermal regulation is separate. The repository does not include the actual module schematic or verified pack limits. This is a material documentation gap, not evidence that a particular board is faulty.

**Writer:** Add the missing pre-power checks and distinguish mechanical assembly from validated charging. Do not invent a current setting or thermistor pin assignment.

**Critic:** Accepted, with a primary-source link beside the claims.

**Moderator:** Documentation fixed. Electrical validation remains a documented risk; a CAD review cannot close it.

## Verification and limits

- `python3 -m unittest -v test_charger.py`: 3 tests pass (housing fit, nominal leaf envelope, and both part renders). Both collision regressions were observed failing before their respective fixes.
- Fresh original-source exports with `--hardwarnings` pass for cradle and bottom. Cradle: 1,576 triangles, closed edges, positive volume 38,703.34898 mm³, bounds 74.6 x 55 x 75 mm. Bottom: 1,340 triangles, closed edges, positive volume 10,353.25705 mm³, bounds 74.6 x 55 x 4.5 mm. The bottom export remains triangle-identical to the supplied file.
- Parameter evaluation accepts 2.54 mm pitch, four pins with 10 mm housing width, six pins with 15 mm housing width, and the -200 housing height. Existing guards reject 3.0 mm pitch, 0.6 mm tip protrusion (floor too thin), and 10 mm connector height. These are assertion checks, not physical fit tests for alternate connectors.
- The assembly preview was regenerated at 1000 x 800 and visually inspected. The SolidWorks file remains byte-identical to the original.
- Baseline OpenSCAD 2021.01 exports succeeded; both supplied STLs matched fresh exports triangle for triangle. Both had closed edges and positive volume.
- Initial default battery, PCB, and connector-box clearance checks passed, but the connector box used the incorrect defaults; I1 invalidated that part of the evidence.
- The initial codebase graph indexed README and CSV only; the added Python tests were indexed later. SCAD and binary artifacts were not tracked; source, rendered solids, and the preview were inspected directly.
- The SolidWorks battery file was preserved but could not be independently decoded here. Battery dimensions and polarity remain the README's supplied assumptions.
- No physical print, actual connector/module fit, spring-force test, electrical test, or thermal test has been performed.

## Integrated Critic review

After both issues settled, the Critic reviewed the combined source, instructions, connector data, tests, generated preview and verification evidence. No new material regression, conflict or scope drift was found. The original bottom STL and SolidWorks file were independently confirmed byte-identical to the backup. A minor graph-coverage wording correction was fast-tracked.

The Moderator closes I1 as fixed and I2 as documentation fixed with electrical validation still unresolved. Neither disposition establishes physical fit or charging readiness. No deadlock required a ruling.
