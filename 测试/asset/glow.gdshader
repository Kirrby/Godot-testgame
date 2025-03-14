shader_type canvas_item;

uniform float glow_power : hint_range(0, 2) = 0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // 光晕计算
    vec2 uv_center = UV - 0.5;
    float glow = smoothstep(0.5, 0.0, length(uv_center)) * glow_power;
    
    // 叠加颜色
    COLOR = tex_color + vec4(0.8, 0.6, 1.0, 1.0) * glow;
}