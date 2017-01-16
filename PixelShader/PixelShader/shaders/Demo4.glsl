#version 130
//Demo: 4. Circle as object

/*Attributes: different values for each pixel*/

//Pixel coords: i,j coord of this pixel
in vec2 pixelCoords;

//Color to paint this pixel (r,g,b,a)
out vec4 pixelColor;

/*Uniforms: same value for  all pixels*/

//Size of the canvas
uniform vec2 size;

//Running time of the program (> 0)
uniform float time;

/*Local Definitions*/
//Struct definition
struct Circle {
  vec2 position;
  float radius;
  vec4 color;
};
  
//Function definition
bool testCircle(Circle c, vec2 pixelCoords)
{
  return distance(c.position,pixelCoords) < c.radius;
}

void main(void)
{
  Circle c1 = Circle(vec2(256,256), 200, vec4(1,0,0,1)); 
  pixelColor = vec4(0,0,0,1);  
  if(testCircle(c1, pixelCoords))
    pixelColor = c1.color;
}
