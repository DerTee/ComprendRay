using System;

namespace ComprendRay
{
	class RenderBuffer
	{
		/// every single sample, basically we have a raw progression of 1-sample images here, which are are averaged and composed into a single one
		public PixelBuffer[] pixelbuffers;

		/// the image that is composed from all pixelbuffers, can be in progress, so it's not necessarily the final image, just the "most finished" one
		public PixelBuffer composed_buffer;

		public RenderParameters renderparameters;

		public this(RenderParameters rp)
		{
			renderparameters = rp;

			pixelbuffers = new PixelBuffer[rp.samples_per_pixel];
			for (let i < pixelbuffers.Count)
			{
				pixelbuffers[i] = PixelBuffer(rp.image_width, rp.image_height);
			}
			composed_buffer = PixelBuffer(rp.image_width, rp.image_height);
		}

		public ~this()
		{
			for (let pb in pixelbuffers)
			{
				delete pb.pixels;
			}
			delete pixelbuffers;
			delete composed_buffer.pixels;
		}
	}

	struct PixelBuffer
	{
		public Color[,] pixels;
		public this(int width, int height)
		{
			pixels = new Color[width, height];
		}
	}
}