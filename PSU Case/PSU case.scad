/* [Internal dimensions of the box] */
inner_length_between_posts_mm = 220;      // mm, interior length (long side)
inner_width_excluding_standoff_mm = 110;       // mm, interior width (short side)
inner_height_excluding_standoff_mm = 50;       // mm, interior height
standoff_thickness_mm = 2;
standoff_height_mm = 5;

/* [Wall thickness of the box and lid] */
wall_thickness_mm = 5;   // cm (5 mm)

/* [Vents on the lid] */
vent_count = 15;        // Number of vents
vent_thickness_mm = 2;      // mm, thickness of vents height


/* [Cable holes on the small end of the box] */
left_cable_hole_diameter_mm = 10;      // mm, diameter of holes on box end
right_cable_hole_diameter_mm = 10;      // mm, diameter of holes on box end
left_cable_hole_radius = left_cable_hole_diameter_mm / 2;  // radius for convenience
right_cable_hole_radius = right_cable_hole_diameter_mm / 2;  // radius for convenience

/* [Corner posts inside the box and on the lid] */
post_diameter_mm = 10;         // mm, diameter of vertical posts
post_radius = post_diameter_mm / 2;
screw_hole_diameter_mm = 5;  // mm, diameter of holes inside posts
screw_hole_radius = screw_hole_diameter_mm / 2;

/* PSU sits between posts on the long edge */
inner_length = inner_length_between_posts_mm + 2 * post_diameter_mm+0.1;

/* Widen inner_width  and inner_height to accomodate 5mm stand offs */
inner_width = inner_width_excluding_standoff_mm + 1;
inner_height = inner_height_excluding_standoff_mm + 0.5;

/* [Calculate the outer dimensions to include walls] */
outer_length = inner_length + 2 * wall_thickness_mm;
outer_width = inner_width + 2 * wall_thickness_mm;
outer_height = inner_height + wall_thickness_mm;  // base wall thickness added to height

/* Post height equals outer box height */
post_height = outer_height;

/* [Switch hole on the small end wall] */
switch_shape = 1; // [0:None, 1:Rectangular, 2:Circular]
switch_hole_width_mm = 10;       // mm, hole width along width (y-axis)
switch_hole_height_mm = 20;      // mm, hole height along height (z-axis)

/* [Rendering Option] */
render_lid = 1; // [0:No, 1:Yes]
render_box = 1; // [0:No, 1:Yes]
rounded_box = 1; // [0:No, 1:Yes]

module roundedCube(size=[10,10,10], r=1, center=false) {
    minkowski() {
        cube(size , center=center);
        sphere(r=0.5, $fn=32);
    }
}

lid_corners = rounded_box ? [
            [post_radius, post_radius],                          // Front-left
            [post_radius, inner_width - post_radius],            // Back-left
            [inner_length - post_radius, post_radius],           // Front-right
            [inner_length - post_radius, inner_width - post_radius] // Back-right
        ] : [
            [wall_thickness_mm + post_radius, wall_thickness_mm + post_radius],                          // Front-left
            [wall_thickness_mm + post_radius, wall_thickness_mm + inner_width - post_radius],            // Back-left
            [wall_thickness_mm + inner_length - post_radius, wall_thickness_mm + post_radius],           // Front-right
            [wall_thickness_mm + inner_length - post_radius, wall_thickness_mm + inner_width - post_radius] // Back-right
        ];
corners =  [
            [wall_thickness_mm + post_radius, wall_thickness_mm + post_radius],                          // Front-left
            [wall_thickness_mm + post_radius, wall_thickness_mm + inner_width - post_radius],            // Back-left
            [wall_thickness_mm + inner_length - post_radius, wall_thickness_mm + post_radius],           // Front-right
            [wall_thickness_mm + inner_length - post_radius, wall_thickness_mm + inner_width - post_radius] // Back-right
        ];

module box_body() {
    union() {
        difference() {
            // Construct the outer shell of the box
            if(rounded_box) {
            roundedCube([outer_length, outer_width, outer_height+5]);
            } else {
            cube([outer_length, outer_width, outer_height]);
            }

            // Hollow out the inside of the box with some extra margin on height (+1 cm)
            translate([wall_thickness_mm, wall_thickness_mm, wall_thickness_mm])
                cube([inner_length, inner_width, outer_height+wall_thickness_mm ]);

            // Subtract two circular holes on the small end wall, rotated to face correctly
            union() {
                rotate([0, 90, 0]){
                    translate([
                        -outer_height/2,                                    // Slightly offset outside small end
                        wall_thickness_mm + inner_width / 3,     // 1/3 along width
                        outer_height / 2     // Halfway up height
                    ])
                    cylinder(h=outer_width + 2, r=right_cable_hole_radius, center=true, $fn=50);
                }
                rotate([0, 90, 0]){
                    translate([
                        -outer_height/2,
                        wall_thickness_mm + 2 * inner_width / 3, // 2/3 along width
                        wall_thickness_mm + inner_height / 2
                    ])
                    cylinder(h=outer_width + 2, r=left_cable_hole_radius, center=true, $fn=50);
                }
            }

                if(switch_shape) {
                 if(switch_shape==2) {
                     translate([wall_thickness_mm/2,outer_width/2,outer_height*0.75])
                     rotate([0,90,0])
                    scale([1,switch_hole_width_mm/switch_hole_height_mm,1])
                        cylinder(h=wall_thickness_mm+2, r=switch_hole_height_mm/2, center=true);
                } else {
                   translate([
                    -0.5,                  // Positioned at small end face, slightly inside
                    outer_width / 2 - switch_hole_width_mm / 2,  // Centered halfway across width
                    outer_height*0.75-switch_hole_height_mm/2                    // Positioned at about 3/4 height (approximate)
                   ])

                  cube([
                    wall_thickness_mm+2,                      // 1 cm wide along width
                    switch_hole_width_mm+2,                     // 2 cm tall along height
                    switch_hole_height_mm+2                    // Depth enough to cut through wall thickness
                  ]);
                }
                }
        }

