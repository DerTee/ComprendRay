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
			Raylib.SetTargetFPS(30);
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

				let user_pressed_start_render = Raylib.IsKeyDown(.KEY_ENTER);
				if (user_pressed_start_render)
				{
					StartRender();
				}

				let user_pressed_pause_render = Raylib.IsKeyDown(.KEY_SPACE);
				if (user_pressed_pause_render)
				{
					TogglePauseRender();
				}


				Raylib.BeginDrawing();
				defer Raylib.EndDrawing();
				Raylib.ClearBackground(.RAYWHITE);

				for (let x < mBuffer.renderparameters.image_width)
				{
					for (let y < mBuffer.renderparameters.image_height)
					{
						/*let last_finished_sample = 0;*/
						let col = mBuffer.composed_buffer.pixels[x, y];
						let (r, g, b) = (col.x, col.y, col.z);
						let color = raylib_beef.Types.Color(
							(uint8)(r * 255),
							(uint8)(g * 255),
							(uint8)(b * 255),
							(uint8)255);

						// in raylib y = 0 is topmost pixel, in the raytracer it's the bottom pixel -> needs flip
						let y_flipped = mBuffer.renderparameters.image_height - y;
						Raylib.DrawPixel(x, y_flipped, color);
					}
				}

				if (mRenderThreadPool.MonitoringThread != null)
				{
					let monitoring_threadstate = mRenderThreadPool.MonitoringThread.ThreadState;
					String state;
					switch (monitoring_threadstate) {
					case .Unstarted: state = "Unstarted";
					case .Suspended: state = "Suspended";
					case .SuspendRequested: state = "SuspendRequested";
					case .Running: state = "Running";
					case .Aborted: state = "Aborted";
					case .Background: state = "Background";
					default: state = "not exhaustive";
					}
					Raylib.DrawText(scope $"Number of RenderThreads: {mRenderThreadPool.RenderThreads.Count}, State of Monitoringthread: {monitoring_threadstate}",
						10, screenheight - 50, 12, .BLUE
						);
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

		public void TogglePauseRender() mut
		{
			if (mRenderThreadPool.IsRunning())
			{
				mRenderThreadPool.TogglePause();
			}
		}
	}
}
