using System;

namespace prng_beef
{
	class XoroShiro128PlusTest
	{
		static void AssertArraysEqual<T>(T[10] expected, T[10] actual, int sequence_length)
		{
			for (var i < sequence_length)
			{
				Test.Assert(
					actual[i] == expected[i], scope $"At position {i} the expected value is {expected[i]}, but got {actual[i]}");
			}
		}

		[Test]
		static void TestU64FirstSequence()
		{
			const let sequence_length = 10;
			var expected_values = uint64[sequence_length](
				0,
				9007336693694464,
				11539493435383743488,
				1307346403661742080,
				1523677445145822208,
				713973829929755264,
				6128618322503699104,
				12180027098666644520,
				2160670818522032800,
				328387783555497074
				);
			var rnd = Xoroshiro128Plus(0, 1);
			uint64[sequence_length] values = ?;
			for (int i < sequence_length)
			{
				values[i] = rnd.NextU64();
				Console.WriteLine(scope $"{i}: {values[i]}");
			}

			AssertArraysEqual<uint64>(expected_values, values, sequence_length);
		}

		[Test]
		static void TestI64FirstSequence()
		{
			const let sequence_length = 10;
			var expected_values = int64[sequence_length](
				-9223372036854775807,
				-9214364700161081343,
				2316121398528967681,
				-7916025633193033727,
				-7699694591708953599,
				-8509398206925020543,
				-3094753714351076703,
				2956655061811868713,
				-7062701218332743007,
				-8894984253299278733
				);
			var rnd = Xoroshiro128Plus(0, 1);
			int64[sequence_length] values = ?;
			for (int i < sequence_length)
			{
				values[i] = rnd.NextI64();
				Console.WriteLine(scope $"{i}: {values[i]}");
			}

			AssertArraysEqual<int64>(expected_values, values, sequence_length);
		}


		// this test takes some time, but should complete in under 1 min even on low end PCs
		[Test]
		static void TestNaiveAverageValue()
		{
			var rnd = Xoroshiro128Plus(0, 1);
			let expected_avg = Int64.MaxValue + Int64.MinValue; // it's -1, but this makes clear that we check the whole range
			int64 avg = 0;
			let iterations = 1'000'000'000;
			let tolerance_percent = (double)0.1;
			let tolerance = ((double)Int64.MaxValue * tolerance_percent * 0.01); // one percent tolerance

			var file = new System.IO.BufferedFileStream();
			file.Create("TestNaiveAverageValue.csv", .Write);

			var writer = new System.IO.StreamWriter(file, .UTF8, 16384, true);
			defer delete writer;

			let first_line = "Running Average; Random Value";
			writer.WriteLine(first_line);
			for (int i in Range(1, iterations)) // start at 1 to avoid zero division workarounds for rand_val_weighted
			{
				let rand_val = rnd.NextI64();
				let rand_val_weighted = rand_val / i; // have to divide right here, otherwise `avg` overflows
				avg += rand_val_weighted;
				if (i % 10000 == 0) writer.WriteLine(scope $"{avg}");
			}

			Console.WriteLine(scope $"Average of {iterations} iterations: {avg}");
			let errmsg = scope $"Expected average of random values to be [{expected_avg - tolerance} - {expected_avg + tolerance}], but got {avg}, which is a deviation of {(double)(avg - expected_avg) / Int64.MaxValue}%";
			Test.Assert(avg > (expected_avg - tolerance) && avg < (expected_avg + tolerance), errmsg);
		}
	}
}