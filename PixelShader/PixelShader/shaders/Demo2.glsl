const int n_elem = 10;	//stack de 10 elementos (por ahora seran 10).
int head = -1;			//Se le hara ++ cada vez que se haga push. -- por cada pop.
vec3[n_elem] stack;
int recursions = 3;

for (int r = 0; r < recursions; r++)
{
	//R_reflex sera el vector direccion del rayo que se usara para revisar si existe reflejo o no.
    vec3 r_reflex = normalize(d - 2.0f * dot(d, normal) * normal);
    vec3 new_obj_normal = vec3(0.0f, 0.0f, 0.0f);
    vec3 q_reflex = obj_point + 0.001f * r_reflex;
	bool intersect = false;
    float closest_t = 0.0f;
    float t = 0.0f;

	//Id -1 en esfera significara que es null----------------------------------
    Sphere closest_obj = Sphere(-1, vec3(0.0f, 0.0f, 0.0f), 1.0f, vec3(0,0,0));
	
    //Para cada objeto, debere ver si el rayo intersecta:
    for(int i = 0; i < obj_count; i++)
    {
		Sphere current_object = objects[i];

        if (current_object.id == obj.id) continue;

        intersect = intersects(scene, q_reflex, r_reflex, current_object, t, new_obj_normal);
        if (closest_t == 0.0f) closest_t = t;

        //Se queda con el t mas cercano.
        if (intersect && t <= closest_t)
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
            obj_reflection_color = material_management(scene, closest_obj, q_reflex, r_reflex, new_obj_point, new_obj_normal, ref_rec - 1);
        else
            obj_reflection_color = material_management(scene, closest_obj, q_reflex, r_reflex, new_obj_point, new_obj_normal, reflex_recursions - 1);

        obj_reflection_color = vec3(obj_reflection_color[0] * reflective.color[0], obj_reflection_color[1] * reflective.color[1], obj_reflection_color[2] * reflective.color[2]);
    }
    else
    {
        //Este seria el caso en que no choca con nada, por lo que refleja la luz de fondo:
        vec3 bgc = scene.backgroundColor;
        obj_reflection_color = vec3(bgc[0] * reflective.color[0], bgc[1] * reflective.color[1], bgc[2] * reflective.color[2]);
    }
}