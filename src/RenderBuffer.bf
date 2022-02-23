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

		public String to_ppm()
		{
			let image_width = pixels.GetLength(0);
			let image_height = pixels.GetLength(1);
			var imageData = new $"P3\n{image_width} {image_height}\n255\n";
			for (var y = image_height - 1; y >= 0; y--)
			{
				for (var x < image_width)
				{
					let pixel = pixels[x, y];
					let (r, g, b) = (pixel.x, pixel.y, pixel.z);
					imageData.AppendF("\n{} {} {}",
						(uint8)(256 * Math.Clamp(r, 0.0, 0.999)),
						(uint8)(256 * Math.Clamp(g, 0.0, 0.999)),
						(uint8)(256 * Math.Clamp(b, 0.0, 0.999))
						);
				}
			}
			return imageData;
		}
	}
}