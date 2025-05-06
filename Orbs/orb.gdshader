shader_type spatial;

uniform sampler2D gradient;

uniform float voronoi_affect : hint_range(0.0, 1.0, 0.1) = 0.0;
uniform float voronoi_scale = 2.0;

varying float rand_val;
varying float rand_val2;


//https://tips.orels.sh/optimized-hash-for-shaders
float hash1(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

//https://www.shadertoy.com/view/7tySzc
float hash3(vec3 p) { // replace this by something better
  p  = fract( p*0.2183099+.1);
  p *= 17.0;
  return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}


vec3 hash3to3(vec3 p) { // replace this by something better
  p  = fract( p*0.2183099+.1);
  p *= 17.0;
  return vec3(fract(p.x * p.y + p.y),fract(p.y + p.z * p.x),fract(p.z * p.x + p.x));
}

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

    float random = hash3(closestCell);
    return -normalize(toClosestCell) * minEdgeDistance;//vec3(minDistToCell, random, minEdgeDistance);
}

void vertex() {
	rand_val = hash1(
		MODEL_MATRIX[3][0] +
		MODEL_MATRIX[3][1] +
		MODEL_MATRIX[3][2]
	);
	
	rand_val2 = hash1(
		MODEL_MATRIX[3][0] * 21.1 +
		MODEL_MATRIX[3][1] * 2018251.2 +
		MODEL_MATRIX[3][2] * 9089210.121213
	);
	
	vec4 modified_model_mat = MODEL_MATRIX[3];
	
	// Offset position
	vec3 voronoi_result = voronoi_affect * (voronoi_scale) * voronoise3D(MODEL_MATRIX[3].xyz * (1.0/voronoi_scale));
	modified_model_mat += vec4(voronoi_result, 0.0);
	
	// Billboard
    mat4 modified_model_view = VIEW_MATRIX * mat4(
        INV_VIEW_MATRIX[0],
        INV_VIEW_MATRIX[1],
        INV_VIEW_MATRIX[2],
        modified_model_mat
    );
    MODELVIEW_MATRIX = modified_model_view;
}

void fragment() {
	vec4 color = texture(gradient, vec2(rand_val, 0.0));
	
	EMISSION = color.xyz * ((rand_val2 + 0.5) * 2.0);
	ALBEDO = color.xyz;
	
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA = float(length(UV - vec2(0.5)) < 0.5);
	
	//EMISSION = MODEL_MATRIX[3].xyz;
}