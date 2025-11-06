
/********************************************************************
 * PARAMETRIC ELECTRONICS BOX WITH LID, POSTS, VENTS & STANDOFFS
 * Cleaned, structured, and commented version (logic unchanged)
 ********************************************************************/

/*-----------------------------
  INTERNAL DIMENSIONS (mm)
-----------------------------*/
inner_length_between_posts_mm = 220;
inner_width_excluding_standoff_mm = 110;
inner_height_excluding_standoff_mm = 50;
standoff_thickness_mm = 2;
standoff_height_mm = 5;

/*-----------------------------
  WALL & STRUCTURAL THICKNESS
-----------------------------*/
wall_thickness_mm = 5;

/*-----------------------------
  VENT SETTINGS
-----------------------------*/
vent_count = 15;
vent_thickness_mm = 2;

/*-----------------------------
  CABLE HOLE SETTINGS
-----------------------------*/
left_cable_hole_shape = 0;   // [0:Circular, 1:Square]
left_cable_hole_position = 1; // [0:None, 1:Middle, 2:Top]
left_cable_hole_diameter_mm = 10;

right_cable_hole_shape = 0;   // [0:Circular, 1:Square]
right_cable_hole_position = 1; // [0:None, 1:Middle, 2:Top]
right_cable_hole_diameter_mm = 10;

left_cable_hole_radius  = left_cable_hole_diameter_mm  / 2;
right_cable_hole_radius = right_cable_hole_diameter_mm / 2;

/*-----------------------------
  CORNER POST SETTINGS
-----------------------------*/
post_diameter_mm = 10;
post_radius = post_diameter_mm / 2;
screw_hole_diameter_mm = 5;
screw_hole_radius = screw_hole_diameter_mm / 2;

/*-----------------------------
  DIMENSION CALCULATIONS
-----------------------------*/
// Inner size includes posts
inner_length = inner_length_between_posts_mm + 2 * post_diameter_mm + 0.1;

// Adjust for stand-offs
inner_width  = inner_width_excluding_standoff_mm + 1;
inner_height = inner_height_excluding_standoff_mm + 0.5;

// Outer dimensions (including walls)
outer_length = inner_length + 2 * wall_thickness_mm;
outer_width  = inner_width  + 2 * wall_thickness_mm;
outer_height = inner_height + wall_thickness_mm;

// Post height equals total box height
post_height = outer_height;

/*-----------------------------
  SWITCH HOLE SETTINGS
-----------------------------*/
switch_shape = 1;  // [0:None, 1:Rectangular, 2:Circular]
switch_hole_width_mm  = 10;
switch_hole_height_mm = 20;

/*-----------------------------
  LOGO SETTINGS
-----------------------------*/
add_logo = 0; // [0:No, 1:Yes]
logo_file = "logo.svg";
logo_x = 100;
logo_y = 50;
logo_z = 1;
pad_x = 5;
pad_y = 5;

/*-----------------------------
  RENDERING OPTIONS
-----------------------------*/
render_lid  = 1;
render_box  = 1;
rounded_box = 1;

/********************************************************************
 * HELPER MODULES
 ********************************************************************/

// Rounded cube using Minkowski sum
module roundedCube(size=[10,10,10], r=1, center=false) {
    minkowski() {
        cube(size, center=center);
        sphere(r=0.5, $fn=32);
    }
}

/********************************************************************
 * POSITION ARRAYS
 ********************************************************************/
lid_corners = rounded_box ?
[
    [post_radius, post_radius],
    [post_radius, inner_width - post_radius],
    [inner_length - post_radius, post_radius],
    [inner_length - post_radius, inner_width - post_radius]
] :
[
    [wall_thickness_mm + post_radius, wall_thickness_mm + post_radius],
    [wall_thickness_mm + post_radius, wall_thickness_mm + inner_width - post_radius],
    [wall_thickness_mm + inner_length - post_radius, wall_thickness_mm + post_radius],
    [wall_thickness_mm + inner_length - post_radius, wall_thickness_mm + inner_width - post_radius]
];

corners = [
    [wall_thickness_mm + post_radius, wall_thickness_mm + post_radius],
    [wall_thickness_mm + post_radius, wall_thickness_mm + inner_width - post_radius],
    [wall_thickness_mm + inner_length - post_radius, wall_thickness_mm + post_radius],
    [wall_thickness_mm + inner_length - post_radius, wall_thickness_mm + inner_width - post_radius]
];

// --- Switch cutout module
module switch_cutout() {
    if (switch_shape == 1) {
        // Rectangular switch hole
        translate([
            -0.5,                               // slightly inside small end wall
            outer_width/2 - switch_hole_width_mm/2,
            outer_height*0.75 - switch_hole_height_mm/2
        ])
            cube([
                wall_thickness_mm + 2,
                switch_hole_width_mm + 2,
                switch_hole_height_mm + 2
            ]);
    }
    else if (switch_shape == 2) {
        // Circular switch hole
        translate([wall_thickness_mm/2, outer_width/2, outer_height*0.75])
            rotate([0, 90, 0])
            scale([1, switch_hole_width_mm / switch_hole_height_mm, 1])
                cylinder(h = wall_thickness_mm + 2, r = switch_hole_height_mm / 2, center = true, $fn = 50);
    }
    // if switch_shape == 0, do nothing
}


