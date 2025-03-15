shader_type canvas_item;

uniform float glow_width = 0.2;
uniform vec4 glow_color : source_color = vec4(1.0);

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float distance = length(uv);
    float alpha = smoothstep(0.8, 0.0, distance) * glow_color.a;

    COLOR = vec4(glow_color.rgb, alpha);
}