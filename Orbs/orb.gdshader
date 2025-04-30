shader_type spatial;

uniform sampler2D gradient;

varying float rand_val;
varying float rand_val2;

// Star colors derived from http://www.vendian.org/mncharity/dir3/starcolor/

//https://tips.orels.sh/optimized-hash-for-shaders
float hash1(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
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
}

void fragment() {
	vec4 color = texture(gradient, vec2(rand_val, 0.0));
	
	EMISSION = color.xyz * ((rand_val2 + 0.5) * 2.0);
	ALBEDO = color.xyz;
}