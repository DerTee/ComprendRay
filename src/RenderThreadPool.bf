using ComprendRay.Raytracer;
using System;
using System.Collections;
using System.Threading;


namespace ComprendRay
{
	struct RenderThreadPool
	{
		public uint8 NumThreads;
		public Thread MonitoringThread;
		public List<Thread> RenderThreads;
		public List<Action> JobList;
		public RenderBuffer RenderBuffer;
		public uint16 MaxStackSizeRenderThread = 16;

		public void Init() mut
		{
			var result = Platform.BfpSystemResult();
			var numLogicalCPUs = Platform.BfpSystem_GetNumLogicalCPUs(&result);

			if (result case .Ok) NumThreads = .(Math.Max(numLogicalCPUs - 1, 1));
			else Runtime.FatalError("Fatal error while trying to determine number of logical CPUs to adjust number of render threads.");
		}

		public bool IsRunning()
		{
			if (RenderThreads == null || RenderThreads.Count == 0) return false;
			for (let thread in RenderThreads)
			{
				if (thread != null) return true;
			}
			return false;
		}

		public void Start(ref HittableList world, ref Camera cam, ref RenderBuffer buffer) mut
		{
			if (RenderThreads == null)
			{
				RenderThreads = new .();
			} else
			{
				RenderThreads.Clear();
				delete MonitoringThread;
				for (let i < buffer.composed_buffer.pixels.Count) buffer.composed_buffer.pixels[i] = .();
			}

			NumThreads = (uint8)buffer.renderparameters.samples_per_pixel;
			for (let i < NumThreads)
			{
				// ToDo: this is not correct, it's just a temporary hack!
				// you could have more samples than threads or the other way around and both must be properly supported
				// a usable solution would probably be a joblist with all ThreadStarts and lambdas in it, those get fed
				// into the threads. No idea how to reuse existing threads, so the first implementation can probably
				// make do with deleting and recreating threads even though the internet says that has a lot of overhead.
				// I don't think this is a problem in this case with longrunning computationally expensive threads, but
				// still, it might be worth checking if anything surprisingly horrible happens.
				let sample = i;

				void incremental_render_lambda()
				{
					render_scene(ref world, ref cam, ref buffer, sample);
				}
				ThreadStart incremental_render = new => incremental_render_lambda;

				var Renderthread = new Thread(incremental_render);
				Renderthread.SetName(scope $"IncrementalRenderThread{i}");
				Renderthread.Start(false);
				RenderThreads.Add(Renderthread);
			}

			void join_threads_and_compose_final_image()
			{
				for (let thread in RenderThreads)
				{
					thread.Join();
					delete thread;
				}

				// ToDo this is shit, writing the image should not come from here, use a delegate later on
				// final image
				// let fileName = scope $"image_final.tga";
				// write_image(fileName, buffer.composed_buffer);
				// open_file_with_associated_app(fileName);
			}

			ThreadStart join_threads = new => join_threads_and_compose_final_image;
			MonitoringThread = new Thread(join_threads);
			MonitoringThread.SetName("Monitoring RenderThreads");
			MonitoringThread.Start(false);
		}

		public void Dispose()
		{
			if (MonitoringThread != null)
			{
				// MonitoringThread.Join();
				delete MonitoringThread;
			}
			if (RenderThreads != null)
			{
				/*
				for (let thread in RenderThreads)
				{
					if (thread != null)
					{
						// thread.Join();
						delete thread;
					}
				}
				*/
				delete RenderThreads;
			}
		}

		public void TogglePause()
		{
			// ToDo Bug threadstate is always .Running, even when suspend was called before. maybe suspend only works properly if there's a yield??? although, pausing clearly works, because the render does not continue after hitting pause. resuming is what does not worl.
			switch (MonitoringThread.ThreadState) {
			case .Running: Pause();
			case .Suspended | .SuspendRequested: UnPause();
			default: break;
			}
		}

		public void Pause()
		{
			for (let thread in RenderThreads)
			{
				thread.Suspend();
			}
			MonitoringThread.Suspend();
		}

		public void UnPause()
		{
			for (let thread in RenderThreads)
			{
				thread.Resume();
			}
			MonitoringThread.Resume();
		}
	}
}