        // Add vertical cylindrical posts on all four interior corners with internal holes
        cylinder_diameter = post_diameter_mm;
        cylinder_radius = cylinder_diameter / 2;
        height = outer_height;  // Height for all posts

        // Positions for the four posts at each interior corner


        // Create each post as a solid cylinder with a smaller cylindrical hole inside starting halfway down
        for (pos = corners) {
            difference() {
                // Solid vertical post
                translate([pos[0], pos[1], 0])
                    cylinder(h=height, r=cylinder_radius, center=false, $fn=50);
                // Hole inside post, starting at half height through to the bottom with extra margin
                translate([pos[0], pos[1], height / 2])
                    cylinder(h=height / 2 + 1, r=screw_hole_radius, center=false, $fn=50);
            }
        }
    }
    // Add internal standoffs/ridges
   standoffs();
}




module standoffs() {
    // Mid-width standoff running full length (X-axis), touching both long walls
    translate([wall_thickness_mm, 
               wall_thickness_mm + inner_width/2 - standoff_thickness_mm/2, 
               wall_thickness_mm])
        cube([inner_length, standoff_thickness_mm, standoff_height_mm]);

    // 1/3rd length standoff running full width (Y-axis), extended into both side walls
        difference() {
            translate([wall_thickness_mm + inner_length/3 -   standoff_thickness_mm/2, 
                0,  // start at outer Y=0 wall
                wall_thickness_mm]) 
                    cube([standoff_thickness_mm, outer_width, inner_height]);
            translate([wall_thickness_mm + inner_length/3 - standoff_thickness_mm/2-0.1, 
                standoff_height_mm+wall_thickness_mm, 
                wall_thickness_mm + standoff_height_mm])
                    cube([standoff_thickness_mm+0.2, inner_width - 2 * standoff_height_mm, inner_height - standoff_height_mm+0.1]);
            }



    // 2/3rd length standoff running full width (Y-axis), extended into both side walls
        difference() {
            translate([wall_thickness_mm + 2*inner_length/3 - standoff_thickness_mm/2, 
                    0, 
                    wall_thickness_mm])
                cube([standoff_thickness_mm, outer_width, inner_height]);
            translate([wall_thickness_mm + 2*inner_length/3 - standoff_thickness_mm/2-0.1, 
                standoff_height_mm+wall_thickness_mm, 
                wall_thickness_mm + standoff_height_mm])
                    cube([standoff_thickness_mm+0.2, inner_width - 2 * standoff_height_mm, inner_height - standoff_height_mm+0.1]);
            }

}

module vents(length, width) {
    union() {
        total_length = length - 2 * wall_thickness_mm;

        gap_thickness_original = (total_length / vent_count) * 0.4; // Original vent gap thickness (40% of half spacing)
        wall_thickness_between = 2 * gap_thickness_original;       // Wall thickness between vents doubled for strength

        // Calculate the width of each vent to fit all vents and walls into total vent length
        vent_width = (total_length - (vent_count - 1) * wall_thickness_between) / vent_count;
    assert(vent_width > 0, "Too many vents!");

        vent_length = width - 2 * wall_thickness_mm;

        // Create each vent slot as a rectangular cutout
        for (i = [0 : vent_count - 1]) {
            x_pos = wall_thickness_mm + i * (vent_width + wall_thickness_between);
            y_pos = wall_thickness_mm;
            translate([x_pos, y_pos, -1])  // Slightly below to ensure clean cut
                cube([vent_width, vent_length, vent_thickness_mm + 20]);  // Size extending through lid thickness
        }
    }
}



module lid() {
    lid_thickness = wall_thickness_mm;
    length = rounded_box ? inner_length - 0.2 : outer_length;
    width  = rounded_box ? inner_width - 0.2  : outer_width;


    // Define corner positions for lid posts to match box posts

    difference() {
        union() {
            difference(){
                // Lid base plate

                cube([length, width, lid_thickness]);

                vents(length, width);  // Subtract vent slots from lid
            }

            // Corner cylinders on lid to match box posts
            for (pos = lid_corners) {
                translate([pos[0], pos[1], 0])
                    cylinder(h=lid_thickness, r=post_radius, center=false, $fn=50);
            }
        }


        // Holes inside lid corner posts, smaller than posts, fully through lid thickness plus margin
        screw_hole_height = lid_thickness + 1;
        for (pos = lid_corners) {
            translate([pos[0], pos[1], 0])
                cylinder(h=screw_hole_height, r=screw_hole_radius, center=false, $fn=50);
        }
    }
}

module box_with_lid_side_by_side() {

  if(render_box==1){
    // Render box at origin
    box_body();
  }

  if(render_lid==1){
    // Render lid offset to the right with a gap for visibility
    translate([outer_length + 20, 0, 0])
        lid();
  }
}

// Call the main render function to display box and lid side by side
box_with_lid_side_by_side();
