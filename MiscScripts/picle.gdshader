shader_type canvas_item;

// Define a uniform variable to hold the texture
uniform sampler2D texture : hint_screen_texture;

// Define the vertex shader
void vertex() {
	VERTEX = vec4(VERTEX.xy, 0.0, 1.0);
	
	// Pass the texture coordinates to the fragment shader
	UV = vec2(VERTEX.x + 0.5, VERTEX.y + 0.5);
}