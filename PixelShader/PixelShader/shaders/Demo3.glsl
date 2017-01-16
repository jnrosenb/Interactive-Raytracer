#version 130
//Demo: 3. Simple 2D Circle

//Se le pasa el punto y objeto y revisa las luces a ver como se deberia mostrar el material que tiene:
vec4 material_management(Scene scene, Sphere sphere, vec3 e, vec3 obj_point, vec3 normal)
{
	vec3 vision_dir = normalize(scene.camera.position - obj_point);
	//En material, id -1 equivale a decir que el material es nulo
	Material lambert = Material(0, -1, vec3(0, 0, 0), false, 0.0f,  0.0f);
	bool using_lambert = false;
	Material blinnPhong = Material(0, -1, vec3(0, 0, 0), false, 0.0f,  0.0f);
	bool using_blinnphong = false;
	Material reflective = Material(0, -1, vec3(0, 0, 0), false, 0.0f,  0.0f);
	bool using_reflective = false;

	for (int i = 0; i < mat_count; i++)
	{
		if (sphere.material_index[i] != -1)
		{
			//Por debug ya se que el indice esta correcto (entre 1 y 8)
			//Pero el material mat por alguna razon no saca el material que corresponde del array. SOLO SE ESTA GUARDANDO EL PRIMER ELEMENTO EN EL ARRAY!
			Material mat = materials[sphere.material_index[i]];

			if (mat.type == 1)
			{
				lambert = mat;
				using_lambert = true;
			}
			else if (mat.type == 0)
			{
				reflective = mat;
				using_reflective = true;
			}
			else if (mat.type == -1)
			{
				blinnPhong = mat;
				using_blinnphong = true;
			}
		}
	}
	//Usare -1 en primera componente para distinguir nulls de no nulls:
	vec3 obj_difuse_color = vec3(-1.0f, 0.0f, 0.0f);
	vec3 obj_specular_color = vec3(-1.0f, 0.0f, 0.0f);
	vec3 obj_reflective_color = vec3(-1.0f, 0.0f, 0.0f);
	vec3 obj_ambient_color = vec3(-1.0f, 0.0f, 0.0f);

	if (using_lambert)		obj_difuse_color = lambert.color;
	if (using_blinnphong)	obj_specular_color = blinnPhong.color;

	if (scene.scene_use_ambient)
    {
        vec3 ac = scene.ambientColor;
        if (obj_difuse_color.x != -1.0f && lambert.use_for_ambient)
            obj_ambient_color = vec3( ac.x * obj_difuse_color.x, ac.y * obj_difuse_color.y, ac.z * obj_difuse_color.z);
    }
	
	vec3 difuse_color_sum = vec3(0.0f,0.0f,0.0f);
	vec3 specular_color_sum = vec3(0.0f,0.0f,0.0f);

	//Aqui se encarga de las luces, sombras y los brillos difusos y especular:
    light_shade_manager(scene, obj_point, vision_dir, normal, sphere, using_lambert, blinnPhong, using_blinnphong,  difuse_color_sum, specular_color_sum);
    /*    
	for (int i = 0; i < light_count; i++)
	{
		PointLight light = lights[i];
		vec3 light_dir = normalize(light.position - obj_point);

		if (using_lambert)
		{
			float cos_theta = dot(normal, light_dir);
			float f_dif = max(0.0f, cos_theta);
			vec3 difuse_color = vec3(f_dif * light.color.x, f_dif * light.color.y, f_dif * light.color.z);
			difuse_color_sum += difuse_color;
		}
		
		if (using_blinnphong)
		{
			vec3 h = normalize((light_dir + vision_dir) / 2.0f);
			float cos_theta2 = dot(normal, h);
			float f_spec = pow(max(0.0f, cos_theta2), blinnPhong.shininess);
			vec3 specular_color = vec3(f_spec * light.color.x, f_spec * light.color.y, f_spec * light.color.z);
			specular_color_sum += specular_color;
		}
	}
	//*/
	if (using_lambert)
		obj_difuse_color = vec3(obj_difuse_color.x * difuse_color_sum.x, obj_difuse_color.y*difuse_color_sum.y, obj_difuse_color.z*difuse_color_sum.z);
	if (using_blinnphong)
		obj_specular_color = vec3(obj_specular_color.x * specular_color_sum.x, obj_specular_color.y*specular_color_sum.y, obj_specular_color.z*specular_color_sum.z);
		
    //Color final que tendra el punto en cuestion:
    vec3 obj_color = vec3(0, 0, 0);
       
    if (using_lambert)
        obj_color += obj_difuse_color;
    if (using_blinnphong)
        obj_color += obj_specular_color;
    if (scene.scene_use_ambient && obj_ambient_color.x != -1)
        obj_color += obj_ambient_color;
   
    return vec4(obj_color, 1.0f);
}

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
//Shader variables (local to this pixel)
vec2 center = vec2(256,256);
float radius = 200;
vec4 color = vec4(1,0,0,1);

void main(void)
{
  pixelColor = vec4(0,0,0,1);  
  if(distance(center, pixelCoords) < radius)
    pixelColor = color; 
}
