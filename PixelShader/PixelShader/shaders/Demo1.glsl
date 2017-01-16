	//Deja seteada la camara. Position, up, target, fov, near:
	Camera camera = Camera(vec3(3, 3, 3), vec3(0, 1, 0), vec3(0.5f, 0.5f, -0.5f), 45, 0.1f);
	
	//Aca dejo seteado las luces. Position, color:
	PointLight light1 = PointLight(vec3(0, 10, 20), vec4(0.5f, 0.5f, 0.5f, 1.0f));
	PointLight light2 = PointLight(vec3(10, 20, 20), vec4(0.1f, 0.1f, 0.1f, 1.0f));
	PointLight light3 = PointLight(vec3(0, 20, 0), vec4(0.4f, 0.4f, 0.4f, 1.0f));
	PointLight lights[light_count];
	lights[0] = light1;
	lights[1] = light2;
	lights[2] = light3;

	//Aca seteo los materiales: type (+1 lambert, -1 blinnphong), id, color, use ambient (solo true para lamberts), shininess (0 para lambert).
	Material lambert1 = Material(+1, 0, vec4(1, 0, 0, 1), true,  0.0f);
	Material lambert2 = Material(+1, 1, vec4(0, 0, 1, 1), true,  0.0f);
	Material lambert3 = Material(+1, 2, vec4(0, 1, 0, 1), true,  0.0f);
	Material lambert4 = Material(+1, 3, vec4(1, 1, 0, 1), true,  0.0f);
	Material lambert5 = Material(+1, 4, vec4(1, 1, 1, 1), true,  0.0f);
	Material lambert6 = Material(+1, 5, vec4(0.2, 0.2, 0.2, 1), true,  0.0f);
	Material blinnph1 = Material(-1, 6, vec4(1, 1, 1, 1), false, 100.0f);
	Material blinnph2 = Material(-1, 7, vec4(1, 1, 1, 1), false, 1000.0f);
	Material blinnph3 = Material(-1, 8, vec4(0, 0, 1, 1), false, 1000.0f);
	Material sph1_materials[2];
	Material sph2_materials[2];
	Material sph3_materials[2];
	sph1_materials[0] = lambert2;
	sph1_materials[1] = blinnph1;
	sph2_materials[0] = lambert3;
	sph2_materials[1] = blinnph3;
	sph3_materials[0] = lambert4;
	sph3_materials[1] = lambert4;
	
	//Aca deja seteados los objetos (por ahora habra solo 1). Los que tienen solo difuso le paso 2 veces (por ahora):
	Sphere sph1 = Sphere(vec3(0, 0, 0), 1, sph1_materials);
	Sphere sph2 = Sphere(vec3(1.2f, 1.85f, 0.0f), 0.5f, sph2_materials);
	Sphere sph3 = Sphere(vec3(-1.5f, 0.0f, 0.0f), 0.3f, sph3_materials);
	Sphere objects[obj_count];
	objects[0] = sph1;
	objects[1] = sph2;
	objects[2] = sph3;
