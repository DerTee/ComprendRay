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

		public Color this[int x, int y]
		{
			[Inline] get
			{
				return pixelbuffers[current_sample].pixels[x, y];
			}
			[Inline] set
			{
				pixelbuffers[current_sample].pixels[x, y] = value;

				// TODO this is a shitty, unexpected, implicit way to create the composed buffer, make it explicit and expected
				let scale = 1.0 / current_sample;
				var composed_pixel = Color();
				for (let i < current_sample)
				{
					composed_pixel += scale * pixelbuffers[i].pixels[x, y];
					// composed_pixel += Math.Sqrt(scale * pixelbuffers[i].pixels[x, y]);
				}
				composed_buffer.pixels[x, y] = composed_pixel;
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

		public String to_ppm(RenderParameters render_params)
		{
			var imageData = new $"P3\n{render_params.image_width} {render_params.image_height}\n255\n";
			for (var y = render_params.image_height - 1; y >= 0; y--)
			{
				for (var x < render_params.image_width)
				{
					let pixel = pixels[x, y];
					let (r, g, b) = (pixel.x, pixel.y, pixel.z);
					imageData.AppendF("\n{} {} {}",
						(int)(256 * Math.Clamp(r, 0.0, 0.999)),
						(int)(256 * Math.Clamp(g, 0.0, 0.999)),
						(int)(256 * Math.Clamp(b, 0.0, 0.999))
						);
				}
			}
			return imageData;
			/*write_color(ref imageData, *pixel_color, render_params.samples_per_pixel);*/
		}
	}
}