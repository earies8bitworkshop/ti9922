/* [Internal dimensions of the box] */
inner_length = 22;      // cm, interior length (long side)
inner_width = 11;       // cm, interior width (short side)
inner_height = 5;       // cm, interior height

/* [Wall thickness of the box and lid] */
wall_thickness = 0.5;   // cm (5 mm)

/* [Vents on the lid] */
vent_count = 15;        // Number of vents
vent_thickness = 0.2;      // cm, thickness of vents height

/* [Cable holes on the small end of the box] */
cable_hole_diameter = 1;      // cm, diameter of holes on box end
cable_hole_radius = cable_hole_diameter / 2;  // radius for convenience

/* [Corner posts inside the box and on the lid] */
post_diameter = 1;         // cm, diameter of vertical posts
post_radius = post_diameter / 2;
screw_hole_diameter = 0.5;  // cm, diameter of holes inside posts
screw_hole_radius = screw_hole_diameter / 2;

/* [Calculate the outer dimensions to include walls] */
outer_length = inner_length + 2 * wall_thickness;
outer_width = inner_width + 2 * wall_thickness;
outer_height = inner_height + wall_thickness;  // base wall thickness added to height

/* Post height equals outer box height */
post_height = outer_height;

/* [Switch hole on the small end wall] */

switch_hole_width = 1;       // cm, hole width along width (y-axis)
switch_hole_height = 2;      // cm, hole height along height (z-axis)

/* [Rendering Option] */
render_lid = 1; // [0:No, 1:Yes]
render_box = 1; // [0:No, 1:Yes]

corners = [
            [wall_thickness + post_radius, wall_thickness + post_radius],                          // Front-left
            [wall_thickness + post_radius, wall_thickness + inner_width - post_radius],            // Back-left
            [wall_thickness + inner_length - post_radius, wall_thickness + post_radius],           // Front-right
            [wall_thickness + inner_length - post_radius, wall_thickness + inner_width - post_radius] // Back-right
        ];

module box_body() {
    union() {
        difference() {
            // Construct the outer shell of the box
            cube([outer_length, outer_width, outer_height]);

            // Hollow out the inside of the box with some extra margin on height (+1 cm)
            translate([wall_thickness, wall_thickness, wall_thickness])
                cube([inner_length, inner_width, inner_height + 1]);

            // Subtract two circular holes on the small end wall, rotated to face correctly
            union() {
                rotate([0, 90, 0]){
                    translate([
                        -3,                                    // Slightly offset outside small end
                        wall_thickness + inner_width / 3,     // 1/3 along width
                        wall_thickness + inner_height / 2     // Halfway up height
                    ])
                    cylinder(h=outer_width + 2, r=cable_hole_radius, center=true, $fn=50);
                }
                rotate([0, 90, 0]){
                    translate([
                        -3,
                        wall_thickness + 2 * inner_width / 3, // 2/3 along width
                        wall_thickness + inner_height / 2
                    ])
                    cylinder(h=outer_width + 2, r=cable_hole_radius, center=true, $fn=50);
                }
            }

            // Subtract rectangular hole on small end wall
            rotate([0, 90, 0]){ 
                translate([
                    -outer_height + 0.5,                  // Positioned at small end face, slightly inside
                    inner_width / 2 - switch_hole_width / 2,  // Centered halfway across width
                    wall_thickness - 1                    // Positioned at about 3/4 height (approximate)
                ])
                cube([
                    switch_hole_width,                      // 1 cm wide along width
                    switch_hole_height,                     // 2 cm tall along height
                    wall_thickness + 1                    // Depth enough to cut through wall thickness
                ]);
            }
        }

        // Add vertical cylindrical posts on all four interior corners with internal holes
        cylinder_diameter = post_diameter;
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
}

module vents() {
    union() {
        total_length = outer_length - 2 * wall_thickness;

        gap_thickness_original = (total_length / vent_count) * 0.4; // Original vent gap thickness (40% of half spacing)
        wall_thickness_between = 2 * gap_thickness_original;       // Wall thickness between vents doubled for strength

        // Calculate the width of each vent to fit all vents and walls into total vent length
        vent_width = (total_length - (vent_count - 1) * wall_thickness_between) / vent_count;

        vent_length = outer_width - 2 * wall_thickness;

        // Create each vent slot as a rectangular cutout
        for (i = [0 : vent_count - 1]) {
            x_pos = wall_thickness + i * (vent_width + wall_thickness_between);
            y_pos = wall_thickness;
            translate([x_pos, y_pos, -1])  // Slightly below to ensure clean cut
                cube([vent_width, vent_length, vent_thickness + 2]);  // Size extending through lid thickness
        }
    }
}

module lid() {
    lid_thickness = wall_thickness;

    // Define corner positions for lid posts to match box posts

    difference() {
        union() {
            difference(){
                // Lid base plate
                cube([outer_length, outer_width, lid_thickness]);
                vents();  // Subtract vent slots from lid
            }

            // Corner cylinders on lid to match box posts
            for (pos = corners) {
                translate([pos[0], pos[1], 0])
                    cylinder(h=lid_thickness, r=post_radius, center=false, $fn=50);
            }
        }


        // Holes inside lid corner posts, smaller than posts, fully through lid thickness plus margin
        screw_hole_height = lid_thickness + 1;
        for (pos = corners) {
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
    translate([outer_length + 0.5, 0, 0])
        lid();
  }
}

// Call the main render function to display box and lid side by side
box_with_lid_side_by_side();
