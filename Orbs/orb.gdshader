shader_type spatial;

uniform sampler2D gradient;

varying float rand_val;

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
}

void fragment() {
	vec4 color = texture(gradient, vec2(rand_val, 0.0));
	
	EMISSION = color.xyz;
}