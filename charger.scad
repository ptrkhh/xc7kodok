// Samsung Galaxy XCover 7 battery desktop charger (upright, contacts down).
// Render one part at a time:  openscad -D 'part="cradle"' -o stl/cradle.stl charger.scad
// part = "cradle" | "bottom" | "assembly" (preview only)
part = "assembly";

// ---- Battery (from "XC7 battery.SLDPRT") ----
bat_l = 63;       // along the pad row
bat_t = 6.25;     // thickness
bat_h = 73;       // standing height
pad_w = 2.0;      // pad width along the row
pad_pitch = 2.5;
pad1_x = 7.0;     // pad 1 (+) center from the "corner" edge; pad 3 (-) = pad1_x + 2*pitch
pad_cy = bat_t/2; // pads are centered in the thickness

// ---- Calibration knobs ----
clr = 0.3;            // slot clearance per side
tip_protrusion = 0.5; // free contact tip height above slot floor (battery rests on tips, gravity only)
win_y = 4.0;          // clears the nominal BC-25 leaf ramp; verify actual compressed sweep
win_margin = 0.8;     // window margin past outer pin centers

// ---- Connector (defaults: BC-25-3P-170 drawing; measure the actual part) ----
// Installed axes: pitch X, housing depth Y, contacts up (+Z), PCB face down (-Z).
con_n = 3;            // pin count (3 or 4 both fine; pin 1 over pad 1)
con_pitch = 2.5;
con_w = 7.5;          // housing length along the pitch
con_h = 5.0;          // installed housing depth along Y
con_d = 1.7;          // installed housing height along Z (DIM A; -200 variant: 2.0)
con_tip = 1.35;       // free tip above housing; drawing tolerance +/-0.2, not working stroke
con_tip_y = 3.75;     // nominal free apex from housing -Y face; measure spring sweep
pin1_off = (con_w - (con_n-1)*con_pitch)/2; // pin 1 center from housing -X end
finger_w = 0.9;       // contact nose width, for the fit check below
con_fit = 0.2;        // pocket oversize (total)
shim_gap = 0.2;       // gap between plate posts and connector underside, fill with glue

// ---- TP4056 USB-C module (measure yours) ----
pcb_w = 17.5;         // across (X)
pcb_l = 28;           // along (Y), USB-C at the back
pcb_t = 1.6;
usb_w = 9.0; usb_hgt = 3.3; // receptacle
usb_overhang = 0.8;   // receptacle front past the PCB edge
led_from_usb = 6;     // LED window center from the USB-end PCB edge
led_win = [8, 3];     // covers both LEDs

// ---- Body: squircle foot, concave flare into a neck around the slot ----
foot = [45, 38];      // foot half-sizes X, Y
foot_n = 4;           // foot superellipse exponent (2 = ellipse, higher = squarer)
neck_n = 10;          // neck superellipse exponent
ws = 2.5;             // neck wall around the slot
skirt_h = 10;         // vertical skirt (USB-C, board bay) before the flare starts
neck_top = 40;        // collar top above the bed
flare_p = 2.2;        // flare concavity (1 = straight taper)
floor_z = 10;         // slot floor height
bay_h = 7;            // board bay height (flat bridged ceiling)
back_wall = 2;        // skirt thickness behind the USB-C end of the PCB
shadow_gap = 1.5;     // bottom plate inset from the foot edge (floating look)
plate_t = 2.5;
screws = [[-32, -26], [32, -26], [-32, 26], [32, 26]];
pilot_d = 1.7; screw_d = 2.4; head_d = 4.4;
mark_z = neck_top - 7; // +/- marks on the neck front

$fn = 40;
eps = 0.01;
N = 128;              // points per superellipse ring

