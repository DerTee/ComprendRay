using SDL2;
using System;
using System.IO;
using ComprendRay.Raytracer;
using SDL2;

namespace ComprendRay
{
	class RaytracerGUIApp : SDLApp
	{
		public String Title = new .("ComprendRay") ~ delete _;
		private RenderBuffer mBuffer ~ delete _;
		private RenderThreadPool mRenderThreadPool;

		HittableList mScene = create_random_scene() ~ delete _;

		// Camera
		Camera mCam = new .(
			Point3(13, 2, 3), // lookfrom
			Point3(0, 0, 0), // lookat
			Vec3(0, 1, 0), // up vector
			20.0, // dist_to_focus
			3 / 2, // aspect ratio
			0.1, // aperture
			10 // focus_dist
			) ~ delete _;

		public ~this()
		{
			// annoying to have to do this, but I don't want RenderThreadPool to be a class (which might be stupid)
			mRenderThreadPool.Dispose();
		}

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
			// mRenderThreadPool.num_threads = 12;
			mRenderThreadPool.NumThreads = (uint8)rp.samples_per_pixel;
		}

		public override void Draw()
		{
			// SDL.FillRect(mScreen, scope SDL.Rect(0, 0, 100, 100), 0xff0000);

			let user_pressed_start_render = true;
			if (user_pressed_start_render)
			{
				StartRender();
			}

			// ToDo clean this mess up! this is a bug, because we can't rely mBuffer.current_sample, also we should not
			// check this internal state here
			for (let x < mBuffer.renderparameters.image_width)
			{
				for (let y < mBuffer.renderparameters.image_height)
				{
					/*let last_finished_sample = 0;*/
					let color = mBuffer.composed_buffer.pixels[x, y];
					set_pixel(mScreen, x, y, Color.to_uint(color));
				}
			}
		}

		public void StartRender()
		{
			if (!mRenderThreadPool.IsRunning())
			{
				mRenderThreadPool.Start(ref mScene, ref mCam, ref mBuffer);
			}
		}

		public static void set_pixel(SDL.Surface* surface, int32 x, int32 y, uint32 pixel)
		{
			uint32* target_pixel = (uint32*)((uint8*)(surface.pixels) + y * surface.pitch + x * 4);
			*target_pixel = pixel;
		}
	}
}
