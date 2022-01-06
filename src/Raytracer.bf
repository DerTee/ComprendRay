using System;

namespace ComprendRay.Raytracer
{
	public static
	{
		[Inline]
		public static double degrees_to_radians(double degrees)
		{
			return degrees * Math.PI_d / 180;
		}

		public static void render_scene(ref HittableList world, ref Camera cam, ref RenderBuffer buffer, int sample)
		{
			let render_params = buffer.renderparameters;
			var rand = scope Random();
			int32 current_sample = (int32)sample;
			for (int32 y < render_params.image_height)
			{
				for (int32 x < render_params.image_width)
				{
					let u = (x + rand.NextDouble()) / (render_params.image_width - 1);
					let v = (y + rand.NextDouble()) / (render_params.image_height - 1);
					var r = cam.get_ray(u, v);
					buffer.pixelbuffers[current_sample].pixels[x, y] = ray_color(ref r, world, render_params.max_depth);
				}
			}

			let fileName = scope $"image_sample_{current_sample}.ppm";

			let imageData = buffer.pixelbuffers[buffer.current_sample].to_ppm(buffer.renderparameters);
			System.IO.File.WriteAllText(fileName, imageData);
			delete imageData;

			/*
			let fileName = scope $"image_sample_composed.ppm";

			let imageData = buffer.composed_buffer.to_ppm(buffer.renderparameters);
			System.IO.File.WriteAllText(fileName, imageData);
			delete imageData;

			// open finished composed image in system image viewer
			var psi = scope System.Diagnostics.ProcessStartInfo();
			psi.SetFileName(fileName);
			var process = scope System.Diagnostics.SpawnedProcess();
			process.Start(psi);
			*/
		}

		public static Color ray_color(ref Ray r, Hittable world, int depth)
		{
			var rec = hit_record();

			// If we've exceeded the ray bounce limit, no more light is gathered.
			if (depth <= 0)
				return Color(0, 0, 0);

			if (world.hit(r, 0.0001, Double.MaxValue, ref rec))
			{
				var scattered = Ray();
				var attenuation = Color();
				if (rec.mat_ptr.scatter(ref r, rec, ref attenuation, ref scattered))
					return attenuation * ray_color(ref scattered, world, depth - 1);
				return Color(0, 0, 0);
			}

			Vec3 unit_direction = Vec3.unit_vector(r.direction);
			let t = 0.5 * (unit_direction.y + 1.0);
			return (1.0 - t) * (Color(0.9, 0.9, 0.9)) + t * (Color(0.7, 0.8, 0.9));
		}

		public static HittableList create_random_scene(int seed = 0)
		{
			let world = new HittableList();
			let rand = scope Random(seed);

			var material_ground = new Lambertian(Color(0.8, 0.8, 0.0));
			world.add(new Sphere(Point3(0, -1000, 0), 1000, material_ground));

			for (int a = -11; a < 11; a++)
			{
				for (int b = -11; b < 11; b++)
				{
					let choose_mat = rand.NextDouble();
					let center = Point3(a + 0.9 * rand.NextDouble(), 0.2, b + 0.9 * rand.NextDouble());

					if ((center - Point3(4, 0.2, 0)).length() > 0.9)
					{
						if (choose_mat < 0.8)
						{
							// diffuse
							let albedo = Color.random() * Color.random();
							let sphere_material = new Lambertian(albedo);
							world.add(new Sphere(center, 0.2, sphere_material));
						} else if (choose_mat < 0.95)
						{
							// metal
							let albedo = Color.random(0.5, 1);
							let fuzz = rand.NextDouble() * 0.5;
							let sphere_material = new Metal(albedo, fuzz);
							world.add(new Sphere(center, 0.2, sphere_material));
						} else
						{
							// glass
							let sphere_material = new Dielectric(1.5);
							world.add(new Sphere(center, 0.2, sphere_material));
						}
					}
				}
			}

			let material1 = new Dielectric(1.5);
			world.add(new Sphere(Point3(0, 1, 0), 1.0, material1));
			let material2 = new Lambertian(Color(0.4, 0.2, 0.1));
			world.add(new Sphere(Point3(-4, 1, 0), 1.0, material2));
			let material3 = new Metal(Color(0.7, 0.6, 0.5), 0.0);
			world.add(new Sphere(Point3(4, 1, 0), 1.0, material3));
			return world;
		}
	}
}