slot_x = bat_l + 2*clr;
slot_y = bat_t + 2*clr;
sx0 = -slot_x/2;                  // slot inner -X face ("corner" side)
sy0 = -slot_y/2;
slot_cy = 0;
neck = [slot_x/2 + ws, slot_y/2 + ws];
slot_depth = neck_top - floor_z;
pin_x = function(i) sx0 + clr + pad1_x + i*con_pitch; // i = 0..con_n-1
t_contact = con_tip - tip_protrusion; // floor thickness over the connector
pocket_top = floor_z - t_contact;
function con_origin() = [pin_x(0) - pin1_off, slot_cy - con_tip_y, pocket_top - con_d]; // nominal housing corner
function con_size() = [con_w, con_h, con_d];
function pin1_tip() = [pin_x(0), slot_cy, floor_z + tip_protrusion]; // free apex of pin 1
pcb_x0 = -pcb_w/2;
pcb_y1 = foot[1] - back_wall;     // USB-end PCB edge
pcb_y0 = pcb_y1 - pcb_l;
rail = 1.2; rail_gap = 0.3;

// superellipse ring; flare(t): t=0 foot, t=1 neck
sq = function(a, b, n, z) [for (i = [0 : N-1]) let(th = 360*i/N, c = cos(th), s = sin(th))
    [a*sign(c)*pow(abs(c), 2/n), b*sign(s)*pow(abs(s), 2/n), z]];
flare = function(t) let(k = pow(1 - t, flare_p))
    [neck[0] + (foot[0] - neck[0])*k, neck[1] + (foot[1] - neck[1])*k, foot_n + (neck_n - foot_n)*t];
flare_z = function(t) skirt_h + t*(neck_top - skirt_h);
// outer surface Y at (x, z), for placing marks on the neck front
surf_y = function(x, z) let(f = flare((z - skirt_h)/(neck_top - skirt_h)))
    f[1]*pow(1 - pow(abs(x)/f[0], f[2]), 1/f[2]);

// ---- Fit checks ----
for (i = [0 : con_n - 1]) if (i <= 5) {
    pad_c = sx0 + clr + pad1_x + i*pad_pitch;
    // contact nose must stay on its pad even with the battery shifted by clr
    assert(abs(pin_x(i) - pad_c) + clr + finger_w/2 <= pad_w/2 + eps,
        str("pin ", i+1, " misses its pad: check con_pitch / clr"));
}
assert(t_contact >= 0.8, "floor over connector too thin: raise con_tip or lower tip_protrusion");
assert(pocket_top >= con_d, "connector longer than the pocket: raise floor_z");
assert(bay_h + 2 <= skirt_h, "board bay must stay inside the skirt");
assert(pcb_y0 - rail - rail_gap > neck[1], "board bay reaches under the slot: enlarge foot[1]");

module loft(rings) {
    n = len(rings);
    pts = [for (r = rings) each r];
    polyhedron(pts, [
        [for (i = [0 : N-1]) i],
        [for (i = [N-1 : -1 : 0]) (n-1)*N + i],
        for (j = [0 : n-2], i = [0 : N-1])
            [j*N + i, (j+1)*N + i, (j+1)*N + (i+1)%N, j*N + (i+1)%N]
    ]);
}

module foot2d(inset = 0) offset(-inset) polygon([for (p = sq(foot[0], foot[1], foot_n, 0)) [p[0], p[1]]]);

module body() {
    linear_extrude(skirt_h + eps) foot2d();
    loft([for (j = [0 : 40]) let(t = j/40, f = flare(t)) sq(f[0], f[1], f[2], flare_z(t))]);
}

module slot_cut()
    translate([sx0, sy0, floor_z]) {
        cube([slot_x, slot_y, slot_depth + 1]);
        // entry chamfer
        translate([0, 0, slot_depth - 1 + eps])
            hull() {
                cube([slot_x, slot_y, eps]);
                translate([-1.2, -1.2, 1.2]) cube([slot_x + 2.4, slot_y + 2.4, eps]);
            }
    }

