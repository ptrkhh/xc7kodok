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
            # Keep parameter assertions active (`use` skips them); replace only the part dispatcher.
            model = SOURCE.read_text().rsplit('\nif (part == "cradle")', 1)[0]
            source.write_text(f"{model}\n{code}\n")
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

    def assert_empty(self, code, message):
        result, mesh = self.render(code)
        self.assertIn("Current top level object is empty.", result.stderr)
        self.assertFalse(mesh, message)

    def test_bc25_170_housing_fits_with_tips_at_target_height(self):
        # Drawing: 7.5 x 5 x 1.7 housing; apex 1.35 above it, 3.75 from its -Y face.
        # Shrunk 0.01 per side so touching faces do not count.
        self.assert_empty("""
            o = con_origin(); s = con_size(); t = pin1_tip();
            assert(s == [7.5, 5, 1.7]);
            assert(abs(t[2] - (o[2] + s[2] + 1.35)) < 1e-6 && abs(t[1] - (o[1] + 3.75)) < 1e-6);
            intersection() {
                cradle();
                translate(o + [0.01, 0.01, 0.01]) cube(s - [0.02, 0.02, 0.02]);
            }
        """, "The connector housing intersects the cradle")

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
        self.assert_empty("""
            o = con_origin(); s = con_size(); t = pin1_tip();
            intersection() {
                cradle();
                translate([t[0] - 0.45, o[1] + 2.0, o[2] + s[2] + 0.01])
                    cube([0.9, 2.3, t[2] - o[2] - s[2] - 0.02]);
            }
        """, "The floor obstructs the nominal leaf envelope")

    def test_plate_posts_back_connector_without_collision(self):
        # Plate top is Z=0 in place; Z>0.1 skips the shared seating face. Posts stop 0.2 below the housing.
        cases = (
            ("posts vs cradle", "intersection() { cradle(); bottom(); translate([-100, -100, 0.1]) cube(200); }", True),
            ("posts vs housing", "o = con_origin(); intersection() { bottom(); translate(o) cube(con_size()); }", True),
            ("posts reach housing", "o = con_origin(); intersection() { bottom(); translate(o - [0, 0, 0.35]) cube([7.5, 5, 0.1]); }", False),
        )
        for name, code, empty in cases:
            with self.subTest(name):
                _, mesh = self.render(code)
                self.assertEqual(not mesh, empty)

if __name__ == "__main__":
    unittest.main()
