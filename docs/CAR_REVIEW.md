# Car charger review — 2026-10-11 to 2026-10-12

## Moderator frame

Scope: `car.scad`, its three STL parts, preview, tests, and the car instructions in `README.md`. Requirements: a flat battery pocket with nominal contact alignment, removable battery, retained bottom plate, printable parts, and assembly claims supported by evidence. The pack dimensions and polarity remain owner-supplied assumptions. Actual vehicle charging, print strength, and contact reliability require hardware evidence.

The previous session's exact Critic / Writer / Moderator protocol was recovered and followed sequentially, one issue at a time. An independent Critic checked the evidence and the Writer's proposed changes; the Moderator consulted the installed Ponytail review guidance and enforced the smallest sufficient correction. No deadlock needed a ruling.

There was no Git repository at review time. Original top-level files were preserved in `/tmp/xc7kodok-car-review-waqk1hx2/` with SHA-256 hashes before editing. The desktop design and battery model are outside the modification scope.

## Issue ledger

| ID | Severity | Evidence and dependencies | Disposition | Remaining risk |
|---|---|---|---|---|
| C1 | MED | All four bottom countersinks break through the inset plate perimeter. Shared screw coordinates affect cradle and plate. | Fixed: move the shared offset from 5.5 to 7 mm; add edge-margin regression. | Printed fastener strength and screw engagement remain untested. |
| C2 | HIGH | The nominal battery intersects the far wall during 3–4 degree insertion/removal tilt despite fitting when seated. Depends on pocket and chamfer geometry. | Fixed: deepen the existing chamfer while retaining a 2.5 mm vertical stop and the original preload. | Sampled rigid-body clearance does not establish spring stroke or real fit. |
| C3 | MED | Rigid beam translation and uniform-beam strain estimates were presented as release/cracking checks. | Corrected claims and test name; physical clip release remains unresolved. | Tab rotation may hit the rear recess. An unpowered printed release test is required. |
| C4 | MED | Car assembly advice did not adequately distinguish material choice and chip thermal limiting from safe battery charging/storage. | Corrected instructions; electrical and thermal qualification remain unresolved. | Actual pack limits, module temperature protection, and vehicle operation are unknown. |
| C5 | MED | ASCII cradle STL has eight edges shared by four faces; binary-only correction still leaves eight zero-area triangles at the body seam. | Fixed after reopening: one continuous body loft removes the seam; binary exports pass all strict topology checks. | Export success alone does not establish usable mesh topology. |

## Sequential debate

### C1 — Countersink edge breakout

**Critic:** With the original 5.5 mm screw offset, each center is only 1.345331 mm inside the inset plate boundary. The 2.2 mm head radius breaks out by 0.854669 mm. The 1.2 mm through-hole radius leaves a 0.145331 mm ligament. A subtraction of the head footprint from the actual 128-segment plate footprint produces a nonempty mesh.

**Writer:** Move the shared screw offset to 7 mm. The matching body pilots and plate holes move together. This leaves 1.258036 mm outside each countersink, without changing the footprint.

**Critic:** Accepted. A probe with the pilot subtraction omitted verifies solid body around the new screw positions throughout the pilot depth; no connector, wire, or PCB cavity intrusion. The new edge-margin regression fails before the change and passes afterward.

**Moderator:** Fixed. Retain hardware strength as untested; do not infer pull-out strength from geometric clearance.

### C2 — Seated fit hides an insertion collision

**Critic:** A battery tilted about its contact-end upper edge spans `73*cos(a) + 6.25*sin(a)` along the pocket. At 3 and 4 degrees this is 73.227056 and 73.258154 mm, exceeding the available 73.2 mm. The far lower corner remains below the original chamfer start at Z=14.55 mm, even with an overly generous allowance for the lip's 0.3 mm lift play. Independent OpenSCAD probes confirm positive-volume interference with the original wall.

**Writer:** Preserve the 0.3 mm nominal preload. Move only the chamfer's lower vertex to `floor_z + 2.5`, or Z=11.5 mm by default. This keeps a vertical stop for the seated battery. Update the insertion instructions to hold the clip clear and move the contact end toward the wall before tilting.

**Critic:** Accepted. A slightly shallower temporary candidate, starting at Z=11.55 mm, clears a 0–10 degree sweep sampled every 0.25 degree. The repository regression samples every 0.5 degree, with 0.01 mm removed from each battery face to exclude touching surfaces. It fails on the original chamfer and passes on the correction. Existing seated-fit, far-wall-stop, lip-retention, and clip-retention checks still pass.

