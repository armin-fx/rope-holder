include <banded.scad>

/* [Rope holder] */

// ratio = 5/6 * skein_rotation_length
rope_hold_length = 75;

rope_hold_wall = 3.0; // [0:0.1:5]

rope_hold_slot = 10;
rope_hold_flat_width = 20;

edges_radius = 1; // [0:0.1:5]

/* [Rope holder screw] */

rope_hold_bolt_length = 30;

rope_hold_bolt       =  5; // Schaft einer M5 Schraube
rope_hold_bolt_head  = 10; // Kopf einer M5 Schraube

rope_hold_nut_length  = 3;

rope_hold_screw_excess = 2;

rope_hold_screw_wall = 2.0; // [0:0.1:5]

rope_screw_distance = 1.0; // [0:0.1:5]

bold_gap = 0.15; // [0:0.01:0.5]

bold_border = true;
bold_border_deviation  = 1; // [0:0.1:10]

/* [Rope mounting] */

rope_mounting_bold     =  6;
rope_mounting_heigth   =  7;
rope_mounting_width    = 30;
rope_mounting_distance = 40;

/* [Rope] */

skein_count = 3;

skein_diameter = 15;

skein_slot_distance = 3.5;
skein_slot_width = 1;
skein_slot_depth = 1.5;

skein_rotation_length = 90;

/* [Display] */

model = "rope holder"; // ["rope holder", "rope test holder", "rope test holder with slots", "rope"]

part_number = 0; // [0, 1, 2]

show_rope=true;
show_screw=true;

/* [Accuracy] */

$fn_min = 12;
$fd     = 0.05;
fn_percent = 0.5;

/* [Hidden] */

$fa = get_angle_from_percent (fn_percent);

skein_distance = skein_diameter/2 / cos(90 - 180/skein_count);

rope_diameter = (skein_distance + skein_diameter/2) * 2;

rope_hold_width = rope_diameter + 2*rope_hold_wall;

rope_inner_cut_radius = skein_distance+rope_diameter/20;

rope_slot_count = quantize (rope_diameter*PI / skein_slot_distance, 2);

rope_hold_bolt_diameter = rope_hold_bolt_head + 2*bold_gap + 2*rope_hold_screw_wall;


echo ("rope_diameter:", rope_diameter);


if (model=="rope holder")
{
	rope_holder (part_number);
}
if (model=="rope test holder" || model=="rope test holder with slots")
{
	if (show_rope==true)
		%rope_smart (rope_hold_length);
	rope_test_part (part_number, rope_hold_length,
		model=="rope test holder"            ? 0 :
		model=="rope test holder with slots" ? 1 :
		undef);
}
if (model=="rope")
{
	rope_smart (rope_hold_length);
}


//------------------------------------------------------------

module rope_holder (part=0)
{
	// defines
	bind_mounting_holder_length = rope_mounting_distance-rope_mounting_width/2;
	
	rope_transform =
		matrix_translate_z (rope_hold_width/2) *
		matrix_rotate_y (90) *
		matrix_rotate_z (30)
	;
		
	holder_outer_trace_left = [
		[-rope_hold_width/2, rope_hold_width/2 - rope_hold_slot/2],
		//[-rope_hold_width/2, rope_hold_width/2 - rope_hold_flat_width/2],
		each (
			translate_points (v=[-rope_hold_width/2,0], list=
			circle_curve (
				r=rope_hold_width/2 - rope_hold_flat_width/2,
				angle=[90,180],
				slices="x",
				align=Y+X
				)
		) )
	];
	holder_outer_trace = [
		each (holder_outer_trace_left),
		each reverse((mirror_x_points (holder_outer_trace_left)))
	];
	
	bolt_transform =
		matrix_translate_z (rope_hold_width/2 -
		(rope_hold_bolt_length-rope_hold_nut_length + rope_hold_screw_excess)/2)
	;
	nut_transform =
		matrix_translate_z (rope_hold_width/2 +
		(rope_hold_bolt_length-rope_hold_nut_length - rope_hold_screw_excess)/2) *
		matrix_rotate_z (0)
	;
	
