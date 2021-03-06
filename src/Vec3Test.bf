using System;

namespace ComprendRay
{
	class Vec3Test
	{
		[Test]
		public static void TestConstructorNoArgs()
		{
			let v = Vec3();
			Test.Assert(v.e[0] === 0);
			Test.Assert(v.e[1] === 0);
			Test.Assert(v.e[2] === 0);
		}

		[Test]
		public static void TestConstructorWithArgs()
		{
			let v = Vec3(2.0, 8.0, 12.0);
			Test.Assert(v.e[0] === 2.0);
			Test.Assert(v.e[1] === 8.0);
			Test.Assert(v.e[2] === 12.0);
		}

		[Test]
		public static void TestAccessByIndex()
		{
			let v = Vec3(2.0, 8.0, 12.0);
			Test.Assert(v[0] === 2.0);
			Test.Assert(v[1] === 8.0);
			Test.Assert(v[2] === 12.0);
		}

		[Test]
		public static void TestAccessByXYZ()
		{
			let v = Vec3(2.0, 8.0, 12.0);
			Test.Assert(v.x === 2.0);
			Test.Assert(v.y === 8.0);
			Test.Assert(v.z === 12.0);
		}

		[Test]
		public static void TestAddAssignOperator()
		{
			var v = Vec3(2.0, 8.0, 12.0);
			let v2 = Vec3(1.0, 1.0, 1.0);
			v += v2;
			Test.Assert(v.x === 3.0);
			Test.Assert(v.y === 9.0);
			Test.Assert(v.z === 13.0);
		}

		[Test]
		public static void TestSubtractAssignOperator()
		{
			var v = Vec3(2.0, 8.0, 12.0);
			let v2 = Vec3(1.0, 2.0, 4.0);
			v -= v2;
			Test.Assert(v.x === 1.0);
			Test.Assert(v.y === 6.0);
			Test.Assert(v.z === 8.0);
		}

		[Test]
		public static void TestLengthOneAxis()
		{
			let v = Vec3(2.0, 0.0, 0.0);
			Test.Assert(v.length() === 2.0);
		}

		[Test]
		public static void TestLengthAllAxis()
		{
			let v = Vec3(8.0, 3.0, 5.0);
			//                64  + 9 + 25  = 98
			//    square root(          98) = 9.8994949366116654
			Test.Assert(v.length() === 9.8994949366116654);
		}

		[Test]
		public static void TestMultiplyOperator()
		{
			let v1 = Vec3(2.0, 0.0, 5.0);
			let v2 = Vec3(5.5, 3.0, 3.0);
			Vec3 v = v1 * v2;
			Test.Assert(v[0] === 11.0);
			Test.Assert(v[1] === 0.0);
			Test.Assert(v[2] === 15.0);
		}

		[Test]
		public static void TestToString()
		{
			let v = Vec3(2.125, 0.0, 5.25);
			var str = scope String();
			v.ToString(str);

			Test.Assert(str == "2.125 0 5.25");
		}
	}
}
