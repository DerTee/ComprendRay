using System;

namespace ComprendRay
{
	class RenderBuffer
	{
		public PixelBuffer[] pixelbuffers;
		public RenderParameters renderparameters;
		public int32 current_sample = 0;
		public Vec2Int current_pixel = .(0, 0);

		public this(RenderParameters rp)
		{
			renderparameters = rp;

			pixelbuffers = new PixelBuffer[rp.samples_per_pixel];
			for (let i < pixelbuffers.Count)
			{
				pixelbuffers[i] = PixelBuffer(rp.image_width, rp.image_height);
			}
		}

		public ~this()
		{
			for (let pb in pixelbuffers)
			{
				delete pb.pixels;
			}
			delete pixelbuffers;
		}

		public Color this[int x, int y]
		{
			[Inline] get
			{
				return pixelbuffers[current_sample].pixels[x, y];
			}
			[Inline] set
			{
				pixelbuffers[current_sample].pixels[x, y] = value;
			}
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