/********************************************************************
 * MAIN BOX BODY
 ********************************************************************/
module box_body() {
    union() {
        difference() {
            // Outer shell (rounded or regular)
            if (rounded_box)
                roundedCube([outer_length, outer_width, outer_height + wall_thickness_mm]);
            else
                cube([outer_length, outer_width, outer_height]);

            // Hollow out the interior
            translate([wall_thickness_mm, wall_thickness_mm, wall_thickness_mm])
                cube([inner_length, inner_width, outer_height + wall_thickness_mm]);

            // Cable holes on small end
            cable_holes();

            // Optional switch cutout
            if (switch_shape)
                switch_cutout();
        }

        // Add corner posts with screw holes
        for (pos = corners) {
            difference() {
                translate([pos[0], pos[1], 0])
                    cylinder(h=outer_height, r=post_radius, $fn=50);
                translate([pos[0], pos[1], outer_height / 2])
                    cylinder(h=outer_height / 2 + 1, r=screw_hole_radius, $fn=50);
            }
        }
    }

    // Internal standoffs
    standoffs();
}

/********************************************************************
 * INTERNAL STANDOFFS
 ********************************************************************/
module standoffs() {
    // Mid-width standoff running full length (X-axis)
    translate([wall_thickness_mm,
               wall_thickness_mm + inner_width / 2 - standoff_thickness_mm / 2,
               wall_thickness_mm])
        cube([inner_length, standoff_thickness_mm, standoff_height_mm]);

    // First vertical standoff (1/3 of box length)
    difference() {
        translate([wall_thickness_mm + inner_length / 3 - standoff_thickness_mm / 2, 0, wall_thickness_mm])
            cube([standoff_thickness_mm, outer_width, inner_height]);
        translate([wall_thickness_mm + inner_length / 3 - standoff_thickness_mm / 2 - 0.1,
                   standoff_height_mm + wall_thickness_mm,
                   wall_thickness_mm + standoff_height_mm])
            cube([standoff_thickness_mm + 0.2,
                  inner_width - 2 * standoff_height_mm,
                  inner_height - standoff_height_mm + 0.1]);
    }

    // Second vertical standoff (2/3 of box length)
    difference() {
        translate([wall_thickness_mm + 2 * inner_length / 3 - standoff_thickness_mm / 2, 0, wall_thickness_mm])
            cube([standoff_thickness_mm, outer_width, inner_height]);
        translate([wall_thickness_mm + 2 * inner_length / 3 - standoff_thickness_mm / 2 - 0.1,
                   standoff_height_mm + wall_thickness_mm,
                   wall_thickness_mm + standoff_height_mm])
            cube([standoff_thickness_mm + 0.2,
                  inner_width - 2 * standoff_height_mm,
                  inner_height - standoff_height_mm + 0.1]);
    }
}

// --- Right side hole(s) (used inside cable_holes())
//    Assumes caller rotates by rotate([0,90,0]) as in the refactored cable_holes()
module right_holes() {
    // Middle position
    if (right_cable_hole_position == 1) {
        if (right_cable_hole_shape == 0) {
            // Circular hole centered ~1mm above z=0
            translate([
                -outer_height/2,
                wall_thickness_mm + inner_width/3,
                1
            ])
                cylinder(h = outer_width + 2, r = right_cable_hole_radius, center = true, $fn = 50);
        } else {
            // Square hole
            translate([
                -outer_height/2 - right_cable_hole_radius,
                wall_thickness_mm + inner_width/3 - right_cable_hole_radius,
                -0.5
            ])
                cube([ right_cable_hole_diameter_mm,
                       right_cable_hole_diameter_mm,
                       wall_thickness_mm + 1 ]);
        }
    }
    // Top position
    else if (right_cable_hole_position == 2) {
        if (right_cable_hole_shape == 0) {
            translate([
                -outer_height,
                wall_thickness_mm + inner_width/3,
                1
            ])
                cylinder(h = outer_width + 2, r = right_cable_hole_radius, center = true, $fn = 50);
        } else {
            translate([
                -outer_height - right_cable_hole_radius - 0.5,
                wall_thickness_mm + inner_width/3 - right_cable_hole_radius,
                -0.5
            ])
                cube([ right_cable_hole_diameter_mm + wall_thickness_mm,
                       right_cable_hole_diameter_mm,
                       wall_thickness_mm + 1 ]);
        }
    }
    // position == 0 => no holes (do nothing)
}

