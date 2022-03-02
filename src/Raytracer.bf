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

		public static void render_scene(ref HittableList world, ref Camera cam, ref RenderBuffer buffer, uint16 sample)
		{
			let render_params = buffer.renderparameters;
			var rand = scope Random();
			for (int32 y < render_params.image_height)
			{
				for (int32 x < render_params.image_width)
				{
					let u = (x + rand.NextDouble()) / (render_params.image_width - 1);
					let v = (y + rand.NextDouble()) / (render_params.image_height - 1);
					var r = cam.get_ray(u, v);
					let pixel = ray_color(ref r, world, render_params.max_depth);
					buffer.pixelbuffers[sample].pixels[x, y] = pixel;

					// ToDo This is a bit shit, because during rendering not all samples are done, so dividing by
					// samples_per_pixel makes the image too dark in the beginning and that only improves with more
					// samples being done
					// One solution would be to let all threads work on the same sample, so we always know where we are
					buffer.composed_buffer.pixels[x, y] += pixel / render_params.samples_per_pixel;
				}
			}

			// write_image(scope $"image_sample_{sample}.ppm", buffer.pixelbuffers[sample]);
		}

		public static void write_image(StringView fileName, PixelBuffer buffer)
		{
			write_image_tga(fileName, buffer);
		}

		public static void write_image_ppm(StringView fileName, PixelBuffer buffer)
		{
			var pixels = buffer.pixels;

			let image_width = pixels.GetLength(0);
			let image_height = pixels.GetLength(1);
			var imageData = new $"P3\n{image_width} {image_height}\n255\n";
			for (var y = image_height - 1; y >= 0; y--)
			{
				for (var x < image_width)
				{
					let pixel = pixels[x, y];
					let (r, g, b) = (pixel.x, pixel.y, pixel.z);
					imageData.AppendF("\n{} {} {}",
						(uint8)(256 * Math.Clamp(r, 0.0, 0.999)),
						(uint8)(256 * Math.Clamp(g, 0.0, 0.999)),
						(uint8)(256 * Math.Clamp(b, 0.0, 0.999))
						);
				}
			}

			System.IO.File.WriteAllText(fileName, imageData);
			delete imageData;
		}

		public static void write_image_tga(StringView fileName, PixelBuffer buffer)
		{
			var pixels = buffer.pixels;

			let image_width = (uint16)pixels.GetLength(0);
			let image_height = (uint16)pixels.GetLength(1);

			// see https://en.wikipedia.org/wiki/Truevision_TGA#Header or https://www.gamers.org/dEngine/quake3/TGA.txt
			let tga_header_size = 18;
			let color_depth_in_byte = 3;
			// uint32 size_in_bytes = (uint32)(tga_header_size + (image_width * image_height * color_depth_in_byte));
			uint32 size_in_bytes = (uint32)tga_header_size + 1 + (uint32)image_width * image_height * color_depth_in_byte;
			// expecting 921 618

			var imageData = new uint8[size_in_bytes];
			defer delete imageData;
			imageData[0] = 0; // Length of the image ID field
			imageData[1] = 0; // Color map type: 0 if image file contains no color map
			imageData[2] = 2; // Image type: 2 uncompressed true-color image

			// 5 bytes Color map specification
			imageData[3] = 0;
			imageData[4] = 0;
			imageData[5] = 0;
			imageData[6] = 0;
			imageData[7] = 0;

			// 10 bytes Image specification

			// X-origin (2 bytes): absolute coordinate of lower-left corner for displays where origin is at the lower left
			imageData[8] = 0;
			imageData[9] = 0;

			// Y-origin (2 bytes lo-hi): as for X-origin
			// imageData[10] = (uint8)(image_height & 0x00ff);
			// imageData[11] = (uint8)(image_height >> 8);
			imageData[10] = 0;
			imageData[11] = 0;

			// Image width (2 bytes lo-hi): width in pixels
			imageData[12] = (uint8)(image_width & 0x00ff);
			imageData[13] = (uint8)(image_width >> 8);

			// Height of Image (2 bytes lo-hi)
			imageData[14] = (uint8)(image_height & 0x00ff);
			imageData[15] = (uint8)(image_height >> 8);

			imageData[16] = 24; // Pixel depth (1 byte): bits per pixel
			imageData[17] = 0; // Image Descriptor Byte. This entire byte should be set to 0.  Don't ask me.
			imageData[18] = 0; // Image Identification Field. It's usually omitted ( length in byte 1 = 0 ), but can be up to 255 characters.

			uint32 cursor = 19; // start RGB data after the header bytes
			// for (var y = image_height - 1; y >= 0; y--)
			for (var y < image_height)
			{
				for (var x < image_width)
				{
					let pixel = pixels[x, y];
					let (r, g, b) = (pixel.x, pixel.y, pixel.z);

					// seems like TGA needs colors in the order green, red, blue. no idea why.
					imageData[cursor] = (uint8)(256 * Math.Clamp(g, 0.0, 0.999));
					imageData[cursor + 1] = (uint8)(256 * Math.Clamp(r, 0.0, 0.999));
					imageData[cursor + 2] = (uint8)(256 * Math.Clamp(b, 0.0, 0.999));
					cursor += 3;
				}
			}
			System.IO.File.WriteAll(fileName, imageData);
		}

		public static void open_file_with_associated_app(StringView fileName)
		{
			var psi = scope System.Diagnostics.ProcessStartInfo();
			psi.SetFileName(fileName);
			var process = scope System.Diagnostics.SpawnedProcess();
			process.Start(psi);
		}

		// HOT FUNCTION!!
		// recursive function, maybe rewrite as a loop for either performance testing or
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
			let rand = scope Random();

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
