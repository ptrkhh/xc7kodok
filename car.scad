// Samsung Galaxy XCover 7 battery car charger: battery lies flat in a pocket, like the phone's own battery bay.
// Spring contacts in the end wall push the battery against the far wall; a contact-end lip and a clip arm stop it lifting.
// Render one part at a time: openscad --export-format=binstl -D 'part="cradle"' -o stl/car_cradle.stl car.scad
// part = "cradle" | "bottom" | "arm" | "assembly" (preview only)
part = "assembly";

// ---- Battery (from "XC7 battery.SLDPRT") ----
bat_l = 63;       // across the pocket, along the pad row
bat_t = 6.25;     // thickness (lies flat)
bat_h = 73;       // along the pocket, contact end first
pad_w = 2.0;      // pad width along the row
pad_h = 3.25;     // pad height across the thickness, centered
pad_pitch = 2.5;
pad1_x = 7.0;     // pad 1 (+) center from the "corner" edge; pad 3 (-) = pad1_x + 2*pitch

// ---- Calibration knobs ----
clr = 0.3;            // pocket clearance per side (X)
clr_z = 0.3;          // battery lift play under the lip and the clip
tip_protrusion = 0.5; // free contact tip past the end wall
preload = 0.3;        // spring compression with the battery seated; sets the pocket length
apex_tol = 1.0;       // contact apex position uncertainty across the pad (Z); measure the spring sweep
win_y = 4.0;          // contact window height
win_margin = 0.8;     // window margin past outer pin centers

// ---- Connector (defaults: BC-25-3P-170 drawing; measure the actual part) ----
// Installed axes: pitch X, contacts toward the battery (+Y), housing -Y face (drawing) down.
con_n = 3;
con_pitch = 2.5;
con_w = 7.5;          // housing length along the pitch
con_h = 5.0;          // housing depth, installed vertical (Z)
con_d = 1.7;          // housing height, installed along Y (DIM A; -200 variant: 2.0)
con_tip = 1.35;       // free tip above housing; drawing tolerance +/-0.2, not working stroke
con_tip_y = 3.75;     // nominal free apex from the housing bottom face
pin1_off = (con_w - (con_n-1)*con_pitch)/2;
finger_w = 0.9;       // contact nose width
con_fit = 0.2;        // shaft oversize (total)
tail = 2.0;           // space behind the housing for solder tails and wires
shim_gap = 0.2;       // gap between plate posts and housing underside, fill with glue

// ---- TP4056 USB-C module (measure yours) ----
pcb_w = 17.5; pcb_l = 28; pcb_t = 1.6;
usb_w = 9.0; usb_hgt = 3.3;
usb_overhang = 0.8;
led_from_usb = 6;
led_win = [8, 3];

// ---- Body ----
side_w = 5;           // side wall at the pocket
end_w = 2.5;          // wall behind the connector shaft
floor_z = 9;          // pocket floor height (board bay underneath)
bay_h = 7;
back_wall = 2;        // wall behind the USB-C end of the PCB
lip = 1.2;            // contact-end lip over the battery
gap = 1.5;            // pocket runs past the far wall above the battery: room to drop the battery in
foot_n = 8;           // footprint superellipse exponent
edge_r = 2;           // top edge round-over
shadow_gap = 1.5;     // bottom plate inset (tape goes on the plate)
plate_t = 2.5;
pilot_d = 1.7; screw_d = 2.4; head_d = 4.4;

// ---- Clip arm (separate part, printed flat so it bends along its layers) ----
arm_t = 1.6;          // beam thickness (bending direction)
arm_h = 4;            // arm height; arm top is flush with the cradle top
hook = 1.2;           // tab overhang over the battery
tab_w = 10;
anchor = [22, 31.5];  // anchor block X range; beam flexes from the tab edge (X=tab_w/2) to anchor[0]
anchor_l = 7.5;
nub_h = 3;            // thumb nub: push it away from the battery to release
arm_strain_max = 0.012; // screening limit only; calibrate for the actual print and temperature

$fn = 40;
eps = 0.01;
N = 128;

