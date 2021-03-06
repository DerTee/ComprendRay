using System;

namespace ComprendRay
{
	class Sphere : Hittable
	{
		public Point3 center;
		public double radius;
		public Material mat_ptr;

		public this() { }
		public this(Point3 cen, double r, Material m)
		{
			radius = r;
			center = cen;
			mat_ptr = m;
		}

		public ~this()
		{
			delete mat_ptr;
		}

		public bool hit(Ray r, double t_min, double t_max, ref hit_record rec)
		{
			Vec3 oc = r.origin - center;
			let a = r.direction.length_squared();
			let half_b = Vec3.dot(oc, r.direction);
			let c = oc.length_squared() - radius * radius;
			let discriminant = half_b * half_b - a * c;

			if (discriminant > 0)
			{
				let root = Math.Sqrt(discriminant);

				var temp = (-half_b - root) / a;
				if (temp < t_max && temp > t_min)
				{
					rec.t = temp;
					rec.p = r.at(rec.t);
					Vec3 outward_normal = (rec.p - center) / radius;
					rec.set_face_normal(r, outward_normal);
					rec.mat_ptr = mat_ptr;
					return true;
				}

				temp = (-half_b + root) / a;
				if (temp < t_max && temp > t_min)
				{
					rec.t = temp;
					rec.p = r.at(rec.t);
					Vec3 outward_normal = (rec.p - center) / radius;
					rec.set_face_normal(r, outward_normal);
					rec.mat_ptr = mat_ptr;
					return true;
				}
			}
			return false;
		}
	}
}
