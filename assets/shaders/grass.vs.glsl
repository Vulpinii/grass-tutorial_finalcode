#version 410 core
layout (location = 0) in vec3 aPos;
// out VS_OUT {} vs_out;

void main() {
	gl_Position = vec4(aPos, 1.0); 
}