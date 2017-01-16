#version 130
//Demo: 8. Randomness 1

/*Attributes: different values for each pixel*/

//Pixel coords: i,j coord of this pixel
in vec2 pixelCoords;

//Color to paint this pixel (r,g,b,a)
out vec4 pixelColor;

/*Uniforms: same value for  all pixels*/

//Pseudo-random temporal value
uniform float rand;

//Size of the canvas
uniform vec2 size;

//Running time of the program (> 0)
uniform float time;

//Current mouse position
uniform vec2 mouse;

//Current key pressed (0 if no key is pressed)
uniform int key;

/*Local Definitions*/
//Struct definition
struct Circle
{
	vec2 position;
	int rad;
	vec4 color;
};

//Function definition
bool intersects(Circle c, vec2 position)
{
	return distance(c.position, position) < c.rad;
}

//Pseudo-random spatial function
float spatial_rand(vec2 seed)
{
    return fract(sin(dot(seed.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void)
{
	Circle c = Circle(mouse, 30, vec4(1*cos(time),1*cos(time),0,1));
	if (intersects(c, pixelCoords))
		pixelColor = c.color; 
	else   
		pixelColor = vec4(spatial_rand(pixelCoords*rand), spatial_rand(pixelCoords*rand), spatial_rand(pixelCoords*rand),1);
}
