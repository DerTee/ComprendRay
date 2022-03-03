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

		// these are the current render params, that might be changed during rendering, but they will only be used on next render. the current buffer has its own copy of the original params it was started with
		private RenderParameters mRenderParameters;

		private int32 screenwidth, screenheight;
		private uint16 displayedBufferIndex; // the rendered buffer currently shown, 0 = composed buffer, rest are samples + 1

		HittableList mScene;

		// Camera
		ComprendRay.Camera mCam;

		public void Init() mut
		{
			mScene = create_random_scene();
			mRenderParameters = RenderParameters();
			mCam = new .(
				Point3(13, 2, 3), // lookfrom
				Point3(0, 0, 0), // lookat
				Vec3(0, 1, 0), // up vector
				20.0, // dist_to_focus
				mRenderParameters.aspect_ratio, // aspect ratio
				0.1, // aperture
				10 // focus_dist
				);
			mBuffer = new RenderBuffer(mRenderParameters);

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
				// get all input
				let pressed_start_render = Raylib.IsKeyReleased(.KEY_ENTER);
				let pressed_pause_render = Raylib.IsKeyReleased(.KEY_SPACE);
				let pressed_next_sample_image = Raylib.IsKeyReleased(.KEY_RIGHT);
				let pressed_previous_sample_image = Raylib.IsKeyReleased(.KEY_LEFT);
				let pressed_new_scene = Raylib.IsKeyReleased(.KEY_N);
				let pressed_increase_samples = Raylib.IsKeyReleased(.KEY_UP);
				let pressed_decrease_samples = Raylib.IsKeyReleased(.KEY_DOWN);

				let mouse_pos = (Raylib.GetMouseX(), Raylib.GetMouseY());
				let has_focused_pixel = mouse_pos.0 < mRenderParameters.image_width && mouse_pos.1 < mRenderParameters.image_height;


				// do logic
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
				if (pressed_increase_samples) mRenderParameters.samples_per_pixel = (uint16)Math.Min(11, mRenderParameters.samples_per_pixel + 1);
				if (pressed_decrease_samples) mRenderParameters.samples_per_pixel = (uint16)Math.Max(1, mRenderParameters.samples_per_pixel - 1);

				PixelBuffer displayBuffer;
				if (displayedBufferIndex == 0) displayBuffer = mBuffer.composed_buffer;
				else displayBuffer = mBuffer.pixelbuffers[displayedBufferIndex - 1];

				ComprendRay.Color focused_pixel = .();
				if (has_focused_pixel)
				{
					// in raylib y = 0 is topmost pixel, in the raytracer it's the bottom pixel -> needs flip
					let y_flipped = mBuffer.renderparameters.image_height - mouse_pos.1;
					focused_pixel = displayBuffer.pixels[mouse_pos.0, y_flipped];
				}

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

				// if (has_focused_pixel)
				if (true)
				{
					let block_y = Math.Max(0, screenheight - 150);
					let block_x = Math.Max(0, screenwidth - 150);
					Raylib.DrawText(scope $"X {mouse_pos.0} Y {mouse_pos.1}", block_x, block_y, 10, .BLUE);
					if (has_focused_pixel)
					{
						Raylib.DrawText(scope $"R {focused_pixel[0]}", block_x, block_y + 14, 12, .BLUE);
						Raylib.DrawText(scope $"G {focused_pixel[1]}", block_x, block_y + 14 * 2, 12, .BLUE);
						Raylib.DrawText(scope $"B {focused_pixel[2]}", block_x, block_y + 14 * 3, 12, .BLUE);
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
			if (mBuffer != null) delete mBuffer;
			mBuffer = new RenderBuffer(mRenderParameters);
			mRenderThreadPool.Start(ref mScene, ref mCam, ref mBuffer);
			// }
		}

		public void TogglePauseRender() mut
		{
			mRenderThreadPool.TogglePause();
		}
	}
}
