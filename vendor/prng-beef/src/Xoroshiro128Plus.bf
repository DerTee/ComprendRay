/*
Based on https://prng.di.unimi.it/xoroshiro128plus.c and translated to beef.
Original License:

Written in 2016-2018 by David Blackman and Sebastiano Vigna (vigna@acm.org)

To the extent possible under law, the author has dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide. This software is distributed without any warranty.

See <http://creativecommons.org/publicdomain/zero/1.0/>.



This is xoroshiro128+ 1.0, our best and fastest small-state generator
for floating-point numbers. We suggest to use its upper bits for
floating-point generation, as it is slightly faster than
xoroshiro128++/xoroshiro128**. It passes all tests we are aware of
except for the four lower bits, which might fail linearity tests (and
just those), so if low linear complexity is not considered an issue (as
it is usually the case) it can be used to generate 64-bit outputs, too;
moreover, this generator has a very mild Hamming-weight dependency
making our test (http://prng.di.unimi.it/hwd.php) fail after 5 TB of
output; we believe this slight bias cannot affect any application. If
you are concerned, use xoroshiro128++, xoroshiro128** or xoshiro256+.

We suggest to use a sign test to extract a random Boolean value, and
right shifts to extract subsets of bits.

The state must be seeded so that it is not everywhere zero. If you have
a 64-bit seed, we suggest to seed a splitmix64 generator and use its
output to fill s. 

NOTE: the parameters (a=24, b=16, b=37) of this version give slightly
better results in our test than the 2016 version (a=55, b=14, c=36).
*/

using System;

namespace prng_beef
{
	struct Xoroshiro128Plus
	{
		const uint32 A = 24;
		const uint32 B = 16;
		const uint32 C = 37;

		uint64[2] s;

		public this(uint64 seed)
		{
			var splitmix = SplitMix64(seed);
			s[0] = splitmix.Next();
			s[1] = splitmix.Next();
		}

		public this(uint64 s0, uint64 s1)
		{
			s[0] = s0;
			s[1] = s1;
		}

		[Inline]
		private static uint64 rotl(uint64 x, int k)
		{
			return (x << k) | (x >> (64 - k));
		}

		public uint64 NextU64() mut
		{
			let s0 = s[0];
			var s1 = s[1];
			let result = s0 * s1;

			s1 ^= s0;
			s[0] = rotl(s0, A) ^ s1 ^ (s1 << B);
			s[1] = rotl(s1, C);

			return result;
		}

		// Note Dertee: starting from here, I added .Next* methods following the API of System.Random that Beeflang ships with

		public int64 NextI64() mut
		{
			return (int64)NextU64() - System.Int64.MaxValue;
		}

		public double NextDouble() mut
		{
			return (NextI64() & Int64.MaxValue) * (double)(1.0 / Int64.MaxValue);
		}

		/// Generates a random double in range -1..1
		public double NextDoubleSigned() mut
		{
			return (NextI64() & Int64.MaxValue) * (double)(2.0 / Int64.MaxValue) - 1.0;
		}

		/// Generates a random bool by taking the leading bit of 64 bit random number
		public bool NextBool() mut
		{
			return (NextU64() >> 63) == 1;
		}



		/*  This is the jump function for the generator. It is equivalent
			to 2^64 calls to next(); it can be used to generate 2^64
			non-overlapping subsequences for parallel computations.

			TODO: unclear if this loop is correctly translated to beef, test!
		*/
		public void Jump() mut
		{
			let JUMP = uint64[2](0xdf900294d8f554a5, 0x170865df4b3201fc);

			uint64 s0 = 0;
			uint64 s1 = 0;
			for (int i < JUMP.Count)
			{
				for (int b < 64)
				{
					if ((JUMP[i] & 1 << b) != 0)
					{
						s0 ^= s[0];
						s1 ^= s[1];
					}
					NextU64();
				}
			}

			s[0] = s0;
			s[1] = s1;
		}

		/* This is the long-jump function for the generator. It is equivalent to
		   2^96 calls to next(); it can be used to generate 2^32 starting points,
		   from each of which jump() will generate 2^32 non-overlapping
		   subsequences for parallel distributed computations.

			TODO: unclear if this loop is correctly translated to beef, test!
		*/
		public void LongJump() mut
		{
			let LONG_JUMP = uint64[](0xd2a98b26625eee7b, 0xdddf9b1090aa7ac1);

			uint64 s0 = 0;
			uint64 s1 = 0;
			for (int i < LONG_JUMP.Count)
			{
				for (int b < 64)
				{
					if ((LONG_JUMP[i] & 1 << b) != 0)
					{
						s0 ^= s[0];
						s1 ^= s[1];
					}
					NextU64();
				}
			}
			s[0] = s0;
			s[1] = s1;
		}
	}
}