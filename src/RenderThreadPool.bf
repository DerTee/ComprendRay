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
			}
			RenderBuffer = buffer;

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
				let fileName = scope $"image_final.ppm";
				write_image(fileName, buffer.composed_buffer);
				open_file_with_associated_app(fileName);
			}

			ThreadStart join_threads = new => join_threads_and_compose_final_image;
			MonitoringThread = new Thread(join_threads);
			MonitoringThread.SetName("Monitoring RenderThreads");
			MonitoringThread.Start();
		}

		public void Dispose()
		{
			if (RenderThreads != null) delete RenderThreads;
		}
	}
}