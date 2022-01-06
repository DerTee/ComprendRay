using SDL2;
using System;
using System.IO;
using ComprendRay.Raytracer;

namespace ComprendRay
{
	class RaytracerGUIApp : SDLApp
	{
		public String Title = new .("ComprendRay") ~ delete _;
		/*private bool mIsRendering = false;*/
		private RenderBuffer mBuffer ~ delete _;
		private System.Threading.Thread mRenderthread1;
		private System.Threading.Thread mRenderthread2;
		private System.Threading.Thread mRenderthread3;

		HittableList mScene = create_random_scene() ~ delete _;

		// Camera
		Camera mCam = new .(
			Point3(13, 2, 3), // lookfrom
			Point3(0, 0, 0), // lookat
			Vec3(0, 1, 0), // up vector
			20.0, // dist_to_focus
			3 / 2, // aspect ratio
			0.1, // aperture
			10) ~ delete _;

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
			if (user_pressed_start_render)
			{
				StartNewRenderThread();
			}

			// ToDo clean this mess up! this is a bug, because we can't rely mBuffer.current_sample, also we should not
			// check this internal state here
			for (let x < mBuffer.renderparameters.image_width)
			{
				for (let y < mBuffer.renderparameters.image_height)
				{
					/*let last_finished_sample = 0;*/
					let color = mBuffer[x, y];
					set_pixel(mScreen, x, y, Color.to_uint(color));
				}
			}
		}

		public void StartNewRenderThread()
		{
			if (mRenderthread1 !== null || mRenderthread2 !== null || mRenderthread3 !== null)
			{
				return;
			}
			void incremental_render_lambda1()
			{
				render_scene(ref mScene, ref mCam, ref mBuffer, 0);
			}
			System.Threading.ThreadStart incremental_render_call1 = new => incremental_render_lambda1;

			void incremental_render_lambda2()
			{
				render_scene(ref mScene, ref mCam, ref mBuffer, 1);
			}
			System.Threading.ThreadStart incremental_render_call2 = new => incremental_render_lambda2;

			void incremental_render_lambda3()
			{
				render_scene(ref mScene, ref mCam, ref mBuffer, 2);
			}
			System.Threading.ThreadStart incremental_render_call3 = new => incremental_render_lambda3;


			mRenderthread1 = new System.Threading.Thread(incremental_render_call1);
			mRenderthread1.SetName("IncrementalRenderThread1");
			mRenderthread1.Start();

			mRenderthread2 = new System.Threading.Thread(incremental_render_call2);
			mRenderthread2.SetName("IncrementalRenderThread2");
			mRenderthread2.Start();

			mRenderthread3 = new System.Threading.Thread(incremental_render_call3);
			mRenderthread3.SetName("IncrementalRenderThread3");
			mRenderthread3.Start();
		}

		public static void set_pixel(SDL.Surface* surface, int32 x, int32 y, uint32 pixel)
		{
			uint32* target_pixel = (uint32*)((uint8*)(surface.pixels) + y * surface.pitch + x * 4);
			*target_pixel = pixel;
		}
	}
}
