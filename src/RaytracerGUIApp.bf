using System;
using System.IO;
using raylib_beef;
using raylib_beef.Types;
using ComprendRay.Raytracer;


namespace ComprendRay
{
	struct RaytracerGUIApp
	{
		public String Title = new .("ComprendRay");
		private volatile RenderBuffer mBuffer;
		private RenderThreadPool mRenderThreadPool;
		private int32 screenwidth, screenheight;

		HittableList mScene = create_random_scene();

		// Camera
		ComprendRay.Camera mCam = new .(
			Point3(13, 2, 3), // lookfrom
			Point3(0, 0, 0), // lookat
			Vec3(0, 1, 0), // up vector
			20.0, // dist_to_focus
			3 / 2, // aspect ratio
			0.1, // aperture
			10 // focus_dist
			);

		public void Init() mut
		{
			let rp = RenderParameters();
			mBuffer = new RenderBuffer(rp);
			// mRenderThreadPool.num_threads = 12;
			mRenderThreadPool.NumThreads = (uint8)rp.samples_per_pixel;

			screenwidth = 800;
			screenheight = 600;
			Raylib.InitWindow(screenwidth, screenheight, Title);
			Raylib.SetTargetFPS(60);
		}

		public void Dispose()
		{
			// annoying to have to do this, but I don't want RenderThreadPool to be a class (which might be stupid)
			mRenderThreadPool.Dispose();
			delete mScene;
			delete mCam;
			delete mBuffer;
			delete Title;

			Raylib.CloseWindow();
		}

		public void Run() mut
		{
			while (!Raylib.WindowShouldClose())
			{
				// SDL.FillRect(mScreen, scope SDL.Rect(0, 0, 100, 100), 0xff0000);

				let user_pressed_start_render = true;
				if (user_pressed_start_render)
				{
					StartRender();
				}


				Raylib.BeginDrawing();
				defer Raylib.EndDrawing();
				Raylib.ClearBackground(.BLACK);
				// ToDo clean this mess up! this is a bug, because we can't rely mBuffer.current_sample, also we should not
				// check this internal state here
				for (let x < mBuffer.renderparameters.image_width)
				{
					for (let y < mBuffer.renderparameters.image_height)
					{
						/*let last_finished_sample = 0;*/
						let col = mBuffer.composed_buffer.pixels[x, y];
						let r = col.x;
						let g = col.y;
						let b = col.z;
						let color = raylib_beef.Types.Color(
							(uint8)(r * 256),
							(uint8)(g * 256),
							(uint8)(b * 256),
							(uint8)256);
						// set_pixel(mScreen, x, y, Color.to_uint(color));
						Raylib.DrawPixel(x, y, color);
					}
				}
			}
		}

		public void StartRender() mut
		{
			if (!mRenderThreadPool.IsRunning())
			{
				mRenderThreadPool.Start(ref mScene, ref mCam, ref mBuffer);
			}
		}
	}
}
