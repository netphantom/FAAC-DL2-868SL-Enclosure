// ================== GLOBAL PARAMETERS ==================
battery_diameter = 21;
battery_height   = 7;
wall_thickness   = 3.0;
clearance        = 0.3;
pin_height       = 2.0;
$fn              = 100;

holder_height = wall_thickness + battery_height + pin_height + 2;

pcb_width  = 35;
pcb_depth  = 34;


// ================== TAB CUTOUT MODULE (8x6mm) ==================
module tab_cutout(open_side = 1) {
    offset_x = 2 * open_side;
    cut_length = 8;
    cut_width  = 6;
    cut_height = 6; // Increased for safer cut-through

    union() {
        translate([offset_x,  cut_width/2, 0])
            cube([cut_length, 0.8, cut_height], center = true);

        translate([offset_x, -cut_width/2, 0])
            cube([cut_length, 0.8, cut_height], center = true);

        translate([offset_x - (4.0 * open_side), 0, 0])
            cube([0.8, cut_width + 0.8, cut_height], center = true);
    }
}


// ================== TOP PCB LID ==================
module pcb_top_lid() {
    lid_wall = 2;

    inner_x = pcb_width  - lid_wall;
    inner_y = pcb_depth - lid_wall;

    outer_x = inner_x + (lid_wall * 2);
    outer_y = inner_y + (lid_wall * 2);

    tab_offset_x = (inner_x / 2) - 4;
    tab_offset_y = (inner_y / 2) - 4;

    // Lift the lid to accommodate the new base height
    translate([0, 0, 8.5])
    difference() {
        cube([outer_x, outer_y, 1.2], center = true);

        translate([-tab_offset_x + 4, -tab_offset_y, 0])
            tab_cutout(open_side = 1);

        translate([ tab_offset_x, tab_offset_y, 0])
            tab_cutout(open_side = -1);

        translate([14.5, 0, 0])
            cylinder(d = 3.4, h = 10, center = true);

        translate([-14, 0, 0])
            cylinder(d = 1.5, h = 10, center = true);
    }
}


// ================== M3 STANDOFF MODULE ==================
module m3_standoff(base_height = 5.5) {
    // Positioned on the bottom of the internal cavity
    translate([14.4, 0, -(base_height / 2) + 1])
    difference() {
        cylinder(d = 4.0, h = 4.5);
        translate([0, 0, -1])
            cylinder(d = 3, h = 10);
    }
}


// ================== KEYCHAIN MODULE ==================
module keychain_module(thickness = 3, hole_diameter = 6, base_height = 5.5) {
    anchor_y = -(pcb_depth / 2) - 5;

    // Aligned to the enclosure base
    translate([18, anchor_y, -(base_height / 2)]) {
        difference() {
            hull() {
                cylinder(d = hole_diameter + (thickness * 2), h = thickness);
                translate([-8, 4, 0])
                    cube([10, 1, thickness]);
            }
            translate([0, 0, -1])
                cylinder(d = hole_diameter, h = thickness + 2);
        }
    }
}


// ================== PCB BASE ==================
module pcb_base(base_height = 5.5) {
    inner_x = pcb_width  - 2;
    inner_y = pcb_depth - 2;

    wall = 2;

    outer_x = inner_x + (wall * 2);
    outer_y = inner_y + (wall * 2);

    union() {
        difference() {
            cube([outer_x, outer_y, base_height], center = true);

            // Internal cavity, keeping 1mm bottom thickness
            translate([0, 0, 1])
                cube([inner_x, inner_y, base_height], center = true);
        }
        m3_standoff(base_height = base_height);
    }
}


// ================== BATTERY HOLDER (FEMALE BASE) ==================
module battery_holder_female() {
    total_height = holder_height;
    outer_diameter = battery_diameter + (wall_thickness * 2);

    difference() {
        cylinder(d = outer_diameter, h = total_height);

        translate([0, 0, wall_thickness])
            cylinder(d = battery_diameter, h = total_height);

        for (angle = [0, 180]) {
            rotate([0, 0, angle]) {
                translate([0, 0, wall_thickness + battery_height])
                    linear_extrude(height = pin_height + 2.1)
                        arc_sector(outer_diameter + 1, 50);

                translate([0, 0, wall_thickness + battery_height])
                    linear_extrude(height = pin_height + 0.4)
                        arc_sector(outer_diameter + 1, 90);
            }
        }
    }
}


// ================== BATTERY MALE CAP ==================
module battery_cap_male() {
    outer_diameter = battery_diameter + (wall_thickness * 2);

    cylinder(d = outer_diameter, h = 2);

    translate([0, 0, 2])
    union() {
        cylinder(d = battery_diameter - clearance, h = pin_height);

        for (angle = [0, 180]) {
            rotate([0, 0, angle])
                translate([0, 0, 2])
                    linear_extrude(height = pin_height)
                        arc_sector(outer_diameter - clearance, 45);
        }
    }

    translate([0, 0, 2])
        cylinder(d = 21, h = pin_height + 2);
}


// ================== ARC SECTOR UTILITY ==================
module arc_sector(diameter, angle) {
    intersection() {
        circle(d = diameter);
        polygon([
            [0, 0],
            [diameter, 0],
            [diameter * cos(angle / 2), diameter * sin(angle / 2)],
            [diameter * cos(angle),     diameter * sin(angle)],
            [0, 0]
        ]);
    }
}


// ================== FINAL ASSEMBLY ==================
module pcb_with_battery_cutouts() {
    pcb_height = 5.5;

    hole_x = 10;
    hole_y = 7;

    union() {
        difference() {
            union() {
                pcb_base(base_height = pcb_height);

                translate([5, 0, -(pcb_height / 2)])
                    rotate([180, 0, 0])
                        battery_holder_female();
            }

            translate([hole_x,  hole_y, 0])
                rotate([0, 0,  55])
                    cube([2, 7, 25], center = true);

            translate([hole_x, -hole_y, 0])
                rotate([0, 0, -55])
                    cube([2, 7, 25], center = true);
        }

        keychain_module(base_height = pcb_height);
    }
}


// ================== PRINT LAYOUT ==================
translate([-40, 0, 0])
    rotate([180, 0, 0])
        pcb_with_battery_cutouts();

translate([40, 0, 0])
    rotate([180, 0, 0])
        pcb_top_lid();

translate([0, -40, 0])
    battery_cap_male();