**Moderator:** Fixed for the nominal sampled path. The fixture holds the clip clear by assumption and does not simulate springs. This does not settle C3 or qualify insertion force.

### C3 — Clip checks exceed their mechanical evidence

**Critic:** The release test shifts the beam rigidly; a real cantilever rotates the wide tab. The strain assertion assumes a uniform 22 mm beam, whereas the widened tab changes stiffness and motion. An idealized rigid-tab calculation estimates roughly 2.96 mm rear-edge travel when the near hook edge moves 1.5 mm, against about 2.1 mm rear clearance. This is a warning from an approximate model, not proof of actual binding: tab flexibility, loading position, and contact can alter the path.

**Writer:** Rename the test to describe translated-beam clearance. Label the strain limit as a screening assumption, remove the claim that it predicts cracking, and document possible rear-edge interference. Require an unpowered printed release check before use. Do not change the clip geometry based on an unvalidated deformation model.

**Critic:** Accepted as corrected documentation with unresolved mechanics. Neither the test nor the 1.2% chosen limit establishes successful release, fatigue life, or strength at vehicle temperatures.

**Moderator:** Claims corrected; hardware release remains open. Documentation does not fix or qualify a possibly binding clip.

### C4 — Vehicle charging and temperature assumptions

**Critic:** [Samsung's battery care guidance](https://www.samsung.com/us/support/galaxy-battery/care-and-maintenance/) warns against prolonged hot-car exposure. It is general device guidance, not a temperature specification for this loose pack. The [TP4056 manufacturer datasheet](https://www.toppwr.com/uploadfile/file/20230304/640301eae1260.pdf), pages 2, 7, and 10, distinguishes chip thermal regulation from battery sensing through `TEMP`; grounding `TEMP` disables battery-temperature sensing. The actual module circuit and pack limits are absent.

**Writer:** Mark the design as a mechanical prototype. Exclude unattended charging and leaving the battery in a hot parked car. Require actual pack limits and verified battery-temperature cutoff before vehicle charging. Specify regulated 5 V USB input and verification of the actual vehicle socket's ignition switching. Do not invent temperature thresholds, thermistor pad assignments, or faults in an unspecified module.

**Critic:** Accepted. PETG/ASA are candidate materials, not evidence that battery charging or storage is safe in a glove box. The existing two-wire instructions do not establish a validated charging circuit.

**Moderator:** Documentation fixed; vehicle charging remains unqualified.

### C5 — Successful exports contain invalid triangles

**Critic:** Both the original and freshly exported ASCII cradle have eight edges incident to four faces around Z=17.55 mm. OpenSCAD still reports `Simple: yes`. The extrusion's polygon and the rounding loft meet with tiny sliver faces; export quantization exposes the defect.

**Writer, first response:** Binary STL preserves more vertex precision and removes the eight four-face edges. Use binary exports and add exact edge and zero-area checks.

**Critic:** Initially accepted the edge result. Stronger verification then finds eight zero-area triangles in the binary cradle: their vertices share X/Y after float32 quantization. Binary format alone is insufficient.

**Moderator:** Reopen C5 on new evidence. The edge-only result is superseded, not a completed mesh validation.

**Writer, revised response:** Build the entire body with the existing loft, adding its bottom ring at Z=0 and removing the separate overlapping extrusion. This removes the seam at its source and uses less code. Re-export and rerun the integrated geometry and topology checks.

**Critic, revised response:** Accepted. The temporary continuous-loft candidate passes exact edge, orientation, connected-component, positive-volume, and zero-area checks in both ASCII and binary format. The source correction is now applied; the final supplied binary artifacts independently pass the same checks.

**Moderator:** C5 fixed at the source. Regenerate all car artifacts and rerun the complete suite because the body change affects every cradle clearance check. Do not retain the earlier format-only explanation.

## Verification

- Baseline: `python3 -m unittest -v test_car.py test_charger.py` passed the original 10 tests. These checks did not expose C1, C2, or C5.
- The new countersink-margin, insertion-path, and mesh checks were each observed failing before their corresponding correction. The binary-only attempt passed the edge check but failed the new zero-area regression; it was not treated as a successful fix.
- Final combined regression run: `python3 -m unittest -v test_car.py test_charger.py` passed all 12 tests in 125.574 seconds (8 car tests and 4 desktop tests).
- Fresh exports from `car.scad` with OpenSCAD 2021.01, `--hardwarnings --export-format=binstl`, pass for all three parts. Independent checks find exactly two faces per edge, consistent orientation, no zero-area triangles, one connected component per part, and positive signed volume. No welding or mesh repair was applied.

| Part | Triangles | Volume, mm³ | Bounds, mm |
|---|---:|---:|---|
| Cradle | 4,132 | 77,803.142 | 73.600 × 96.150 × 19.550 |
| Bottom, including posts | 1,868 | 16,291.619 | 70.600 × 93.150 × 10.675 |
| Arm | 696 | 527.253 | 36.500 × 10.500 × 6.990 |

- Parameter assertion evaluation accepts defaults, 2.54 mm pitch, four pins with a 10 mm housing, six pins with a 15 mm housing, and the -200 housing height. It rejects 3.0 mm pitch, a 0.75 mm contact wall, insufficient floor thickness, and preload equal to tip protrusion. These are guard checks, not clearance or fit qualification of alternate parts.
- The test harness now evaluates the source assertions rather than bypassing them with `use`, invokes hard warnings, and requires OpenSCAD's explicit empty-object diagnostic before accepting an empty collision result.
- Regenerated all three car STLs and the 1200 × 900 preview; visually inspected the preview and verified copied artifact bytes. The eight preserved desktop/source artifacts match the pre-edit SHA-256 hashes: `charger.scad`, `test_charger.py`, `cradle.stl`, `bottom.stl`, `preview.png`, `connectors.csv`, `REVIEW.md`, and `XC7 battery.SLDPRT`.
- LOW clarification, fast-tracked: the car printing instructions now name the bottom-plate mating face as the bed face, and the height includes the thumb nub. No slicer or printer qualification was performed.

## Integrated Critic review

The independent Critic reviewed the final source changes, tests, car instructions, ledger, and mesh evidence. No new material regression, contradiction, or scope drift was found. The shared screw coordinates preserve matching holes; the chamfer correction preserves preload and the seated stop; the continuous loft removes the overlapping seam. The final combined suite passed afterward.

The Moderator closes C1, C2, and C5 as fixed. C3 and C4 have corrected claims and documented unresolved hardware requirements. This review does not qualify real clip release, fatigue, contact performance, or vehicle charging. No further source correction was requested by the integrated Critic.

## Hardware limits

No physical print, release-force test, spring stroke/force measurement, vibration test, screw pull-out test, adhesive qualification, electrical test, thermal test, or vehicle trial was performed. The battery model was preserved but not independently decoded. Manufacturer connector dimensions were checked against the [BC-25 drawing](https://datasheet.lcsc.com/datasheet/pdf/8153bae77de8ce951813d5d88903037f.pdf?productCode=C707322); actual connector tolerances and soldered wire clearance remain unverified.

The codebase graph was stale for README and did not track the car source/tests. All relevant source was read directly; no coverage claim relies on that graph.

## Follow-up: C3 recess fix (2026-10-12)

The owner approved fixing C3 in geometry, not only documentation. Model: a cantilever beam from the anchor (X=22) to the tab edge (X=5), a rigid tab, release force at the thumb nub (X=0). For the whole hook to clear, the tab's anchor-side edge must move `travel`. With the previous `hook = 1.5` that needed 3.55 mm at the tab's free end against 2.1 mm of recess, and a root strain of 1.34%, above the 1.2% screening limit.

Changes in `car.scad`:

- `free_travel` and `arm_strain` come from that model. The recess behind the beam is sized from `free_travel`; the strain assertion uses `arm_strain` instead of the uniform-beam estimate.
- Default `hook` 1.5 to 1.2 mm, so the default passes: free-end travel 2.96 mm, strain 1.12%. The body is 1.16 mm longer (footprint 73.6 x 97.31 mm).
- `arm_free()` returns `free_travel`; the flexed-beam test shifts the whole free beam by it, an upper bound on the bent beam's sweep.

Verification: all 12 tests pass. Mutations caught: the old recess size fails the flexed-beam test, and `hook = 1.5` fails the strain assertion. The physical release test is still required.

`test_charger.py` now loads the desktop model the same way as `test_car.py`, so its parameter assertions run during tests (`use` skipped them). A 3.0 mm pitch now fails the desktop tests with "pin 2 misses its pad".
