shader_type canvas_item;

// 核心控制
uniform int cells : hint_range(10, 500) = 50;         // 多边形数量
uniform float border : hint_range(0.0, 0.2) = 0.02;   // 边界粗细
uniform float color_speed : hint_range(0.0, 5.0) = 1.0; // 颜色变化速度

// 高级控制
uniform float pattern_seed = 0.0;    // 图案随机种子
uniform bool animated_cells = true;  // 动态细胞效果
uniform bool color_cycling = true;   // 颜色循环效果

// 改进的Voronoi算法
vec2 random2(vec2 st) {
    st = vec2(dot(st,vec2(127.1,311.7)), dot(st,vec2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
}

vec3 voronoi(vec2 st, float time) {
    st *= float(cells);
    
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);
    
    float m_dist = 1.0;
    vec3 m_color = vec3(0.0);
    
    // 3x3网格搜索
    for(int y=-1; y<=1; y++) {
        for(int x=-1; x<=1; x++) {
            vec2 neighbor = vec2(float(x),float(y));
            vec2 p = i_st + neighbor;
            
            // 生成随机点（带动态偏移）
            vec2 point = random2(p + pattern_seed);
            if(animated_cells) {
                point = 0.5 + 0.5 * sin(time * color_speed + 6.2831*point);
            }
            
            // 计算距离
            vec2 diff = neighbor + point - f_st;
            float dist = length(diff);
            
            // 保持最近距离和对应颜色
            if(dist < m_dist) {
                m_dist = dist;
                m_color = vec3(
                    fract(sin(dot(p,vec2(12.9898,78.233))) * 43758.5453),
                    fract(sin(dot(p.yx,vec2(12.9898,78.233))) * 43758.5453),
                    fract(sin(dot(p.xy,vec2(78.233,12.9898))) * 43758.5453)
                );
            }
        }
    }
    
    // 边界检测
    float edge = smoothstep(0.0, border * 2.0, m_dist);
    return vec3(m_color * edge);
}

void fragment() {
    float time = TIME * float(animated_cells || color_cycling);
    vec2 st = UV;
    
    // 生成Voronoi颜色
    vec3 color = voronoi(st, time);
    
    // 颜色循环效果
    if(color_cycling) {
        color = 0.5 + 0.5 * cos(time + vec3(0.0,2.0,4.0) + color*6.283);
    }
    
    COLOR = vec4(pow(color, vec3(1.0/2.2)), 1.0); // Gamma校正
}