slot_x = bat_l + 2*clr;
sx0 = -slot_x/2;
t_contact = con_tip - tip_protrusion; // wall over the connector
y_bat = tip_protrusion - preload;     // battery contact face, seated
y_far = y_bat + bat_h;                // springs push the battery against this wall
z_hold = floor_z + bat_t + clr_z;     // lip and tab underside
z_top = z_hold + arm_h;
apex_z = floor_z + bat_t/2;           // pad center height
pin_x = function(i) sx0 + clr + pad1_x + i*con_pitch;
travel = hook + 0.3;                  // tab release travel
beam_y = y_far + gap;
// Clip release, cantilever with a rigid tab, pushed at the nub (X=0): F/EI that moves the
// tab's anchor-side edge by travel, then the tab's free-end travel and the root strain.
flex_l = anchor[0] - tab_w/2;
k_rel = travel/(pow(flex_l, 3)/3 + tab_w/2*pow(flex_l, 2)/2);
free_travel = travel + tab_w*k_rel*(pow(flex_l, 2)/2 + tab_w/2*flex_l);
arm_strain = k_rel*anchor[0]*arm_t/2;
ledge_y = beam_y + arm_t + free_travel + 0.3; // recess edge, clears the flexed tab's free end
led_y = ledge_y + 1 + led_win[1]/2;
pcb_y1 = led_y + led_from_usb;        // USB-end PCB edge
pcb_y0 = pcb_y1 - pcb_l;
pcb_x0 = -pcb_w/2;
y_out = pcb_y1 + back_wall;
rail = 1.2; rail_gap = 0.3;
function con_origin() = [pin_x(0) - pin1_off, -t_contact - con_d, apex_z - con_tip_y]; // housing corner
function con_size() = [con_w, con_d, con_h];
function pin1_tip() = [pin_x(0), tip_protrusion, apex_z]; // free apex of pin 1
function bat_origin() = [sx0 + clr, y_bat, floor_z];
function bat_size() = [bat_l, bat_h, bat_t];
function hold_z() = z_hold;
function arm_free() = [anchor[0] - 1, free_travel]; // beam part that flexes, its largest release travel
y_in = con_origin()[1] - tail - con_fit - end_w;
foot = [slot_x/2 + side_w, (y_out - y_in)/2];
foot_cy = (y_out + y_in)/2;
// Leave at least 1 mm outside the countersinks on the inset plate.
screws = [for (sx = [-1, 1], sy = [-1, 1]) [sx*(foot[0] - 7), foot_cy + sy*(foot[1] - 7)]];
arm_screws = [[anchor[0] + 2.5, beam_y + 4], [anchor[1] - 2.5, beam_y + 4]];

sq = function(a, b, n, z) [for (i = [0 : N-1]) let(th = 360*i/N, c = cos(th), s = sin(th))
    [a*sign(c)*pow(abs(c), 2/n), b*sign(s)*pow(abs(s), 2/n), z]];
inside = function(p, m) pow(abs(p[0])/(foot[0] - m), foot_n) + pow(abs(p[1] - foot_cy)/(foot[1] - m), foot_n) <= 1;

// ---- Fit checks ----
for (i = [0 : con_n - 1]) if (i <= 5) {
    pad_c = sx0 + clr + pad1_x + i*pad_pitch;
    assert(abs(pin_x(i) - pad_c) + clr + finger_w/2 <= pad_w/2 + eps,
        str("pin ", i+1, " misses its pad: check con_pitch / clr"));
}
assert(clr_z + apex_tol <= pad_h/2, "contact apex may leave the pad: lower clr_z or apex_tol");
assert(t_contact >= 0.8, "wall over connector too thin: raise con_tip or lower tip_protrusion");
assert(preload > 0 && preload < tip_protrusion, "preload must be between 0 and tip_protrusion");
assert(con_origin()[2] - shim_gap >= 1, "connector too low for the plate posts: raise floor_z");
assert(bay_h + 2 <= floor_z, "board bay must stay under the pocket floor");
// Beam-theory estimate only; the printed clip still needs a release test.
assert(arm_strain <= arm_strain_max, str("clip root strain ", arm_strain, " exceeds limit: lower hook or arm_t"));
for (p = [[sx0, 0], [-sx0, 0], [sx0, ledge_y], [-sx0, ledge_y], [anchor[1], beam_y + anchor_l],
          [con_origin()[0], con_origin()[1] - tail - con_fit], [con_origin()[0] + con_w, con_origin()[1] - tail - con_fit]])
    assert(inside(p, 1.5), str("wall thinner than 1.5 mm at ", p, ": enlarge side_w / end_w"));

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

module foot2d(inset = 0) translate([0, foot_cy]) offset(-inset) polygon([for (p = sq(foot[0], foot[1], foot_n, 0)) [p[0], p[1]]]);

module body() {
    // One continuous surface avoids quantized sliver faces at the rounded seam.
    translate([0, foot_cy, 0])
        loft([sq(foot[0], foot[1], foot_n, 0), for (j = [0 : 8]) let(a = 90*j/8, i = edge_r*(1 - cos(a)))
            sq(foot[0] - i, foot[1] - i, foot_n, z_top - edge_r + edge_r*sin(a))]);
}

// YZ profile extruded across X
module yz(x0, w, pts) translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(w) polygon(pts);

