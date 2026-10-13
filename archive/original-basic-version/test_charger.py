"""Run with WSL Python: python3 -m unittest -v test_charger.py (requires OpenSCAD)."""

from pathlib import Path
import os
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).with_name("charger.scad")


class ChargerGeometryTests(unittest.TestCase):
    def render(self, code, *definitions):
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / "check.scad"
            output = Path(folder) / "check.stl"
            source.write_text(f"use <{SOURCE.as_posix()}>\n{code}\n")
            command = ["openscad", "-o", str(output)]
            for definition in definitions:
                command.extend(["-D", definition])
            result = subprocess.run(
                [*command, str(source)], capture_output=True, text=True,
                env={**os.environ, "QT_QPA_PLATFORM": "offscreen"}, timeout=60,
            )
            self.assertNotIn("ERROR:", result.stderr)
            self.assertNotIn("WARNING:", result.stderr)
            return result, output.read_bytes() if output.exists() else b""

    def test_bc25_170_housing_fits_with_tips_at_target_height(self):
        # Drawing: 7.5 x 5 x 1.7 housing; apex Y=3.75, 1.35 above housing.
        # Target apex: X=12.8, Y=14.925, Z=10.5. Inset avoids touching faces.
        result, mesh = self.render("""
            intersection() {
                cradle();
                translate([11.56, 11.185, 7.46]) cube([7.48, 4.98, 1.68]);
            }
        """)
        self.assertIn("Current top level object is empty.", result.stderr)
        self.assertFalse(mesh, "The connector housing intersects the cradle")

    def test_default_parts_render(self):
        for part in ("cradle", "bottom"):
            with self.subTest(part=part):
                result, mesh = self.render(f"{part}();")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertTrue(mesh)
                self.assertRegex(result.stderr, r"Simple:\s+yes")

    def test_window_clears_nominal_leaf_envelope(self):
        # Approximate drawing envelope: housing-relative Y=2.0..4.3 above its top.
        # This checks nominal floor clearance, not the spring's permitted stroke.
        result, mesh = self.render("""
            intersection() {
                cradle();
                translate([12.35, 13.175, 9.16]) cube([0.9, 2.3, 1.33]);
            }
        """)
        self.assertIn("Current top level object is empty.", result.stderr)
        self.assertFalse(mesh, "The floor obstructs the nominal leaf envelope")

    def test_plate_posts_back_connector_without_collision(self):
        # Plate sits 2.5 below the cradle; Z>0.1 skips the shared seating face. Housing underside Z=7.45; posts stop shim_gap=0.2 below.
        for name, code, empty in (
            ("posts vs cradle", "intersection() { cradle(); translate([0, 0, -2.5]) bottom(); translate([-1, -1, 0.1]) cube(200); }", True),
            ("posts vs housing", "intersection() { translate([0, 0, -2.5]) bottom(); translate([11.55, 11.175, 7.45]) cube([7.5, 5, 1.7]); }", True),
            ("posts reach housing", "intersection() { translate([0, 0, -2.5]) bottom(); translate([11.55, 11.175, 7.1]) cube([7.5, 5, 0.1]); }", False),
        ):
            with self.subTest(name):
                _, mesh = self.render(code)
                self.assertEqual(not mesh, empty)


if __name__ == "__main__":
    unittest.main()