module cradle() difference() {
    body();
    slot_cut();
    // connector pocket, open at the bottom
    translate(con_origin() - [con_fit/2, con_fit/2, 0]) translate([0, 0, -con_origin()[2] - 1])
        cube([con_w + con_fit, con_h + con_fit, pocket_top + 1]);
    // contact window through the floor
    translate([pin_x(0) - win_margin, slot_cy - win_y/2, pocket_top - eps])
        cube([(con_n-1)*con_pitch + 2*win_margin, win_y, t_contact + 1]);
    // board bay
    bay = [pcb_w + 2*(rail_gap + rail + 0.3), pcb_l + rail_gap + rail + 0.3];
    translate([-bay[0]/2, pcb_y1 - bay[1], -1]) cube([bay[0], bay[1] + eps, bay_h + 1]);
    // wire channel: pocket -> bay
    ch_y = pcb_y0 - rail - rail_gap - 2;
    translate([con_origin()[0] + con_w/2 - 2, slot_cy, -1]) cube([4, ch_y + 4 - slot_cy, 4.5]);
    translate([con_origin()[0] + con_w/2 - 2, ch_y, -1]) cube([-bay[0]/2 + 2 - con_origin()[0] - con_w/2 + 2, 4, 4.5]);
    // USB-C: receptacle hole, outside recess so the plug seats fully
    usb_z = pcb_t + usb_hgt/2;
    translate([-(usb_w + 0.8)/2, pcb_y1 - 1, usb_z - (usb_hgt + 0.8)/2])
        cube([usb_w + 0.8, back_wall + 2, usb_hgt + 0.8]);
    translate([-6.5, pcb_y1 + usb_overhang, usb_z - 3.5]) cube([13, back_wall + 1, 7]);
    // LED window
    translate([-led_win[0]/2, pcb_y1 - led_from_usb - led_win[1]/2, bay_h - 1])
        cube([led_win[0], led_win[1], neck_top]);
    // screw pilots into the solid foot
    for (s = screws) translate([s[0], s[1], -eps]) cylinder(d = pilot_d, h = 10);
    // polarity marks on the neck front, over pins 1 and 3
    for (m = [[0, "+"], [2, "-"]]) let(x = pin_x(m[0]))
        translate([x, -surf_y(x, mark_z) + 0.6, mark_z]) rotate([90, 0, 0])
            linear_extrude(2) text(m[1], size = 5, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
}

// modeled in place: plate top at z=0, prints flat
module bottom() translate([0, 0, -plate_t]) difference() {
    union() {
        linear_extrude(plate_t) foot2d(shadow_gap);
        translate([0, 0, plate_t]) {
            // PCB rails (USB end open)
            difference() {
                translate([pcb_x0 - rail_gap - rail, pcb_y0 - rail_gap - rail, 0]) cube([pcb_w + 2*(rail_gap + rail), pcb_l + rail_gap + rail, 2]);
                translate([pcb_x0 - rail_gap, pcb_y0 - rail_gap, -1]) cube([pcb_w + 2*rail_gap, pcb_l + 1, 4]);
            }
            // corner posts backing the connector housing; wires pass between them
            for (x = [con_origin()[0], con_origin()[0] + con_w - 1.5], y = [con_origin()[1], con_origin()[1] + con_h - 1.5])
                translate([x, y, 0]) cube([1.5, 1.5, con_origin()[2] - shim_gap]);
        }
    }
    for (s = screws) translate([s[0], s[1], -eps]) {
        cylinder(d = screw_d, h = plate_t + 1);
        cylinder(d1 = head_d, d2 = screw_d, h = (head_d - screw_d)/2); // countersink
    }
}

if (part == "cradle") cradle();
else if (part == "bottom") bottom();
else {
    cradle();
    color("gray") bottom();
    %translate([sx0 + clr, sy0 + clr, floor_z + tip_protrusion]) cube([bat_l, bat_t, bat_h]);
}
