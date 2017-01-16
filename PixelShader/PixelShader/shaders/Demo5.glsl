#version 130
//Demo: 5. Many circles

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

  pixelColor = vec4(0,0,0,1);  
  Circle circles[3];
  circles[0] = Circle(vec2(100,100), 66, vec4(1,1,0,1));
  circles[1] = Circle(vec2(300,300), 55, vec4(0,1,1,1));
  circles[2] = Circle(vec2(400,60), 30, vec4(1,0,0,1));
  
  for(int i=0; i<3; i++)
  {
    circles[i].position= circles[i].position;
    if(testCircle(circles[i], pixelCoords))
      pixelColor = circles[i].color;
  }
}
