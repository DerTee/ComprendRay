using System;

namespace prng_beef
{
	class SplitMix64Test
	{
		[Test]
		static void TestFirstSequence()
		{
			var sm = SplitMix64(0);
			for (var i < 10)
			{
				let val = sm.Next();
				Test.Assert(val != 0);
				Console.WriteLine(scope $"{i}: {val}");
			}
		}
	}
}