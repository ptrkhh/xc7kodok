// Samsung Galaxy XCover 7 battery desktop charger (upright, contacts down).
// Render one part at a time:  openscad -D 'part="cradle"' -o cradle.stl charger.scad
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

// ---- Body ----
wall = 2.0;           // outer shell
top_t = 2.0;
ws = 2.5;             // slot collar wall
base_h = 14;
floor_z = 10;         // slot floor height
slot_depth = 20;      // floor to collar top
front_margin = 9;     // room for +/- marks in front of the collar
plate_t = 2.5;
boss_d = 6; pilot_d = 1.7; screw_d = 2.4; head_d = 4.2;

$fn = 40;
eps = 0.01;

slot_x = bat_l + 2*clr;
slot_y = bat_t + 2*clr;
BX = slot_x + 2*ws + 2*3;
BY = 55;
sx0 = (BX - slot_x)/2;           // slot inner -X face ("corner" side)
sy0 = front_margin + ws;          // slot inner front face
slot_cy = sy0 + slot_y/2;
pin_x = function(i) sx0 + clr + pad1_x + i*con_pitch; // i = 0..con_n-1
t_contact = con_tip - tip_protrusion; // floor thickness over the connector
pocket_top = floor_z - t_contact;
pcb_x0 = (BX - pcb_w)/2;
pcb_y1 = BY - wall;               // USB-end PCB edge at the inner back wall
pcb_y0 = pcb_y1 - pcb_l;
bosses = [for (x = [wall + boss_d/2 - 1, BX - wall - boss_d/2 + 1], y = [wall + boss_d/2 - 1, BY - wall - boss_d/2 + 1]) [x, y]];

// ---- Fit checks ----
for (i = [0 : con_n - 1]) if (i <= 5) {
    pad_c = sx0 + clr + pad1_x + i*pad_pitch;
    // contact nose must stay on its pad even with the battery shifted by clr
    assert(abs(pin_x(i) - pad_c) + clr + finger_w/2 <= pad_w/2 + eps,
        str("pin ", i+1, " misses its pad: check con_pitch / clr"));
}
assert(t_contact >= 0.8, "floor over connector too thin: raise con_tip or lower tip_protrusion");
assert(pocket_top >= con_d, "connector longer than the pocket: raise floor_z");
assert(floor_z + slot_depth > base_h, "collar must rise above base");

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
    union() {
        difference() {
            cube([BX, BY, base_h]);
            translate([wall, wall, -eps]) cube([BX - 2*wall, BY - 2*wall, base_h - top_t + eps]);
        }
        // slot well + collar, solid down to the bed so nothing floats while printing
        translate([sx0 - ws, sy0 - ws, 0])
            cube([slot_x + 2*ws, slot_y + 2*ws, floor_z + slot_depth]);
        for (b = bosses) translate([b[0], b[1], 0]) cylinder(d = boss_d, h = base_h);
    }
    slot_cut();
    // connector pocket, open at the bottom
    translate([pin_x(0) - pin1_off - con_fit/2, slot_cy - con_tip_y - con_fit/2, -1])
        cube([con_w + con_fit, con_h + con_fit, pocket_top + 1]);
    // wire channel from the pocket to the board bay
    translate([pin_x(0) - pin1_off + con_w/2 - 2, slot_cy, -1])
        cube([4, sy0 + slot_y + ws + 1 - slot_cy, 3.5]);
    // contact window through the floor
    translate([pin_x(0) - win_margin, slot_cy - win_y/2, pocket_top - eps])
        cube([(con_n-1)*con_pitch + 2*win_margin, win_y, t_contact + 1]);
    // USB-C: receptacle hole, outside recess so the plug seats fully
    usb_z = pcb_t + usb_hgt/2;
    translate([BX/2 - (usb_w + 0.8)/2, BY - wall - 1, usb_z - (usb_hgt + 0.8)/2])
        cube([usb_w + 0.8, wall + 2, usb_hgt + 0.8]);
    translate([BX/2 - 6.5, BY - (wall - usb_overhang), usb_z - 3.5])
        cube([13, wall, 7]);
    // LED window
    translate([BX/2 - led_win[0]/2, pcb_y1 - led_from_usb - led_win[1]/2, base_h - top_t - 1])
        cube([led_win[0], led_win[1], top_t + 2]);
    // screw pilot holes
    for (b = bosses) translate([b[0], b[1], -eps]) cylinder(d = pilot_d, h = base_h - top_t);
    // polarity marks in front of pins 1 and 3
    for (m = [[0, "+"], [2, "-"]]) translate([pin_x(m[0]), front_margin/2, base_h - 0.6])
        linear_extrude(1) text(m[1], size = 5, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
}

module bottom() difference() {
    union() {
        cube([BX, BY, plate_t]);
        // PCB rails (USB end open)
        translate([0, 0, plate_t]) difference() {
            translate([pcb_x0 - 0.3 - 1.2, pcb_y0 - 0.3 - 1.2, 0]) cube([pcb_w + 0.6 + 2.4, pcb_l + 0.3 + 1.2, 2]);
            translate([pcb_x0 - 0.3, pcb_y0 - 0.3, -1]) cube([pcb_w + 0.6, pcb_l + 1, 4]);
        }
        // corner posts backing the connector housing; wires pass between them
        for (x = [pin_x(0) - pin1_off, pin_x(0) - pin1_off + con_w - 1.5],
             y = [slot_cy - con_tip_y, slot_cy - con_tip_y + con_h - 1.5])
            translate([x, y, plate_t]) cube([1.5, 1.5, pocket_top - con_d - shim_gap]);
    }
    for (b = bosses) translate([b[0], b[1], -eps]) {
        cylinder(d = screw_d, h = plate_t + 1);
        cylinder(d = head_d, h = 1.2);
    }
}

if (part == "cradle") cradle();
else if (part == "bottom") bottom();
else {
    cradle();
    color("gray") translate([0, 0, -plate_t]) bottom();
    %translate([sx0 + clr, sy0 + clr, floor_z + tip_protrusion]) cube([bat_l, bat_t, bat_h]);
}
