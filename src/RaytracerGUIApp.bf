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
		private uint16 displayedBufferIndex; // the rendered buffer currently shown, 0 = composed buffer, rest are samples + 1

		HittableList mScene;

		// Camera
		ComprendRay.Camera mCam;

		public void Init() mut
		{
			mScene = create_random_scene();
			let rp = RenderParameters();
			mCam = new .(
				Point3(13, 2, 3), // lookfrom
				Point3(0, 0, 0), // lookat
				Vec3(0, 1, 0), // up vector
				20.0, // dist_to_focus
				rp.aspect_ratio, // aspect ratio
				0.1, // aperture
				10 // focus_dist
				);
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
				let pressed_start_render = Raylib.IsKeyReleased(.KEY_ENTER);
				let pressed_pause_render = Raylib.IsKeyReleased(.KEY_SPACE);
				let pressed_next_sample_image = Raylib.IsKeyReleased(.KEY_RIGHT);
				let pressed_previous_sample_image = Raylib.IsKeyReleased(.KEY_LEFT);
				let pressed_new_scene = Raylib.IsKeyReleased(.KEY_N);


				if (pressed_start_render) StartRender();
				if (pressed_pause_render) TogglePauseRender();
				if (pressed_next_sample_image)
				{
					if (displayedBufferIndex >= mBuffer.renderparameters.samples_per_pixel)
						displayedBufferIndex = 0;
					else
						displayedBufferIndex += 1;
				}
				if (pressed_previous_sample_image)
				{
					if (displayedBufferIndex == 0)
						displayedBufferIndex = mBuffer.renderparameters.samples_per_pixel;
					else
						displayedBufferIndex -= 1;
				}
				if (pressed_new_scene)
				{
					delete mScene;
					mScene = create_random_scene();
				}

				PixelBuffer displayBuffer;
				if (displayedBufferIndex == 0) displayBuffer = mBuffer.composed_buffer;
				else displayBuffer = mBuffer.pixelbuffers[displayedBufferIndex - 1];

				Raylib.BeginDrawing();
				defer Raylib.EndDrawing();
				Raylib.ClearBackground(.RAYWHITE);

				for (let x < mBuffer.renderparameters.image_width)
				{
					for (let y < mBuffer.renderparameters.image_height)
					{
						/*let last_finished_sample = 0;*/
						let col = displayBuffer.pixels[x, y];
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
			// if (!mRenderThreadPool.IsRunning())
			// {
			mRenderThreadPool.Start(ref mScene, ref mCam, ref mBuffer);
			// }
		}

		public void TogglePauseRender() mut
		{
			mRenderThreadPool.TogglePause();
		}
	}
}
