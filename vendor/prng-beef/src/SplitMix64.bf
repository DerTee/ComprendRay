/*  Written in 2015 by Sebastiano Vigna (vigna@acm.org)
	Retrieved from https://github.com/svaarala/duktape/blob/master/misc/splitmix64.c
	and translated from C to Beeflang by DerTee in 2022


To the extent possible under law, the author has dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide. This software is distributed without any warranty.
See <http://creativecommons.org/publicdomain/zero/1.0/>. */


/* This is a fixed-increment version of Java 8's SplittableRandom generator
   See http://dx.doi.org/10.1145/2714064.2660195 and
   http://docs.oracle.com/javase/8/docs/api/java/util/SplittableRandom.html
   It is a very fast generator passing BigCrush, and it can be useful if
   for some reason you absolutely want 64 bits of state; otherwise, we
   rather suggest to use a xoroshiro128+ (for moderately parallel
   computations) or xorshift1024* (for massively parallel computations)
   generator. */


namespace prng_beef
{
	struct SplitMix64
	{
		uint64 x; /* The state can be seeded with any value. */

		public this(uint64 seed)
		{
			x = seed;
		}

		public uint64 Next() mut
		{
			uint64 z = (x += (uint64)0x9E3779B97F4A7C15);
			z = (z ^ (z >> 30)) * (uint64)0xBF58476D1CE4E5B9;
			z = (z ^ (z >> 27)) * (uint64)0x94D049BB133111EB;
			return z ^ (z >> 31);
		}
	}
}