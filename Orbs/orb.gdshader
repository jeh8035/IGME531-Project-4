shader_type spatial;

uniform sampler2D gradient;


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
//float hash3(vec3 p) { // replace this by something better
  //p  = fract( p*0.2183099+.1);
  //p *= 17.0;
  //return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
//}
//
//vec3 distanceToCenter( vec3 c0, vec3 ic) {
  //vec3 fc = c0 - ic;
  //vec3 center = vec3(hash3(ic.xyz), hash3(ic.yxz * 153.), hash3(ic.zxy));
  //vec3 delta = center - fc;
  //float r = dot( delta, delta );
  //return delta;
//}
//
//vec3 voronoise3D(vec3 c) {
  //float r = 10.;
  //
  //vec3 dir;
  //
  //vec3 ic = floor(c);
  //for( float x=-1.0; x<=1.0; x+=1.0 ) {
      //for( float y=-1.0; y<=1.0; y+=1.0 ) {
        //for( float z=-1.0; z<=1.0; z+=1.0 ) {
          //
            //vec3 ic2 = ic + vec3(x,y,z);
            //vec3 fc = c - ic2;
            //vec3 center = vec3(hash3(ic2.xyz), hash3(ic2.yxz * 153.), hash3(ic2.zxy));
            //vec3 delta = center - fc;
            //float r0 = dot( delta, delta );
          //
          //if (r > r0) dir = delta;
          //
          //r = min( r, r0 );
         //}
      //}
  //}
  //return dir;
  ////return clamp( 1.0 - pow(1. * r, 0.5), 0., 1.0);
//}

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