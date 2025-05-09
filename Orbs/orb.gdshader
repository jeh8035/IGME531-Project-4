shader_type spatial;
render_mode cull_disabled, blend_add;


uniform sampler2D gradient;

uniform float voronoi_affect : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float voronoi_scale = 2.0;

uniform vec3 velocity_dir;

uniform float warp_stretch = 0.0;

varying float rand_val;
varying float rand_val2;

//https://www.shadertoy.com/view/7tySzc
float hash3(vec3 p) { // replace this by something better
  p  = fract( p*0.2183099+.1);
  p *= 17.0;
  return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}


vec3 hash3to3(vec3 p) {
  p  = fract( p*0.2183099+.1);
  p *= 17.0;
  return vec3(fract(p.x * p.y + p.y),fract(p.y + p.z * p.x),fract(p.z * p.x + p.x));
}

// Returns a vector to the edge of a voronoi cell
// https://github.com/ronja-tutorials/ShaderTutorials/blob/master/Assets/028_Voronoi_Noise/voronoi_noise_scrolling.shader
vec3 voronoise3D(vec3 value) {
	vec3 baseCell = floor(value);

    //first pass to find the closest cell
    float minDistToCell = 10.0;
    vec3 toClosestCell;
    vec3 closestCell;
    for(int x1=-1; x1<=1; x1++){
        for(int y1=-1; y1<=1; y1++){
            for(int z1=-1; z1<=1; z1++){
                vec3 cell = baseCell + vec3(float(x1), float(y1), float(z1));
                vec3 cellPosition = cell + hash3to3(cell);
                vec3 toCell = cellPosition - value;
                float distToCell = length(toCell);
                if(distToCell < minDistToCell){
                    minDistToCell = distToCell;
                    closestCell = cell;
                    toClosestCell = toCell;
                }
            }
        }
    }

    //second pass to find the distance to the closest edge
    float minEdgeDistance = 10.0;
    for(int x2=-1; x2<=1; x2++){
        for(int y2=-1; y2<=1; y2++){
            for(int z2=-1; z2<=1; z2++){
                vec3 cell = baseCell + vec3(float(x2), float(y2), float(z2));
                vec3 cellPosition = cell + hash3to3(cell);
                vec3 toCell = cellPosition - value;

                vec3 diffToClosestCell = abs(closestCell - cell);
                bool isClosestCell = diffToClosestCell.x + diffToClosestCell.y + diffToClosestCell.z < 0.1;
                if(!isClosestCell){
                    vec3 toCenter = (toClosestCell + toCell) * 0.5;
                    vec3 cellDifference = normalize(toCell - toClosestCell);
                    float edgeDistance = dot(toCenter, cellDifference);
                    minEdgeDistance = min(minEdgeDistance, edgeDistance);
                }
            }
        }
    }

    return -normalize(toClosestCell) * minEdgeDistance;//vec3(minDistToCell, random, minEdgeDistance);
}

mat4 calcLookAtMatrix(vec3 origin, vec3 target_start, vec3 target_vector) {
	// Right (Non-orthogonal)
	vec3 rr = normalize(target_start - origin);

	// Forward
	vec3 ww = normalize((target_start + target_vector) - origin);

	// Forward x Right = Up
	vec3 uu = normalize(cross(ww, rr));

	// Up x Forward = Right
	vec3 vv = normalize(cross(uu, ww));

	return mat4(vec4(uu, 0.0), vec4(vv, 0.0), vec4(ww,0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

void vertex() {
	rand_val = hash3(vec3(
		MODEL_MATRIX[3][0],
		MODEL_MATRIX[3][1],
		MODEL_MATRIX[3][2]
	));

	rand_val2 = hash3(vec3(
		MODEL_MATRIX[3][0] * 29535671.172,
		MODEL_MATRIX[3][1] * 2018251.27212,
		MODEL_MATRIX[3][2] * 9089210.121213
	));

	vec4 new_translation = MODEL_MATRIX[3];

	// Offset position
	vec3 voronoi_result = voronoi_affect * (voronoi_scale) * voronoise3D(MODEL_MATRIX[3].xyz * (1.0/voronoi_scale));
	new_translation += vec4(voronoi_result, 0.0);

    mat4 modified_translation = mat4(
        vec4(1.0, 0.0, 0.0, 0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(0.0, 0.0, 1.0, 0.0),
        new_translation
    );

	// "Hyperspace" effect

	bool is_significant_speed = length(velocity_dir) > 1.0;

	// Face player for billboard effect, plus velocity for hyperspace effect
	mat4 modified_rot = calcLookAtMatrix(new_translation.xyz, CAMERA_POSITION_WORLD + vec3(0.0, 0.0, 5.0), vec3(0.0, 0.0, -5.0));
	// If going above a certain speed, face point going towards the direction of velocity for hyperspace effect
	if (is_significant_speed)
		modified_rot = calcLookAtMatrix(new_translation.xyz, CAMERA_POSITION_WORLD, normalize(velocity_dir.xyz) * warp_stretch * 10000.0);

	// Distance to line of velocity
	// Only calculate if going above a certain speed to avoid jittering
	float dist_from_vel = 0.0;
	if (is_significant_speed)
		dist_from_vel = length(cross(new_translation.xyz - CAMERA_POSITION_WORLD, new_translation.xyz - (CAMERA_POSITION_WORLD + normalize(velocity_dir.xyz) )));

	mat4 modified_scale = mat4(
		vec4(5.0, 0.0, 0.0, 0.0),
		vec4(0.0, 5.0 + warp_stretch * dist_from_vel, 0.0, 0.0),
		vec4(0.0, 0.0, 5.0, 0.0),
		vec4(0.0, 0.0, 0.0, 1.0)
	);

	MODELVIEW_MATRIX = VIEW_MATRIX * modified_translation * modified_rot * modified_scale;
}

void fragment() {
	vec4 color = texture(gradient, vec2(rand_val, 0.0));

	EMISSION = color.xyz * ((rand_val2 + 0.5) * 2.0);
	ALBEDO = color.xyz;

	//ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA = min(1.0, pow(1.0 - length(UV - vec2(0.5)), 5.0));

	//EMISSION = MODEL_MATRIX[3].xyz;
}