	bolt_pos = rope_screw_distance + max(
		rope_diameter/2 + rope_hold_bolt/2 - rope_diameter*0.12,
		rope_hold_bolt_head/2 + sqrt(
			sqr(rope_diameter/2) -
			sqr((rope_hold_bolt_length-rope_hold_nut_length+rope_hold_screw_excess)/2)
			),
		rope_hold_bolt_head/2 + sqrt(
			sqr(rope_diameter/2) -
			sqr((rope_hold_bolt_length-rope_hold_nut_length-rope_hold_screw_excess)/2)
			)
		);
	bolt_places = [
		[skein_rotation_length*1/6, -bolt_pos],
		[skein_rotation_length*3/6, -bolt_pos],
		//
		[skein_rotation_length*2/6, +bolt_pos],
		[skein_rotation_length*4/6, +bolt_pos],
	];
	
	// rope mounting (left in x axis)
	if (part==0 || part==1)
	{
		color ("green")
		difference()
		{
			union()
			{
				translate_x (-rope_mounting_distance)
				cylinder_edges_rounded (h=rope_mounting_heigth, d=rope_mounting_width,
					angle=[180,90], r_edges=edges_radius
				);
				
				translate_x (-rope_mounting_distance)
				cube_rounded ([rope_mounting_width/2, rope_mounting_width, rope_mounting_heigth],
					r=edges_radius, edges_bottom=[1,0,1,0], edges_top=[1,0,1,0], edges_side=0,
					align=+X +Z
				);
				
				// Anbindung von der Befestigungslasche zum Seilhalter
				difference ()
				{
					hull()
					{
						extrude_to_x (epsilon, -bind_mounting_holder_length)
						square_rounded ([rope_mounting_width, rope_mounting_heigth],
							r=edges_radius,
							align=+Y
						);
						
						extrude_to_x (epsilon, 0, align=-1)
						polygon(holder_outer_trace);
					}
					
					translate_z (rope_hold_width/2)
					rotate_y (-90)
					cylinder_extend (h=bind_mounting_holder_length,
						d1=rope_diameter, d2=rope_hold_width-rope_mounting_heigth*2
					);
				}
			}
			
			translate_x (-rope_mounting_distance)
			translate_z (-extra)
			cylinder_extend (
				h=rope_mounting_heigth+2*extra,
				d=rope_mounting_bold+2*bold_gap,
				outer=1
			);
		}
	}
	
	// rope holder (down part)
	if (part==0 || part==1)
	{
		color ("yellowgreen")
		combine () {
			// main
			difference ()
			{
				union ()
				{
					extrude_to_x (rope_hold_length, convexity=3)
					polygon(holder_outer_trace);
					//
					place_copy (bolt_places)
					holder_bolt_add ();
				}
				
				render(convexity=2)
				rotate_y (90)
				rotate_z (90)
				translate_z (rope_hold_length)
				plain_trace_extrude (holder_outer_trace)
				edge_rounded_plane (r=edges_radius, angle=[90,180]);
				
				multmatrix (rope_transform) rope_cut (rope_hold_length);
			}
			
			// add
			empty ();
			
			// cut
			union ()
			{
				holder_rope_to_mounting_cut ();
				
				place_copy (bolt_places)
				multmatrix (bolt_transform) m5_bolt_cut();
			}
		}
	}
	
	// rope holder (upper part)
	if (part==0 || part==2)
	{
		color ("MediumAquamarine")
		combine () {
			// main
			difference ()
			{
				union ()
				{
					mirror_at_z (rope_hold_width/2)
					extrude_to_x (rope_hold_length, convexity=3)
					polygon (holder_outer_trace);
					
					place_copy (bolt_places)
					mirror_at_z (rope_hold_width/2)
					holder_nut_add ();
				}
				
				render(convexity=2)
				mirror_at_z (rope_hold_width/2)
				rotate_y (90)
				rotate_z (90)
				translate_z (rope_hold_length)
				plain_trace_extrude (holder_outer_trace)
				edge_rounded_plane (r=edges_radius, angle=[90,180]);
				
				render(convexity=2)
				mirror_at_z (rope_hold_width/2)
				rotate_y (90)
				rotate_z (90)
//				translate_z (rope_hold_length)
				plain_trace_extrude (holder_outer_trace)
				edge_rounded_plane (r=edges_radius, angle=[90,90]);
				
				multmatrix (rope_transform) rope_cut (rope_hold_length);
			}
			
			// add
			empty ();
			
			// cut
			union ()
			{
				holder_rope_to_mounting_cut ();
				
				place_copy (bolt_places)
				multmatrix (nut_transform) m5_nut_cut();
			}
		}
	}
	