module cradle() difference() {
    body();
    // pocket, contact-end lip, room above the battery past the far wall
    translate([sx0, lip, floor_z]) cube([slot_x, y_far - lip, z_top]);
    translate([sx0, -eps, floor_z]) cube([slot_x, lip + 2*eps, z_hold - floor_z]);
    translate([sx0, lip, z_hold - 0.5]) cube([slot_x, y_far + gap - lip, z_top]);
    // Relieve the tilted battery's bottom corner; retain a 2.5 mm seated stop.
    yz(sx0, slot_x, [[y_far - eps, floor_z + 2.5], [y_far + gap, z_hold - 0.5 + eps], [y_far - eps, z_hold - 0.5 + eps]]);
    // connector shaft, open at the bottom; ribs back the housing ends, wires pass between them
    o = con_origin();
    difference() {
        translate([o[0] - con_fit/2, o[1] - tail - con_fit, -1]) cube([con_w + con_fit, tail + con_fit + con_d, o[2] + con_h + con_fit/2 + 1]);
        for (x = [o[0] - 1, o[0] + con_w - 1.5]) translate([x, o[1] - tail - 1, -2]) cube([2.5, tail + 1, o[2] + con_h + 3]);
    }
    // contact window: slot open at the bottom so the leaves slide up into place
    translate([pin_x(0) - win_margin, -t_contact - eps, -1])
        cube([(con_n-1)*con_pitch + 2*win_margin, t_contact + 1, apex_z + win_y/2 + 1]);
    // board bay
    bay = [pcb_w + 2*(rail_gap + rail + 0.3), pcb_l + rail_gap + rail + 0.3];
    translate([-bay[0]/2, pcb_y1 - bay[1], -1]) cube([bay[0], bay[1] + eps, bay_h + 1]);
    // wire channel: shaft -> bay
    ch_x = o[0] + con_w/2 - 2;
    ch_y = pcb_y0 - rail - rail_gap - 2;
    translate([ch_x, o[1] - tail, -1]) cube([4, ch_y + 4 - o[1] + tail, 4.5]);
    translate([ch_x, ch_y, -1]) cube([-bay[0]/2 + 2 - ch_x, 4, 4.5]);
    // USB-C: receptacle hole, outside recess so the plug seats fully
    usb_z = pcb_t + usb_hgt/2;
    translate([-(usb_w + 0.8)/2, pcb_y1 - 1, usb_z - (usb_hgt + 0.8)/2]) cube([usb_w + 0.8, back_wall + 2, usb_hgt + 0.8]);
    translate([-6.5, pcb_y1 + usb_overhang, usb_z - 3.5]) cube([13, back_wall + 1, 7]);
    // LED window
    translate([-led_win[0]/2, led_y - led_win[1]/2, bay_h - 1]) cube([led_win[0], led_win[1], z_top]);
    // clip arm recess: beam sweep 0.5 below the arm, anchor seat at z_hold
    translate([-tab_w/2 - 1, y_far - eps, z_hold - 0.5]) cube([anchor[0] + tab_w/2 + 1, ledge_y - y_far, z_top]);
    translate([anchor[0] - 0.3, y_far - eps, z_hold]) cube([anchor[1] - anchor[0] + 0.6, beam_y + anchor_l + 0.3 - y_far, z_top]);
    for (s = arm_screws) translate([s[0], s[1], z_hold - 8]) cylinder(d = pilot_d, h = 9);
    // finger scoops in the side walls near the far end
    translate([-foot[0] - 1, y_far - 12, z_top + 3]) rotate([0, 90, 0]) cylinder(r = 9, h = 2*foot[0] + 2, $fn = 80);
    // bottom screw pilots
    for (s = screws) translate([s[0], s[1], -eps]) cylinder(d = pilot_d, h = 7);
    // polarity marks on the contact-end top, over pins 1 and 3
    for (m = [[0, "+"], [2, "-"]]) translate([pin_x(m[0]), (o[1] - tail)/2 - 0.5, z_top - 0.6])
        linear_extrude(1) text(m[1], size = 4, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
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
            // posts under the housing ends
            o = con_origin();
            for (x = [o[0], o[0] + con_w - 1.5]) translate([x, o[1] + 0.1, 0]) cube([1.5, 1.5, o[2] - shim_gap]);
        }
    }
    for (s = screws) translate([s[0], s[1], -eps]) {
        cylinder(d = screw_d, h = plate_t + 1);
        cylinder(d1 = head_d, d2 = screw_d, h = (head_d - screw_d)/2);
    }
}

// modeled in place: prints flat on its underside
module arm() difference() {
    union() {
        translate([-tab_w/2, beam_y, z_hold]) cube([anchor[0] + tab_w/2 + eps, arm_t, arm_h]);
        translate([-tab_w/2, y_far - hook, z_hold]) cube([tab_w, beam_y - y_far + hook + eps, arm_h]);
        translate([anchor[0], beam_y, z_hold]) cube([anchor[1] - anchor[0], anchor_l, arm_h]);
        translate([-3, beam_y, z_top - eps]) cube([6, arm_t, nub_h]);
    }
    // ramp: the dropping battery pushes the tab away
    yz(-tab_w/2 - 1, tab_w + 2, [[y_far - hook - eps, z_hold + 0.6], [y_far + 0.5, z_top + eps], [y_far - hook - eps, z_top + eps]]);
    for (s = arm_screws) translate([s[0], s[1], z_hold - 1]) {
        cylinder(d = screw_d, h = arm_h + 2);
        translate([0, 0, arm_h + 1 - (head_d - screw_d)/2]) cylinder(d1 = screw_d, d2 = head_d, h = (head_d - screw_d)/2 + eps);
    }
}

if (part == "cradle") cradle();
else if (part == "bottom") bottom();
else if (part == "arm") arm();
else {
    cradle();
    color("gray") bottom();
    color("orange") arm();
    %translate(bat_origin()) cube(bat_size());
}
