#version 100
precision mediump float;

uniform float u_time;
uniform float u_radius;
uniform sampler2D texture0;

varying vec2 fragTexCoord;


void main() {
    vec2 uv = fragTexCoord;
	float time = mod(u_time, 6.28318530718);

	vec2 vignette_position = uv;
	vignette_position.y += sin(time + uv.x * 16.0) / 16.0;
	vignette_position.y -= 0.5;
	vignette_position.x -= 0.5;
	float sdf = length(vignette_position) - u_radius;

	vec4 color = texture2D(texture0, uv);
	sdf = smoothstep(0.0, 0.25, sdf);
	color.rgb *= 1.0 - sdf;

	vignette_position = uv;
	vignette_position.y += sin(time + uv.x * 16.0 + 8.0) / 16.0;
	vignette_position.y -= 0.5;
	vignette_position.x -= 0.5;
	sdf = length(vignette_position) - u_radius + 0.05;
	sdf = smoothstep(0.0, 0.25, sdf);

	color.rgb *= 1.0 - sdf;
	gl_FragColor = color;
}