	// show screws
	if (show_rope==true)
		%multmatrix (rope_transform) rope_smart (rope_hold_length+100);
	
	if (show_screw==true)
	{
		%place_copy (bolt_places)
		multmatrix (bolt_transform) m5_bolt (length=rope_hold_bolt_length);
		//
		%place_copy (bolt_places)
		multmatrix (nut_transform) m5_nut ();
		//
		%translate_x (-rope_mounting_distance)
		union ()
		{
			translate_z (-2.5)
			m6_bolt (length=16);
			//
			translate_z (rope_mounting_heigth)
			m6_washer  ();
			//
			translate_z (rope_mounting_heigth + 1.5)
			m6_nut  ();
		}

	}
}

module holder_rope_to_mounting_cut ()
{
	bind_width = 5;
	fn_bezier = get_slices_circle_current_x (bind_width);
	
	translate_z (rope_hold_width/2)
	rotate_y (-90)
	rotate_extrude_extend ($fn=get_slices_circle_current_x (rope_diameter/2))
	rotate_z(-90)
	polygon([
		[0,0],
		each (bezier_curve ([
			[0             , -rope_diameter/2],
			[bind_width*2/3, -rope_diameter/2],
			[bind_width*1/3, -rope_inner_cut_radius],
			[bind_width    , -rope_inner_cut_radius],
			], slices=fn_bezier)
		),
		[bind_width, 0]
	]);
}

// Schraube

module holder_bolt_add (gap=bold_gap)
{
	bold_height      = rope_hold_bolt_length/2 - rope_hold_slot/2
		- rope_hold_nut_length/2 + rope_hold_screw_excess/2;
	bold_hull_height = bold_height + 4;
	hold_part_height = rope_hold_width/2 - rope_hold_slot/2;
	
	if (bold_border==true)
	{
		translate_z (rope_hold_width/2 - rope_hold_slot/2)
		cylinder_edges_rounded (d=rope_hold_bolt_diameter,
			h = is_nearly (bold_hull_height, hold_part_height, bold_border_deviation) ?
				hold_part_height : bold_hull_height,
			r_edges=[edges_radius,0],
			align=-Z,
			outer=0.5
		);
	}
	else
	{
		translate_z (rope_hold_width/2 - rope_hold_slot/2)
		cylinder_edges_rounded (d=rope_hold_bolt_diameter,
			h = bold_height,
			r_edges=[edges_radius,0],
			align=-Z,
			outer=0.5
		);
	}
}
module holder_nut_add ()
{
	nut_height       = rope_hold_bolt_length/2 - rope_hold_slot/2
		- rope_hold_nut_length/2 + rope_hold_screw_excess/2;
	nut_hull_height  = nut_height + 4;
	hold_part_height = rope_hold_width/2 - rope_hold_slot/2;
	
	translate_z (hold_part_height)
	cylinder_edges_rounded (d=rope_hold_bolt_diameter,
		h = is_nearly (nut_hull_height, hold_part_height, bold_border_deviation) ?
			hold_part_height : nut_hull_height,
		r_edges=[edges_radius,0],
		align=-Z,
		outer=0.5
	);
}

module m5_bolt_cut (length=50)
{
	// Kopf unterhalb, Schaubschaft oberhalb
	cylinder_extend (h=length, d=5  + 2*bold_gap, align= Z, outer=1);
	cylinder_extend (h=length, d=10 + 2*bold_gap, align=-Z, outer=1);
}
module m5_nut_cut (length=50, gap=0)
{
	// Mutter oberhalb
	cylinder_extend (h=length, d=8 + 2*gap, align=Z,
	slices=6, outer=1);
	cylinder_extend (h=length, d=5 + 2*bold_gap, align=-Z, outer=1);
}

