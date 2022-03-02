using System;

namespace ComprendRay
{
	struct RenderParameters
	{
		public uint16 image_width = (uint16)(320);
		public uint16 image_height = (uint16)(240);
		public float aspect_ratio = image_width / image_height;
		public uint16 samples_per_pixel = 1;
		public uint16 max_depth = 3;

		public enum ParameterError
		{
			case UnknownError;
			case Error(String msg);
		}

		public static Result<RenderParameters, ParameterError> create_from_cli_args(String[] args)
		{
			var rp = RenderParameters();
			for (int i < args.Count)
			{
				let arg = args[i];
				let next_arg = (i + 1) < args.Count ? args[i + 1] : "";
				switch (arg) {
				case "--samples","-s":
					if (next_arg.IsEmpty)
					{
						// System.Console.Error.WriteLine($"Parameter {arg} needs number of samples after it!");
						return .Err(.Error(scope $"Parameter {arg} needs number of samples after it!"));
						// break;
					}
					let samples = System.Int32.Parse(next_arg);
					switch (samples) {
					case .Err:
						// System.Console.Error.WriteLine($"{next_arg} is not a valid number of samples! Parameter {arg} needs number of samples after it!");
						return .Err(.Error(scope $"{next_arg} is not a valid number of samples! Parameter {arg} needs number of samples after it!"));
					case .Ok:
						rp.samples_per_pixel = (uint16)samples;
					}
				case "--width","-w":
					if (next_arg.IsEmpty)
					{
						System.Console.Error.WriteLine($"Parameter {arg} needs pixel width after it!");
						break;
					}
					let width = System.UInt32.Parse(next_arg);
					switch (width) {
					case .Err:
						// System.Console.Error.WriteLine($"{next_arg} is not a valid pixel width!");
						return .Err(.Error(scope $"{next_arg} is not a valid pixel width!"));
					case .Ok: rp.image_width = (uint16)width;
					}
				case "--help","-h","?":
					print_cli_help();
				default:
					System.Console.Error.Write(
						"""
						Unknown parameter!
						""");
				}
			}
			rp.image_height = (uint16)(rp.image_width / rp.aspect_ratio);
			return .Ok(rp);
		}

		public static void print_cli_help()
		{
			System.Console.Write(
				"""
				--samples(-s) samples per pixel
				--height(-h) pixel height
				--width(-w) pixel width
				""");
		}
	}
}
