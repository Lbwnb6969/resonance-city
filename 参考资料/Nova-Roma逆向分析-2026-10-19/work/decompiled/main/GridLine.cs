using System;

public static class GridLine
{
	public readonly struct LineWalk(int startIndex, int endIndex, int width)
	{
		private readonly int startIndex = startIndex;

		private readonly int endIndex = endIndex;

		private readonly int width = width;

		public LineEnumerator GetEnumerator()
		{
			return new LineEnumerator(startIndex, endIndex, width);
		}
	}

	public struct LineEnumerator
	{
		private int x0;

		private int z0;

		private readonly int x1;

		private readonly int z1;

		private readonly int width;

		private readonly int dx;

		private readonly int dz;

		private readonly int sx;

		private readonly int sz;

		private int err;

		private bool started;

		public int Current => x0 + z0 * width;

		public LineEnumerator(int startIndex, int endIndex, int width)
		{
			this.width = width;
			x0 = startIndex % width;
			z0 = startIndex / width;
			x1 = endIndex % width;
			z1 = endIndex / width;
			dx = Math.Abs(x1 - x0);
			dz = Math.Abs(z1 - z0);
			sx = ((x0 < x1) ? 1 : (-1));
			sz = ((z0 < z1) ? 1 : (-1));
			err = dx - dz;
			started = false;
		}

		public bool MoveNext()
		{
			if (!started)
			{
				started = true;
				return true;
			}
			if (x0 == x1 && z0 == z1)
			{
				return false;
			}
			int num = 2 * err;
			if (num > -dz)
			{
				err -= dz;
				x0 += sx;
			}
			if (num < dx)
			{
				err += dx;
				z0 += sz;
			}
			return true;
		}
	}

	public static LineWalk Walk(int startIndex, int endIndex, int width)
	{
		return new LineWalk(startIndex, endIndex, width);
	}
}
