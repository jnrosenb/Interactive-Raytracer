#version 130

//Pixel coords: i,j coord of this pixel
in vec2 pixelCoords;
out vec4 pixelColor;

//UNIFORMS
uniform vec2 size;
uniform float time;
uniform vec2 mouse;
uniform int key; 
uniform float rand; 

//Pseudo-random spatial function
float spatial_rand(vec2 seed){
    return fract(sin(dot(seed.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

//Struct que representara las esferas en la escena.
struct Camera
{
	vec3 position;
	vec3 up;
	vec3 target;
	float fov;
	float near;
	float lensize;
};

//Materiales que se asignaran a los objetos: type 1:lambert, 0:reflective, -1:blinnphong.
struct Material
{
	int type;
	int id;
	vec3 color;
	bool use_for_ambient;
	float glossyfact;
	float shininess;
};

//Struct que representara las esferas en la escena.
struct Sphere
{
	int id;
	vec3 center;
	float radius;
	//Vector simplemente dira indice de materiales del objeto.
	ivec3 material_index;
};

//Las luces:
struct PointLight
{
	vec3 position;
	vec3 color;
};

//CONSTANTES
const int obj_count = 4;
const int light_count = 2;
const int mat_count = 13;
const int ray_count_pow2 = 1;

//Deja seteada la camara. Position, up, target, fov, near, lensize:
Camera camera = Camera(vec3(8.0f, 1.0f, 8.0f), vec3(0.0f, 1.0f, 0.0f), vec3(0.5f, 0.5f, -0.5f), 45.0f, 0.1, 0.04f);

PointLight[light_count] lights = PointLight[light_count](
	PointLight((vec3(10.0f, 20.0f, 20.0f)), vec3(0.1f, 0.1f, 0.1f)),
	PointLight((vec3(10.0f, 10.0f, 10.0f)), vec3(0.4f, 0.4f, 0.4f))
);

//Type(1 lambert, 0 reflective, -1 blinnphong), id, color, use_ambient, glossy, shininess:
const Material[mat_count] materials = Material[mat_count](
	Material(+1, 0,  vec3(1.0f, 0.0f, 0.0f),  true,  0.0f, 0.0f),		// red lambert			0
	Material(+1, 1,  vec3(0.0f, 0.0f, 1.0f),  true,  0.0f, 0.0f),		// blue lambert			1
	Material(+1, 2,  vec3(0.0f, 1.0f, 0.0f),  true,  0.0f, 0.0f),		// green lambert		2
	Material(+1, 3,  vec3(1.0f, 1.0f, 0.0f),  true,  0.0f, 0.0f),		// yellow lambert		3
	Material(+1, 4,  vec3(1.0f, 1.0f, 1.0f),  true,  0.0f, 0.0f),		// white lambert		4
	Material(+1, 5,  vec3(0.2f, 0.2f, 0.2f),  true,  0.0f, 0.0f),		// gray lambert			5
	Material(-1, 6,  vec3(1.0f, 1.0f, 1.0f),  false, 0.0f, 100.0f),		// white_bp_100			6
	Material(-1, 7,  vec3(1.0f, 1.0f, 1.0f),  false, 0.0f, 1000.0f),	// white_bp_1000		7
	Material(-1, 8,  vec3(0.0f, 0.0f, 1.0f),  false, 0.0f, 1000.0f),	// blue_bp_1000			8	 
	Material(+0, 9,  vec3(1.0f, 1.0f, 1.0f),  false, 0.0f, 0.0f),		// white_mirror			9
	Material(+0, 10, vec3(1.0f, 1.0f, 1.0f),  false, 0.1f, 0.0f),		// white_glossy_mirror	10
	Material(+0, 11, vec3(0.5f, 0.5f, 0.5f),  false, 0.0f, 0.0f),		// gray_mirror			11
	Material(+0, 12, vec3(0.75f, 0.6f, 0.0f), false, 0.0f, 0.0f)		// gold_mirror			12
);

//-1 en vector de indices quiere decir que no tiene asignado ese material aun.
Sphere[obj_count] objects = Sphere[obj_count](
	Sphere(0, vec3( sin(time), cos(time), 1.0f),			1.0f, vec3( 2,  6,  9)),
	Sphere(1, vec3( 2*sin(2*time), 4*cos(2*time), 0.0f),	0.5f, vec3( 1,  8, -1)),
	Sphere(2, vec3(3f*cos(5*time), 0, 3*sin(5*time)),		0.3f, vec3( 3, -1, -1)),
	Sphere(5, vec3(-20f, -20.0f, -20.0f),					30.0, vec3( 5, -1,  9))
	//Sphere(4, vec3(-20f,  20.0f,  20.0f),					30.0, vec3( 0, -1,  9))
);

//La escena, consta de camara, luces y objetos, ademas de otros atributos.
struct Scene
{
	Camera camera;
	vec3 backgroundColor;
	vec3 ambientColor;
	bool scene_use_ambient;

	int maxReflectionRecursions;
};


//Para obtener coordenadas mundo a partir de coordenadas 2d:
vec3 get_world_coord(Camera c, vec2 position)
{
	float top = c.near * tan(radians(c.fov / 2.0f));
	float bottom = - top;
	float right = top * (size.x / size.y);
	float left = -right;
    float pix_width  = abs((right - left) / size.x);
    float pix_height = abs((top - bottom) / size.y);

	//Ahora dejamos las coordenadas en espacio camara:
	float iu = (position.x + 0.5f)*((right - left)/(size.x)) - ((right - left)/2.0f);
	float jv = (position.y + 0.5f)*((top - bottom)/(size.y)) - ((top - bottom)/2.0f);
	float kw = -c.near;

	//Defino u, v, y w (vectores direccion unitarios de espacio camara):
	vec3 w = normalize(c.position - c.target);
	vec3 u = normalize(cross(c.up, w));
	vec3 v = normalize(cross(w, u));

	//Posicion en espacio mundo de el pixel (actual) por el que esta pasando el rayo que viene desde la camara:
	vec3 world_coord = c.position + iu*u + jv*v + kw*w;

	return world_coord;
}


//Metodo que revisara si al tirar un rayo desde una posicion, se intersecta a algun objeto. Deja seteado t.
bool intersects(Scene scene, vec3 origen, vec3 d, Sphere obj, inout float t, inout vec3 normal)
{
    Sphere sphere = obj;
    vec3 c = sphere.center;

    //Elementos de la ecuacion cuadratica (A,B,C):
	float A = dot(d, d);
	float B = dot(2*d, origen - c);
	float C = dot(origen - c, origen - c) - pow(sphere.radius, 2.0f);
	float discr = pow(B, 2.0f) - 4.0f * C * A;

    //Caso que se pinta.
    if (discr >= 0.0f && A != 0.0f)
    {
        float temp = sqrt(discr);
        float t1 = (-B - temp) / 2.0f * A;
        float t2 = (-B + temp) / 2.0f * A;

        //Temporalmente sera asi, despues cambiar.
        if (t1 < t2 && t1 >= 0) t = t1;
        else                    t = t2;

        //Posicion en coordenada mundo del punto que estamos pintando.
        vec3 obj_point = origen + t * d;
        normal = normalize(obj_point - c);

        return true;
    }
    return false;
}


//Metodo que se encarga de las luces y sombras.
void light_shade_manager(Scene scene, vec3 obj_point, vec3 vision_dir, vec3 normal, Sphere obj, bool using_lambert, Material blinnPhong, bool using_blinnphong, inout vec3 difuse_color_sum, inout vec3 specular_color_sum) 
{
    //Aqui se encarga de las luces y los brillos difusos y especular:
    for (int i = 0; i < light_count; i++)
    {
		PointLight light = lights[i];
        vec3 light_pos = light.position;
        vec3 light_dir = normalize(light_pos - obj_point);

        //Esta parte se encarga de las sombras:
        bool shadowed = false;
        vec3 q = obj_point + 0.001f * light_dir;

        //Para cada objeto, debere ver si el rayo intersecta y se produce sombra:
        for(int j = 0; j < obj_count; j++)
        {
			Sphere current_object = objects[j];
            float t = 0.0f;
            vec3 normal_current;

            if (current_object.id == obj.id) continue;

            shadowed = intersects(scene, q, light_dir, current_object, t, normal_current);
			if (shadowed && t >= 0.0f && t < length(light_pos - q))
                break;

            //Deja shadowed en false por si termina el loop sin cumplir condicion.
            shadowed = false;
        }

		if (using_lambert && !shadowed)
		{
			float cos_theta = dot(normal, light_dir);
			float f_dif = max(0.0f, cos_theta);
			vec3 difuse_color = vec3(f_dif * light.color.x, f_dif * light.color.y, f_dif * light.color.z);
			difuse_color_sum += difuse_color;
		}
		
		if (using_blinnphong && !shadowed)
		{
			vec3 h = normalize((light_dir + vision_dir) / 2.0f);
			float cos_theta2 = dot(normal, h);
			float f_spec = pow(max(0.0f, cos_theta2), blinnPhong.shininess);
			vec3 specular_color = vec3(f_spec * light.color.x, f_spec * light.color.y, f_spec * light.color.z);
			specular_color_sum += specular_color;
		}        
    }
}

///*
//Se le pasa el punto y objeto y revisa las luces a ver como se deberia mostrar el material que tiene:
vec3 material_management_2(Scene scene, Sphere sphere, vec3 e, vec3 d, vec3 obj_point, vec3 normal)
{
	vec3 vision_dir = normalize(scene.camera.position - obj_point);
	Material lambert = Material(0, -1, vec3(0, 0, 0), false, 0.0f,  0.0f);
	Material blinnPhong = Material(0, -1, vec3(0, 0, 0), false, 0.0f,  0.0f);
	Material reflective = Material(0, -1, vec3(0, 0, 0), false, 0.0f,  0.0f);
	bool using_lambert = false;
	bool using_blinnphong = false;
	bool using_reflective = false;

	for (int i = 0; i < mat_count; i++)
	{
		if (sphere.material_index[i] != -1)
		{
			Material mat = materials[sphere.material_index[i]];
			if (mat.type == 1)
			{
				lambert = mat;
				using_lambert = true;
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
	vec3 obj_ambient_color = vec3(-1.0f, 0.0f, 0.0f);

	if (using_lambert)		obj_difuse_color = lambert.color;
	if (using_blinnphong)	obj_specular_color = blinnPhong.color;

	if (scene.scene_use_ambient)
    {
        vec3 ac = scene.ambientColor;
        if (obj_difuse_color.r != -1.0f && lambert.use_for_ambient)
            obj_ambient_color = vec3( ac.r * obj_difuse_color.r, ac.g * obj_difuse_color.g, ac.b * obj_difuse_color.b);
    }
	
	vec3 difuse_color_sum = vec3(0.0f,0.0f,0.0f);
	vec3 specular_color_sum = vec3(0.0f,0.0f,0.0f);
    light_shade_manager(scene, obj_point, vision_dir, normal, sphere, using_lambert, blinnPhong, using_blinnphong,  difuse_color_sum, specular_color_sum);
	if (using_lambert)
		obj_difuse_color = vec3(obj_difuse_color.x * difuse_color_sum.x, obj_difuse_color.y*difuse_color_sum.y, obj_difuse_color.z*difuse_color_sum.z);
	if (using_blinnphong)
		obj_specular_color = vec3(obj_specular_color.x * specular_color_sum.x, obj_specular_color.y*specular_color_sum.y, obj_specular_color.z*specular_color_sum.z);
	
    //Color final que tendra el punto en cuestion:
    vec3 obj_color = vec3(0.0f, 0.0f, 0.0f);     
    if (using_lambert)
        obj_color += obj_difuse_color;
    if (using_blinnphong)
        obj_color += obj_specular_color;
    if (scene.scene_use_ambient && obj_ambient_color.x != -1)
        obj_color += obj_ambient_color;
   
    return vec3(obj_color);
}


//Metodo de la reflexion. Devuelve color de reflexion.
void reflection(Scene scene, Sphere obj, vec3 obj_point, vec3 d, vec3 normal, float reflex_recursions, Material reflective, inout vec3 obj_reflection_color) 
{
	int recursions = scene.maxReflectionRecursions;	
	vec3 r_reflex = normalize(d - 2.0f * dot(d, normal) * normal);
	vec3 q_reflex = obj_point + 0.001f * r_reflex;
	vec3 refc = reflective.color;
	bool intersect = false;
	float t = 0.0f;
	
	//Id -1 en esfera significara que es null----------------------------------
	Sphere closest_obj = Sphere(-1, vec3(0.0f, 0.0f, 0.0f), 1.0f, vec3(0,0,0));
	vec3 new_obj_normal = vec3(0.0f, 0.0f, 0.0f);
	float closest_t = 0.0f;

	for (int r = 0; r < recursions; r++)
	{
		//Para cada objeto, debere ver si el rayo intersecta:
		for(int i = 0; i < obj_count; i++)
		{
			Sphere current_object = objects[i];

			if (current_object.id == obj.id) continue;

			intersect = intersects(scene, q_reflex, r_reflex, current_object, t, new_obj_normal);
			if (closest_t == 0.0f) closest_t = t;

			//Se queda con el t mas cercano.
			if (intersect && t <= closest_t && t >= 0)
			{
				closest_t = t;
				closest_obj = current_object;
			}
		}

		int ref_rec = scene.maxReflectionRecursions;
		if (closest_obj.id != -1 && (reflex_recursions < 0 || reflex_recursions > 0))
		{
			vec3 new_d = normalize(d + r_reflex);
			vec3 new_obj_point = q_reflex + closest_t * r_reflex;
		
			if (reflex_recursions < 0)
				obj_reflection_color = material_management_2(scene, closest_obj, q_reflex, r_reflex, new_obj_point, new_obj_normal); 
			else
				obj_reflection_color = material_management_2(scene, closest_obj, q_reflex, r_reflex, new_obj_point, new_obj_normal); 

			obj_reflection_color = vec3(obj_reflection_color.r * refc.r, obj_reflection_color.g * refc.g, obj_reflection_color.b * refc.b);
			
			//EXPERIMENTO PARA REEMPLAZAR RECURSION:
			r_reflex = normalize(r_reflex - 2.0f * dot(r_reflex, new_obj_normal) * new_obj_normal);
			q_reflex = new_obj_point + 0.001f * r_reflex;
			intersect = false; 
			t = 0.0f;
			new_obj_normal = vec3(0.0f, 0.0f, 0.0f);
			closest_t = 0.0f;

			//Esto es para que pare cuando el objeto que refleja no tiene reflexion:
			if (closest_obj.material_index[2] == -1) break;
		}
		else
		{
			//Este seria el caso en que no choca con nada, por lo que refleja la luz de fondo:
			vec3 bgc = scene.backgroundColor;
			obj_reflection_color = vec3(bgc[0] * reflective.color[0], bgc[1] * reflective.color[1], bgc[2] * reflective.color[2]);
			break;
		}
	}
}


//Se le pasa el punto y objeto y revisa las luces a ver como se deberia mostrar el material que tiene:
vec4 material_management(Scene scene, Sphere sphere, vec3 e, vec3 d, vec3 obj_point, vec3 normal,  float reflex_recursions)
{
	vec3 vision_dir = normalize(e - obj_point);

	//En material, id -1 equivale a decir que el material es nulo
	Material lambert = Material(0, -1, vec3(0, 0, 0), false, 0.0f,  0.0f);
	Material blinnPhong = Material(0, -1, vec3(0, 0, 0), false, 0.0f,  0.0f);
	Material reflective = Material(0, -1, vec3(0, 0, 0), false, 0.0f,  0.0f);
	bool using_lambert = false;
	bool using_blinnphong = false;
	bool using_reflective = false;

	for (int i = 0; i < 3; i++)
	{
		if (sphere.material_index[i] != -1)
		{
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
        if (obj_difuse_color.r != -1.0f && lambert.use_for_ambient)
            obj_ambient_color = vec3( ac.r * obj_difuse_color.r, ac.g * obj_difuse_color.g, ac.b * obj_difuse_color.b);
    }
	
	vec3 difuse_color_sum = vec3(0.0f,0.0f,0.0f);
	vec3 specular_color_sum = vec3(0.0f,0.0f,0.0f);

    light_shade_manager(scene, obj_point, vision_dir, normal, sphere, using_lambert, blinnPhong, using_blinnphong,  difuse_color_sum, specular_color_sum);
	if (using_lambert)
		obj_difuse_color = vec3(obj_difuse_color.x * difuse_color_sum.x, obj_difuse_color.y*difuse_color_sum.y, obj_difuse_color.z*difuse_color_sum.z);
	if (using_blinnphong)
		obj_specular_color = vec3(obj_specular_color.x * specular_color_sum.x, obj_specular_color.y*specular_color_sum.y, obj_specular_color.z*specular_color_sum.z);
	
	//Aca se maneja el tema de la reflexion:
	if (using_reflective)
		reflection(scene, sphere, obj_point, d, normal, reflex_recursions, reflective, obj_reflective_color);
	
    //Color final que tendra el punto en cuestion:
    vec3 obj_color = vec3(0.0f, 0.0f, 0.0f);
       
    if (using_lambert)
        obj_color += obj_difuse_color;
    if (using_blinnphong)
        obj_color += obj_specular_color;
    if (scene.scene_use_ambient && obj_ambient_color.x != -1)
        obj_color += obj_ambient_color;
    if (using_reflective)
        obj_color += obj_reflective_color;
   
    return vec4(obj_color, 1.0f);
}


//Metodo que pinta las esferas.
void paint_sphere(Sphere obj, Scene scene, vec3 d, vec3 e, inout float distance_ray, inout vec4 pixel_data, int n_ray) //, inout vec3[ray_count_pow2] rayImgData)
{
    Sphere sphere = obj;
    float t = 0.0f;
    vec3 c = sphere.center;
	vec3 normal;

    //Bool que ve si intersecta a esfera:
    bool intersect = intersects(scene, e, d, sphere, t, normal);

    if (!intersect)
    {
		//Aqui debo hacer un if para que no pinte si ya esta pintado.
		if (pixel_data.x == -1 && pixel_data.y == -1 && pixel_data.z == -1)
			pixel_data = vec4(scene.backgroundColor, 1.0f);
    }
    else
    {
		if (distance_ray == 0.0f) 
			distance_ray = t;

        //Posicion en coordenada mundo del punto que estamos pintando.
        vec3 obj_point = e + t * d;

		if (t <= distance_ray)
		{
			distance_ray = t;
			pixel_data = material_management(scene, sphere, scene.camera.position, d, obj_point, normal, -1);
		}
    }
}


//Cada pixel coord ahora se transforma a coordenada mundo. Luego se generan los rayos a partir de e.
vec4 raycast(Scene scene)
{
	//Color final que tendra este pixel:
	vec4 pixel_data = vec4(-1.0f, -1.0f, -1.0f, 1.0f);

	//Origen de camara, y posicion de pixel por donde pasa rayo.
	vec3 e = scene.camera.position;
	//vec3 pix_pos = get_world_coord(scene.camera, pixelCoords.xy);
	
	float top = camera.near * tan(radians(camera.fov / 2.0f));
	float bottom = - top;
	float right = top * (size.x / size.y);
	float left = -right;
    
	float pix_width  = abs((right - left) / size.x);
    float pix_height = abs((top - bottom) / size.y);

	//Ahora dejamos las coordenadas en espacio camara:
	float iu = (pixelCoords.x + 0.5f)*((right - left)/(size.x)) - ((right - left)/2.0f);
	float jv = (pixelCoords.y + 0.5f)*((top - bottom)/(size.y)) - ((top - bottom)/2.0f);
	float kw = -camera.near;

	//Defino u, v, y w (vectores direccion unitarios de espacio camara):
	vec3 w = normalize(camera.position - camera.target);
	vec3 u = normalize(cross(camera.up, w));
	vec3 v = normalize(cross(w, u));

	//Posicion en espacio mundo de el pixel (actual) por el que esta pasando el rayo que viene desde la camara:
	vec3 pix_pos = camera.position + iu*u + jv*v + kw*w;
	
	/*//MULTIPLE-RAYS: Define los puntos por los que pasaran los rayos:
	int ray_count = int(sqrt(ray_count_pow2));
	vec3[ray_count_pow2] ray_array;
	float iu2, jv2 = 0.0f;
	int index = 0;
	for (int i1 = 1; i1 <= ray_count; i1++)
	{
		jv2 = (jv - pix_height / 2.0f) + i1 * (pix_height / (ray_count + 1.0f));
		for (int j1 = 1; j1 <= ray_count; j1++)
		{
			iu2 = (iu - pix_width / 2.0f) + j1 * (pix_width / (ray_count + 1.0f));
			vec3 pixelPos  = e + (iu2 * u) + (jv2 * v) + (kw * w);
			ray_array[index++] = pixelPos;
		}
	}

	//Multiples rayos. Por cada uno, vera con que objetos chocan:
    vec3[ray_count_pow2] rayImgData;
    for (int n_ray = 0; n_ray < ray_count_pow2; n_ray++)
    {
        //Define origen de forma aleatoria, y usando define la d que corresponda segun el arreglo y el origen:
        float arg = scene.camera.lensize; /// 2.0f;

        //Este se compara contra t, y va a decidir que objeto se pinta y cual no para un mismo pixel.
        float distance_ray = 0.0f;

        //Obtengo el nuevo origen y, de acuerdo a esto, el nuevo d:
        vec3 curr_e = e + ((-0.5f + rand*0.5f) * arg) * u + ((-0.5f + rand*0.5f) * arg) * v;
        vec3 curr_d = normalize(ray_array[n_ray] - curr_e);

        //Ahora, para cada objeto, debere ver si el rayo intersecta:
        for (int o = 0; o < obj_count; o++)
			paint_sphere(objects[o], scene, curr_d, curr_e, distance_ray, pixel_data, n_ray, rayImgData);
    }

	//Promedia los rayos y lo guarda en image_data:
    for (int i2 = 0; i2 < ray_count_pow2; i2++)
        pixel_data += rayImgData[i2];
    pixel_data /= ray_count_pow2;
	//*/
	
	//Y obtenida la posicion del pixel, obtengo la direccion d del rayo:
	vec3 d = normalize(pix_pos - e);

	//Se define el t que vera que objeto se pintara y cual no:
	float distance_ray = 0.0f;

	//Ahora con d, veo si intersecta a alguno de los objetos en scene.objects:
	for (int x = 0; x < obj_count; x++)
	{
		Sphere s = objects[x];
		paint_sphere(s, scene, d, e, distance_ray, pixel_data, 0);
	}//*/
	
	return pixel_data;
}


//Metodo principal:
void main(void)
{	
	if (key != 0.0f && key == 51)
	{
		float current = 6*sin(time);
		camera.position += current;
	}
	
	//Aca crea y setea la scene: Camara, bg color, ambient color, use ambient, max recursions:
	Scene scene = Scene(camera, vec3(0.0f,0.0f,0.0f), vec3(0.2f,0.2f,0.2f), true, 3);

	//Obtiene color que pintara en este pixel:
	pixelColor = raycast(scene);
}