// --- Left side hole(s) (used inside cable_holes())
//    Assumes caller rotates by rotate([0,90,0]) as in cable_holes()
module left_holes() {
    // Middle position
    if (left_cable_hole_position == 1) {
        if (left_cable_hole_shape == 0) {
            translate([
                -outer_height/2,
                wall_thickness_mm + 2 * inner_width / 3,
                1
            ])
                cylinder(h = outer_width + 2, r = left_cable_hole_radius, center = true, $fn = 50);
        } else {
            translate([
                -outer_height/2 - left_cable_hole_radius,
                wall_thickness_mm + 2 * inner_width / 3 - left_cable_hole_radius,
                -0.5
            ])
                cube([ left_cable_hole_diameter_mm,
                       left_cable_hole_diameter_mm,
                       wall_thickness_mm + 1 ]);
        }
    }
    // Top position
    else if (left_cable_hole_position == 2) {
        if (left_cable_hole_shape == 0) {
            translate([
                -outer_height,
                wall_thickness_mm + 2 * inner_width / 3,
                1
            ])
                cylinder(h = outer_width + 2, r = left_cable_hole_radius, center = true, $fn = 50);
        } else {
            translate([
                -outer_height - left_cable_hole_radius - 0.5,
                wall_thickness_mm + 2 * inner_width / 3 - left_cable_hole_radius,
                -0.5
            ])
                cube([ left_cable_hole_diameter_mm + wall_thickness_mm,
                       left_cable_hole_diameter_mm,
                       wall_thickness_mm + 1 ]);
        }
    }
    // position == 0 => no holes (do nothing)
}

/********************************************************************
 * CABLE HOLE MODULE
 ********************************************************************/
module cable_holes() {
    union() {
        // Right side holes
        rotate([0, 90, 0]) right_holes();

        // Left side holes
        rotate([0, 90, 0]) left_holes();
    }
}

/********************************************************************
 * LID MODULE (vents, logo, corner posts)
 ********************************************************************/
module lid() {
    lid_thickness = wall_thickness_mm;
    length = rounded_box ? inner_length - 0.2 : outer_length;
    width  = rounded_box ? inner_width - 0.2  : outer_width;

    union() {
        difference() {
            union() {
                // Lid base and vents
                difference() {
                    cube([length, width, lid_thickness]);
                    vents(length, width);
                }

                // Corner posts on lid
                for (pos = lid_corners)
                    translate([pos[0], pos[1], 0])
                        cylinder(h=lid_thickness, r=post_radius, $fn=50);

                // Optional logo (if enabled)
                if (add_logo == 1) {
                    assert(lid_thickness > logo_z, "Logo Z must be less than thickness of the lid");
                    difference() {
                        translate([length/2 - logo_x/2, width/2 - logo_y/2, 0])
                            cube([logo_x, logo_y, lid_thickness]);
                    }
                }
            }

            // Screw holes in lid posts
            for (pos = lid_corners)
                translate([pos[0], pos[1], 0])
                    cylinder(h=lid_thickness + 1, r=screw_hole_radius, $fn=50);

            // Logo pocket (if enabled)
            if (add_logo == 1) {
              translate([length/2 - logo_x/2 + lid_thickness,
                       width/2 - logo_y/2 + lid_thickness,
                       lid_thickness - logo_z])
                cube([logo_x - 2*lid_thickness, logo_y - 2*lid_thickness, logo_z + 0.1]);
            }
        }

        // Extruded logo graphic (if enabled)
        if (add_logo == 1) {
          translate([length/2, width/2, 0])
            color("blue")
                linear_extrude(height=lid_thickness)
                    resize([logo_x - 3*lid_thickness - pad_x, 0, 0], auto=true)
                        import(logo_file, center=true);
        }
    }
}

/********************************************************************
 * VENTS MODULE
 ********************************************************************/
module vents(length, width) {
    union() {
        total_length = length - 2 * wall_thickness_mm;
        gap_thickness_original = (total_length / vent_count) * 0.4;
        wall_thickness_between = 2 * gap_thickness_original;

        vent_width = (total_length - (vent_count - 1) * wall_thickness_between) / vent_count;
        assert(vent_width > 0, "Too many vents!");

        vent_length = width - 2 * wall_thickness_mm;

        // Generate all vent slots
        for (i = [0 : vent_count - 1]) {
            x_pos = wall_thickness_mm + i * (vent_width + wall_thickness_between);
            y_pos = wall_thickness_mm;
            translate([x_pos, y_pos, -1])
                cube([vent_width, vent_length, vent_thickness_mm + 20]);
        }
    }
}

/********************************************************************
 * RENDER COMPLETE ASSEMBLY
 ********************************************************************/
module box_with_lid_side_by_side() {
    if (render_box == 1)
        box_body();

    if (render_lid == 1)
        translate([outer_length + 20, 0, 0])
            lid();
}

// MAIN CALL
box_with_lid_side_by_side();
