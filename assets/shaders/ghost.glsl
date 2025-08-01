#version 100
precision mediump float;

uniform float u_time;
uniform sampler2D texture0;

varying vec2 fragTexCoord;

const vec4 ghost_color = vec4(1.0, 0.0, 1.0, 1.0);

float rand(vec2 co) {
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt = dot(co, vec2(a, b));
    highp float sn = mod(dt, 3.14);
    return fract(sin(sn) * c);
}


void main() {
    vec2 uv = fragTexCoord;

    float time_seed = floor(u_time * 10.0);
    float glitch = step(0.98, rand(uv + vec2(time_seed, 0.0)));

    vec4 color = texture2D(texture0, uv);

	color = vec4(color.rgb * 0.07, color.a);
    gl_FragColor = mix(color, ghost_color, glitch);
}
