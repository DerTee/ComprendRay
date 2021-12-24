using SDL2;
using System;
using System.IO;
using ComprendRay.Utils;

namespace ComprendRay
{
	class RaytracerGUIApp : SDLApp
	{
		public String Title = new .("ComprendRay") ~ delete _; 
		/*private bool mIsRendering = false;*/
		private RenderBuffer mBuffer;
		private System.Threading.Thread mRenderthread;

		HittableList mScene = random_scene() ~ _.clear(); // the scene / world / list of raytraceable objects 


		/*let lookfrom = Point3(13, 2, 3);
		let lookat = Point3(0, 0, 0);
		let vup = Vec3(0, 1, 0);
		let dist_to_focus = 10;
		let aperture = 0.1;*/ 

		// Camera
		// var cam = scope Camera(lookfrom, lookat, vup, 20.0, aspect_ratio, aperture, dist_to_focus);
		Camera mCam = new .(Point3(13, 2, 3), Point3(0, 0, 0), Vec3(0, 1, 0), 20.0, 3 / 2, 0.1, 10) ~ delete _;

		public new void Init()
		{
			if (!SDL.VERSION_ATLEAST(2, 0, 9))
			{
				SDL.Version version = . { };
				SDL.VERSION(out version);
				System.Internal.FatalError(scope $"SDL version too low! Need at least SDL 2.0.9, found {version.major}.{version.minor}.{version.patch}!");
			}
			base.Init();

			let rp = RenderParameters();
			mBuffer = new RenderBuffer(rp);
		}

		public override void Draw()
		{ 
			// SDL.FillRect(mScreen, scope SDL.Rect(0, 0, 100, 100), 0xff0000);

			let user_pressed_start_render = true;
			if (user_pressed_start_render && mRenderthread == null)
			{
				void incremental_render_lambda()
			{
					render_scene(ref mScene, ref mCam, ref mBuffer);
				} 
				// System.Threading.ThreadStart incremental_render_call = new [&] => incremental_render_lambda;
				System.Threading.ThreadStart incremental_render_call = new [&] => incremental_render_lambda;

				mRenderthread = new System.Threading.Thread(incremental_render_call);
				mRenderthread.SetName("IncrementalRenderThread");
				mRenderthread.Start();
			} 

			// ToDo clean this mess up! this is a bug, because we can't rely mBuffer.current_sample, also we should not
			// check this internal state here
			if (!mRenderthread.IsAlive)
			{
			for (let x < mBuffer.renderparameters.image_width)
			{
				for (let y < mBuffer.renderparameters.image_height)
				{ 
					/*let last_finished_sample = 0;*/ 
						let color = mBuffer[x, y];
					set_pixel(mScreen, x, y, Color.to_uint(color));
				}
			} 
			// render next sample UNTESTESTED IF THIS WORKS!! check if the subsequent samples are filled in pixel
			// buffers!
			if (mBuffer.current_sample < mBuffer.renderparameters.samples_per_pixel)
			{
					delete mRenderthread; 

					// ToDo: this is copy paste from above, fix this!!
			void incremental_render_lambda()
			{
				render_scene(ref mScene, ref mCam, ref mBuffer);
			} 
			// System.Threading.ThreadStart incremental_render_call = new [&] => incremental_render_lambda;
			System.Threading.ThreadStart incremental_render_call = new [&] => incremental_render_lambda;

			mRenderthread = new System.Threading.Thread(incremental_render_call);
			mRenderthread.SetName("IncrementalRenderThread");
			mRenderthread.Start();
		}
				else // render finished -> write the ppm file
				{
					delete mRenderthread;
				}
			}
		}

		public static void set_pixel(SDL.Surface* surface, int32 x, int32 y, uint32 pixel)
		{
			uint32* target_pixel = (uint32*)((uint8*)(surface.pixels) + y * surface.pitch + x * 4);
			*target_pixel = pixel;
		}

		static void render_scene(ref HittableList world, ref Camera cam, ref RenderBuffer buffer)
		{
			let render_params = buffer.renderparameters; 
			// var start_time = DateTime.Now; 

			// Render

			// var Stream = System.Console.Out;

			var rand = scope Random();
			for (int32 y = render_params.image_height - 1; y >= 0; --y)
			{ 
				// Stream.Write("\rScanlines remaining: {0,5}", j);
				for (int32 x < render_params.image_width)
				{
					for (int32 s < render_params.samples_per_pixel)
					{
						let u = (x + rand.NextDouble()) / (render_params.image_width - 1);
						let v = (y + rand.NextDouble()) / (render_params.image_height - 1);
						var r = cam.get_ray(u, v);
						buffer[x, y] = ray_color(ref r, world, render_params.max_depth);
					}
				}
			}
			let current_sample = buffer.current_sample; 



			// Stream.Write(scope $"\nDone. Render time: {DateTime.Now - start_time}\n");

			let fileName = scope $"image_sample_{current_sample}.ppm"; 

			// TODO actually wanted to allocate from outside, pass to the function, but coulnt get it to work quickly,
			// fucking beef syntax hell, 1000 ways to do things and only very few are correct 
			/*var imageData = new String();*/ 
			/*defer delete imageData;*/ 
			/*colors_to_ppm(buffer, ref imageData);*/
			let imageData = colors_to_ppm(buffer);
			System.IO.File.WriteAllText(fileName, imageData);
			delete imageData;

			buffer.current_sample++;

			var psi = scope System.Diagnostics.ProcessStartInfo();
			psi.SetFileName(fileName);
			var process = scope System.Diagnostics.SpawnedProcess();
			process.Start(psi);
		}

		static Color ray_color(ref Ray r, Hittable world, int depth)
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

		static HittableList random_scene(int seed = 0)
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
