using System;

namespace ComprendRay.Utils
{
	public static
	{
		[Inline]
		public static double degrees_to_radians(double degrees)
		{
			return degrees * Math.PI_d / 180;
		}


		public static String colors_to_ppm(RenderBuffer buffer)
		{
			let render_params = buffer.renderparameters;
			var imageData = new $"P3\n{render_params.image_width} {render_params.image_height}\n255\n"; 


			// Divide the color by the number of samples 
			/*let scale = 1.0 / render_params.samples_per_pixel;
			r = Math.Sqrt(scale * r);
			g = Math.Sqrt(scale * g);
			b = Math.Sqrt(scale * b);*/
			for (var x < render_params.image_width)
			{
				for (var y < render_params.image_height)
				{
					let pixel = buffer[x, y];
					let r = pixel.x;
					let g = pixel.y;
					let b = pixel.z;
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
