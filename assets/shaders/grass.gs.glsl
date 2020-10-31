#version 410 core
layout (points) in;
layout (triangle_strip, max_vertices = 36) out;
// in VS_OUT {} gs_in[];

out GS_OUT {
	vec2 textCoord;
	float colorVariation;
} gs_out;

uniform mat4 u_view;
uniform mat4 u_projection;
uniform mat4 u_model;
uniform vec3 u_cameraPosition;
uniform sampler2D u_wind;
uniform float u_time;

/* CONST PARAMETERS */
const float c_min_size = 0.4f;
const float LOD1 = 5.0f;
const float LOD2 = 10.0f;
const float LOD3 = 20.0f;
const float PI = 3.141592653589793;

/* PARAMETERS */
float grass_size;

/* USEFUL FUNCTIONS */
mat4 rotationX(in float angle);
mat4 rotationY(in float angle);
mat4 rotationZ(in float angle);
float random (vec2 st);
float noise (in vec2 st);
float fbm ( in vec2 _st);

/* MAIN FUNCTIONS */
void createQuad(vec3 base_position, mat4 crossmodel){
	vec4 vertexPosition[4];
	vertexPosition[0] = vec4(-0.25, 0.0, 0.0, 0.0); 	// down left
	vertexPosition[1] = vec4( 0.25, 0.0, 0.0, 0.0);		// down right
	vertexPosition[2] = vec4(-0.25, 0.5, 0.0, 0.0);		// up left
	vertexPosition[3] = vec4( 0.25, 0.5, 0.0, 0.0);		// up right

	vec2 textCoords[4];
	textCoords[0] = vec2(0.0, 0.0);						// down left
	textCoords[1] = vec2(1.0, 0.0);						// down right
	textCoords[2] = vec2(0.0, 1.0);						// up left
	textCoords[3] = vec2(1.0, 1.0);						// up right

	// wind
	vec2 windDirection = vec2(1.0, 1.0); float windStrength = 0.15f;
	vec2 uv = base_position.xz/10.0 + windDirection * windStrength * u_time ;
	uv.x = mod(uv.x,1.0);
	uv.y = mod(uv.y,1.0);
	vec4 wind = texture(u_wind, uv);
	mat4 modelWind =  (rotationX(wind.x*PI*0.75f - PI*0.25f) * rotationZ(wind.y*PI*0.75f - PI*0.25f));
	mat4 modelWindApply = mat4(1);

	// random rotation on Y
	mat4 modelRandY = rotationY(random(base_position.zx)*PI);

	// loop of billboard creation
	for(int i = 0; i < 4; i++) {
		if (i == 2 ) modelWindApply = modelWind;
	    gl_Position = u_projection * u_view *
            (gl_in[0].gl_Position + modelWindApply*modelRandY*crossmodel*(vertexPosition[i]*grass_size));

	    gs_out.textCoord = textCoords[i];
		gs_out.colorVariation = fbm(gl_in[0].gl_Position.xz);
	    EmitVertex();
    }
    EndPrimitive();
}

void createGrass(int numberQuads){
	mat4 model0, model45, modelm45;
	model0 = mat4(1.0f);
	model45 = rotationY(radians(45));
	modelm45 = rotationY(-radians(45));

	switch(numberQuads) {
		case 1: {
			createQuad(gl_in[0].gl_Position.xyz, model0);
			break;
		}
		case 2: {
			createQuad(gl_in[0].gl_Position.xyz, model45);
			createQuad(gl_in[0].gl_Position.xyz, modelm45);
			break;
		}
		case 3: {
			createQuad(gl_in[0].gl_Position.xyz, model0);
			createQuad(gl_in[0].gl_Position.xyz, model45);
			createQuad(gl_in[0].gl_Position.xyz, modelm45);
			break;
		}
	}
}

/* MAIN */
void main()
{
	vec3 distance_with_camera = gl_in[0].gl_Position.xyz - u_cameraPosition;
	float dist_length = length(distance_with_camera); // distance of position to camera
	grass_size = random(gl_in[0].gl_Position.xz) * (1.0f - c_min_size) + c_min_size; 	// for random size

	// distance of position to camera
	float t = 6.0f; if (dist_length > LOD2) t *= 1.5f;
	dist_length += (random(gl_in[0].gl_Position.xz)*t - t/2.0f);

	// change number of quad function of distance
	int lessDetails = 3;
	if (dist_length > LOD1) lessDetails = 2;
	if (dist_length > LOD2) lessDetails = 1;
	if (dist_length > LOD3) lessDetails = 0;

	// create grass
	if (lessDetails != 1
		|| (lessDetails == 1 && (int(gl_in[0].gl_Position.x * 10) % 1) == 0 || (int(gl_in[0].gl_Position.z * 10) % 1) == 0)
		|| (lessDetails == 2 && (int(gl_in[0].gl_Position.x * 5) % 1) == 0 || (int(gl_in[0].gl_Position.z * 5) % 1) == 0)
	)
		createGrass(lessDetails);
} 


// *******************************************************************
//                            UTILS
// *******************************************************************
mat4 rotationX( in float angle ) {
	return mat4(	1.0,		0,			0,			0,
			 		0, 	cos(angle),	-sin(angle),		0,
					0, 	sin(angle),	 cos(angle),		0,
					0, 			0,			  0, 		1);
}

mat4 rotationY( in float angle )
{
	return mat4(	cos(angle),		0,		sin(angle),	0,
			 				0,		1.0,			 0,	0,
					-sin(angle),	0,		cos(angle),	0,
							0, 		0,				0,	1);
}

mat4 rotationZ( in float angle ) {
	return mat4(	cos(angle),		-sin(angle),	0,	0,
			 		sin(angle),		cos(angle),		0,	0,
							0,				0,		1,	0,
							0,				0,		0,	1);
}

float random (vec2 st) {
    return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123);
}

// 2D Noise based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
	vec2 i = floor(st);
	vec2 f = fract(st);

	// Four corners in 2D of a tile
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));

	// Smooth Interpolation

	// Cubic Hermine Curve.  Same as SmoothStep()
	vec2 u = f*f*(3.0-2.0*f);
	// u = smoothstep(0.,1.,f);

	// Mix 4 coorners percentages
	return mix(a, b, u.x) +
	(c - a)* u.y * (1.0 - u.x) +
	(d - b) * u.x * u.y;
}
#define NUM_OCTAVES 5
float fbm ( in vec2 _st) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0);
	// Rotate to reduce axial bias
	mat2 rot = mat2(cos(0.5), sin(0.5),
	-sin(0.5), cos(0.50));
	for (int i = 0; i < NUM_OCTAVES; ++i) {
		v += a * noise(_st);
		_st = rot * _st * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}