module m5_bolt (length=10)
{
	// Kopf unterhalb, Schaubschaft oberhalb
	cylinder_extend (h=length, d= 5, align= Z);
	cylinder_extend (h=4     , d=10, align=-Z);
}
module m5_nut ()
{
	// Mutter oberhalb
	difference ()
	{
		cylinder_extend (h=4, d=8, align=Z,
			slices=6, outer=1
		);
		translate_z(-extra)
		cylinder_extend (h=4+2*extra, d=5, align=Z);
	}
}
module m6_bolt (length=10)
{
	// Kopf unterhalb, Schaubschaft oberhalb
	cylinder_extend (h=length, d= 6, align= Z);
	cylinder_extend (h=4     , d=10, align=-Z, outer=1, slices=6);
}
module m6_nut ()
{
	// Mutter oberhalb
	difference ()
	{
		cylinder_extend (h=5, d=10, align=Z,
			slices=6, outer=1
		);
		translate_z(-extra)
		cylinder_extend (h=5+2*extra, d=6, align=Z);
	}
}
module m6_washer ()
{
	// Scheibe oberhalb
	difference ()
	{
		cylinder_extend (h=1.5, d=16, align=Z);
		translate_z(-extra)
		cylinder_extend (h=1.5+2*extra, d=8.5, align=Z);
	}
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// number:
// - undef = all parts
// - 1     = part 1
// - 2     = part 2
module rope_test_part (part=0, length=90, rope_type=0)
{
	difference()
	{
		union()
		{
			if (part==0 || part==1)
			translate_y (rope_hold_slot/2)
			cube_extend ([rope_hold_width, rope_hold_width/2 - rope_hold_slot/2, length], align=Z+Y);
			
			if (part==0 || part==2)
			translate_y (-rope_hold_slot/2)
			cube_extend ([rope_hold_width, rope_hold_width/2 - rope_hold_slot/2, length], align=Z-Y);
		}
		
		translate_z (-extra)
		union()
		{
			cylinder (h=length+2*extra, r=skein_distance+rope_diameter/20);
			if (rope_type==0)
				rope_smart (length+2*extra);
			else if (rope_type==1)
				rope (length+2*extra);
			else
				empty();
		}
	}
}

module rope_slots (length=90)
{
	for (i=[0:1:rope_slot_count-1])
	{
		rotate_z (360/rope_slot_count * i)
		linear_extrude (height=length, convexity=3)
		translate_x (rope_diameter/2 + skein_slot_width/2 - skein_slot_depth)
		union()
		{
			square_extend ([skein_slot_width/2+skein_slot_depth, skein_slot_width], align=X);
			circle_extend (d=skein_slot_width);
		}
	}
}

module rope_cut (length=90)
{
	union()
	{
		rope (length);
		
		cylinder (h=length, r=rope_inner_cut_radius);
	}	
}

module rope (length=90)
{
	difference()
	{
		rope_smart (length);
		
		rope_slots (length);
	}	
}

module rope_smart (length=90)
{
	linear_extrude (height=length, twist=-360*length/skein_rotation_length, convexity=skein_count*2)
	rope_profile();
}

module rope_profile ()
{
	for (c=[0:1:skein_count-1])
	{
		translate ( circle_point(r=skein_distance-epsilon, angle=c*360/skein_count) )
		circle_extend (d=skein_diameter);
	}
}

//------------------------------------------------------------

module extrude_to_x (length, position=0, align=1, convexity)
{
	rotate_y (90)
	rotate_z (90)
	translate_z ((align-1) * length + position)
	linear_extrude (height=length, convexity=convexity)
	children();
}

//------------------------------------------------------------

skrew_data = [
	// screw_type, screw diameter, hex nut spanner width
	["M5", 5,  8],
	["M6", 6, 10]
];

