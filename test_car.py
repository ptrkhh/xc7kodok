"""Run with WSL Python: python3 -m unittest -v test_car.py (requires OpenSCAD)."""

from pathlib import Path
from collections import Counter
import os
import struct
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).with_name("car.scad")


class CarGeometryTests(unittest.TestCase):
    def render(self, code):
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / "check.scad"
            output = Path(folder) / "check.stl"
            # Keep parameter assertions active; replace only the part dispatcher.
            model = SOURCE.read_text().rsplit('\nif (part == "cradle")', 1)[0]
            source.write_text(f"{model}\n{code}\n")
            result = subprocess.run(
                ["openscad", "--hardwarnings", "--export-format=binstl", "-o", str(output), str(source)], capture_output=True, text=True,
                env={**os.environ, "QT_QPA_PLATFORM": "offscreen"}, timeout=120,
            )
            self.assertNotIn("ERROR:", result.stderr)
            self.assertNotIn("WARNING:", result.stderr)
            if output.exists():
                self.assertEqual(result.returncode, 0, result.stderr)
            else:
                self.assertIn("Current top level object is empty.", result.stderr)
            return result, output.read_bytes() if output.exists() else b""

    def check(self, cases):
        for name, code, empty in cases:
            with self.subTest(name):
                _, mesh = self.render(code)
                self.assertEqual(not mesh, empty)

    def test_default_parts_render(self):
        for part in ("cradle", "bottom", "arm"):
            with self.subTest(part=part):
                result, mesh = self.render(f"{part}();")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertTrue(mesh)
                self.assertRegex(result.stderr, r"Simple:\s+yes")
                if mesh.startswith(b"solid"):
                    vertices = [tuple(map(float, line.split()[1:]))
                                for line in mesh.decode().splitlines()
                                if line.strip().startswith("vertex")]
                else:
                    count = struct.unpack_from("<I", mesh, 80)[0]
                    self.assertEqual(len(mesh), 84 + 50 * count)
                    vertices = [struct.unpack_from("<3f", mesh, 84 + 50*i + 12 + 12*j)
                                for i in range(count) for j in range(3)]
                edges = Counter(tuple(sorted((vertices[i+j], vertices[i+(j+1)%3])))
                                for i in range(0, len(vertices), 3) for j in range(3))
                self.assertTrue(all(count == 2 for count in edges.values()),
                                "Every STL edge must belong to exactly two faces")
                for i in range(0, len(vertices), 3):
                    a, b, c = vertices[i:i+3]
                    u = [b[j] - a[j] for j in range(3)]
                    v = [c[j] - a[j] for j in range(3)]
                    self.assertTrue(any(u[j]*v[(j+1)%3] != u[(j+1)%3]*v[j]
                                        for j in range(3)), "STL triangle has zero area")

    def test_bottom_screw_heads_have_edge_margin(self):
        self.check([("1 mm around each countersink", """
            difference() {
                for (s = screws) translate([s[0], s[1], 0])
                    cylinder(d = head_d + 2, h = 1);
                linear_extrude(1) foot2d(shadow_gap);
            }
        """, True)])

    def test_bc25_170_housing_fits_with_tips_at_target(self):
        # Drawing: 7.5 x 5 x 1.7 housing; apex 1.35 out of it, 3.75 from its bottom face.
        # Housing shrunk 0.01 per side so touching faces do not count.
        self.check([("housing vs cradle", """
            o = con_origin(); s = con_size(); t = pin1_tip();
            assert(s == [7.5, 1.7, 5]);
            assert(abs(t[1] - (o[1] + s[1] + 1.35)) < 1e-6 && abs(t[2] - (o[2] + 3.75)) < 1e-6);
            assert(abs(t[2] - (bat_origin()[2] + bat_size()[2]/2)) < 1e-6);
            intersection() { cradle(); translate(o + [0.01, 0.01, 0.01]) cube(s - [0.02, 0.02, 0.02]); }
        """, True)])

    def test_window_clears_leaf_in_place_and_on_insertion(self):
        # Nominal leaf envelope (housing-relative 2.0..4.3), swept down to the plate: the housing slides up from below.
        self.check([("leaf envelope", """
            o = con_origin(); s = con_size(); t = pin1_tip();
            intersection() { cradle();
                translate([t[0] - 0.45, o[1] + s[1] + 0.01, 0.01]) cube([0.9, t[1] - o[1] - s[1] - 0.02, o[2] + 4.3]); }
        """, True)])

    def test_plate_posts_back_connector_without_collision(self):
        # Plate top is Z=0 in place; Z>0.1 skips the shared seating face. Posts stop 0.2 below the housing.
        self.check([
            ("posts vs cradle", "intersection() { cradle(); bottom(); translate([-100, -100, 0.1]) cube(200); }", True),
            ("posts vs housing", "intersection() { bottom(); translate(con_origin()) cube(con_size()); }", True),
            ("posts reach housing", "o = con_origin(); intersection() { bottom(); translate(o - [0, 0, 0.35]) cube([7.5, 1.7, 0.1]); }", False),
        ])

    def test_battery_seats_and_is_held(self):
        bat = "translate(bat_origin() + [0.01, 0.01, 0.01]) cube(bat_size() - [0.02, 0.02, 0.02]);"
        lifted = "translate(bat_origin() + [0.01, 0.01, 0.4]) cube(bat_size() - [0.02, 0.02, 0.02]);"
        self.check([
            ("battery vs cradle", f"intersection() {{ cradle(); {bat} }}", True),
            ("battery vs arm", f"intersection() {{ arm(); {bat} }}", True),
            ("lip stops lift", f"intersection() {{ cradle(); {lifted} }}", False),
            ("clip stops lift", f"intersection() {{ arm(); {lifted} }}", False),
            ("far wall stops slide", "intersection() { cradle(); translate(bat_origin() + [0.01, 0.05, 0.01]) cube(bat_size() - [0.02, 0.02, 0.02]); }", False),
        ])

    def test_battery_tilts_past_far_wall(self):
        # Push toward the contacts, then lift the far end with the clip released.
        # Shrink 0.01 mm per face to exclude touching surfaces; sample every 0.5 degree.
        self.check([("insertion/removal tilt", """
            intersection() {
                cradle();
                union() {
                    for (a = [0 : 0.5 : 10])
                        translate([bat_origin()[0], 0.01, floor_z + bat_t])
                            rotate([a, 0, 0]) translate([0.01, 0.01, -bat_t + 0.01])
                                cube(bat_size() - [0.02, 0.02, 0.02]);
                }
            }
        """, True)])

    def test_arm_fits_and_translated_beam_clears(self):
        # Shifts the whole free beam by the tab free-end travel: an upper bound on the bent beam's sweep.
        self.check([
            ("arm vs cradle", "intersection() { cradle(); arm(); translate([-100, -100, hold_z() + 0.1]) cube(200); }", True),
            ("flexed beam vs cradle", """
                f = arm_free();
                intersection() { cradle(); translate([0, f[1], 0]) intersection() { arm(); translate([-100, -100, -100]) cube([100 + f[0], 300, 300]); } }
            """, True),
        ])


if __name__ == "__main__":
    unittest.main()
