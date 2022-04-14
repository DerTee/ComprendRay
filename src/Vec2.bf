using System;

namespace ComprendRay
{
	struct Vec2
	{
		public double[2] e;

		[ThreadStatic]
		private static prng_beef.Xoroshiro128Plus rand = prng_beef.Xoroshiro128Plus((uint64)System.Platform.BfpSystem_GetTimeStamp());

		public this()
		{
			e = .(0.0, 0.0);
		}

		public this(double e0, double e1)
		{
			e = .(e0, e1);
		}

		public double this[int key]
		{
			[Inline] get { return e[key]; }
				[Inline] set mut { e[key] = value; }
		}

		[Inline]
		public static Vec2 random()
		{
			return Vec2(rand.NextDouble(), rand.NextDouble());
		}

		[Inline]
		public static Vec2 random(double min, double max)
		{
			let range = max - min;
			return Vec2(rand.NextDouble() * range + min, rand.NextDouble() * range + min);
		}
	}

	struct Vec2Int
	{
		public int16[2] e;

		public this()
		{
			e = .(0, 0);
		}

		public this(int16 e0, int16 e1)
		{
			e = .(e0, e1);
		}

		public int16 this[int key]
		{
			[Inline] get { return e[key]; }
				[Inline] set mut { e[key] = value; }
		}
	}
}