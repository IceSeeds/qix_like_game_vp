shader_type canvas_item;
uniform sampler2D mask_texture : hint_default_white;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    float mask = texture(mask_texture, UV).a;

    // マスクが0の場合は完全に透明に
    color.a *= mask;
    COLOR = color;
}