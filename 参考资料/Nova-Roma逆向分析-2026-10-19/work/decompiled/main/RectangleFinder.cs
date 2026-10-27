using System.Collections.Generic;
using UnityEngine;

public class RectangleFinder
{
	public class RectangleCoordinates
	{
		public bool isSquare;

		public int area;

		public int lowerX;

		public int lowerZ;

		public int upperX;

		public int upperZ;

		public int sizeX;

		public int sizeZ;

		public bool foundRectangle;

		public bool isRotated;

		public bool IsSame(RectangleCoordinates targetCoords)
		{
			if (targetCoords == null)
			{
				return false;
			}
			if (targetCoords.lowerX == lowerX && targetCoords.lowerZ == lowerZ && targetCoords.upperX == upperX && targetCoords.upperZ == upperZ && targetCoords.sizeX == sizeX)
			{
				return targetCoords.sizeZ == sizeZ;
			}
			return false;
		}

		public bool IsSameSize(RectangleCoordinates targetCoords)
		{
			if (targetCoords != null)
			{
				if (sizeX != targetCoords.sizeX || sizeZ != targetCoords.sizeZ)
				{
					if (sizeX == targetCoords.sizeZ)
					{
						return sizeZ == targetCoords.sizeX;
					}
					return false;
				}
				return true;
			}
			return false;
		}

		public bool IsIntersecting(RectangleCoordinates tCoords)
		{
			if (upperX <= tCoords.lowerX || tCoords.upperX <= lowerX || upperZ <= tCoords.lowerZ || tCoords.upperZ <= lowerZ)
			{
				return false;
			}
			return true;
		}

		public RectangleCoordinates()
		{
		}

		public RectangleCoordinates(RectangleCoordinates copyTarget)
		{
			isSquare = copyTarget.isSquare;
			area = copyTarget.area;
			lowerX = copyTarget.lowerX;
			lowerZ = copyTarget.lowerZ;
			upperX = copyTarget.upperX;
			upperZ = copyTarget.upperZ;
			sizeX = copyTarget.sizeX;
			sizeZ = copyTarget.sizeZ;
			foundRectangle = true;
			isRotated = false;
		}

		public void CopyFrom(RectangleCoordinates targetCoords)
		{
			isSquare = targetCoords.isSquare;
			area = targetCoords.area;
			lowerX = targetCoords.lowerX;
			lowerZ = targetCoords.lowerZ;
			upperX = targetCoords.upperX;
			upperZ = targetCoords.upperZ;
			sizeX = targetCoords.sizeX;
			sizeZ = targetCoords.sizeZ;
			foundRectangle = true;
			isRotated = false;
		}
	}

	public delegate bool ValidCell(int x, int z);

	public delegate bool ValidRectangle(int lowerX, int lowerZ, int upperX, int upperZ, bool isSquare, bool isHorizontal = true);

	private static bool[] isValidCopy;

	public static RectangleCoordinates FindLargestRectangle(int minX, int maxX, int minZ, int maxZ, ValidCell filter)
	{
		return FindFirstRectangle(minX, maxX, minZ, maxZ, int.MaxValue, int.MaxValue, filter);
	}

	public static List<RectangleCoordinates> FindLargestRectangles(int minX, int maxX, int minZ, int maxZ, DynamicMeshSize[] sizes, bool[] isValidMap)
	{
		List<RectangleCoordinates> list = new List<RectangleCoordinates>(8);
		if (isValidCopy == null || isValidCopy.Length != isValidMap.Length)
		{
			isValidCopy = new bool[isValidMap.Length];
		}
		isValidMap.CopyTo(isValidCopy, 0);
		int gridWidth = World.inst.GridWidth;
		RectangleCoordinates rectangleCoordinates = null;
		do
		{
			rectangleCoordinates = CalculateLargestRectangle(minX, maxX + 1, minZ, maxZ + 1, sizes, isValidCopy);
			if (rectangleCoordinates == null)
			{
				continue;
			}
			for (int i = rectangleCoordinates.lowerX; i < rectangleCoordinates.upperX; i++)
			{
				for (int j = rectangleCoordinates.lowerZ; j < rectangleCoordinates.upperZ; j++)
				{
					int num = i + j * gridWidth;
					isValidCopy[num] = false;
				}
			}
			list.Add(rectangleCoordinates);
		}
		while (rectangleCoordinates != null);
		return list;
	}

	public static RectangleCoordinates CalculateLargestRectangle(int minX, int maxX, int minZ, int maxZ, DynamicMeshSize[] sizes, bool[] isValidMap)
	{
		RectangleCoordinates rectangleCoordinates = new RectangleCoordinates();
		int num = maxX - minX;
		int num2 = maxZ - minZ;
		int gridWidth = World.inst.GridWidth;
		Stack<int> stack = new Stack<int>();
		int[] histogram = new int[num];
		int[] array = new int[num];
		int num3 = 0;
		int maxAreaFromSizes = GetMaxAreaFromSizes(sizes);
		for (int i = 0; i < num2; i++)
		{
			UpdateHistogram(ref histogram, minZ + i, minX, isValidMap, gridWidth);
			int num4 = -1;
			for (int j = 0; j < num; j++)
			{
				if (histogram[j] != 0)
				{
					while (stack.Count > 0 && histogram[stack.Peek()] >= histogram[j])
					{
						stack.Pop();
					}
					int num5 = num4;
					if (stack.Count > 0)
					{
						num5 = Mathf.Max(num5, stack.Peek());
					}
					array[j] = num5;
				}
				else
				{
					array[j] = 0;
					num4 = j;
				}
				stack.Push(j);
			}
			stack.Clear();
			int num6 = num;
			for (int num7 = num - 1; num7 >= 0; num7--)
			{
				if (histogram[num7] != 0)
				{
					while (stack.Count > 0 && histogram[stack.Peek()] >= histogram[num7])
					{
						stack.Pop();
					}
					int num8 = num6;
					if (stack.Count > 0)
					{
						num8 = Mathf.Min(num8, stack.Peek());
					}
					int width = num8 - 1 - (array[num7] + 1) + 1;
					int height = histogram[num7];
					RectangleCoordinates rectangleCoordinates2 = GenerateRectangle(i, height, width, num8, sizes, minX, minZ);
					if (rectangleCoordinates2.area > num3)
					{
						num3 = rectangleCoordinates2.area;
						rectangleCoordinates.CopyFrom(rectangleCoordinates2);
						if (num3 == maxAreaFromSizes)
						{
							return rectangleCoordinates;
						}
					}
					stack.Push(num7);
				}
				else
				{
					num6 = num7;
				}
			}
			stack.Clear();
		}
		if (rectangleCoordinates.area <= 0)
		{
			return null;
		}
		return rectangleCoordinates;
	}

	private static int GetMaxAreaFromSizes(DynamicMeshSize[] sizes)
	{
		int num = 0;
		for (int i = 0; i < sizes.Length; i++)
		{
			if (num < sizes[i].area)
			{
				num = sizes[i].area;
			}
		}
		return num;
	}

	private static RectangleCoordinates GenerateRectangle(int z, int height, int width, int rBound, DynamicMeshSize[] sizes, int minX, int minZ)
	{
		RectangleCoordinates rectangleCoordinates = new RectangleCoordinates();
		RectangleCoordinates rectangleCoordinates2 = new RectangleCoordinates();
		for (int num = sizes.Length - 1; num >= 0; num--)
		{
			DynamicMeshSize dynamicMeshSize = sizes[num];
			rectangleCoordinates2.lowerX = minX + rBound - Mathf.Min(width, dynamicMeshSize.sizeX);
			rectangleCoordinates2.upperX = minX + rBound;
			rectangleCoordinates2.lowerZ = minZ + z - (Mathf.Min(height, dynamicMeshSize.sizeZ) - 1);
			rectangleCoordinates2.upperZ = minZ + z + 1;
			rectangleCoordinates2.sizeX = rectangleCoordinates2.upperX - rectangleCoordinates2.lowerX;
			rectangleCoordinates2.sizeZ = rectangleCoordinates2.upperZ - rectangleCoordinates2.lowerZ;
			rectangleCoordinates2.area = rectangleCoordinates2.sizeX * rectangleCoordinates2.sizeZ;
			rectangleCoordinates2.isRotated = false;
			rectangleCoordinates2.isSquare = rectangleCoordinates2.sizeX == rectangleCoordinates2.sizeZ;
			if (rectangleCoordinates2.area > rectangleCoordinates.area)
			{
				rectangleCoordinates.CopyFrom(rectangleCoordinates2);
			}
			if (rectangleCoordinates2.area == dynamicMeshSize.area)
			{
				break;
			}
			if (dynamicMeshSize.sizeX != dynamicMeshSize.sizeZ)
			{
				rectangleCoordinates2.lowerX = minX + rBound - Mathf.Min(width, dynamicMeshSize.sizeZ);
				rectangleCoordinates2.upperX = minX + rBound;
				rectangleCoordinates2.lowerZ = minZ + z - (Mathf.Min(height, dynamicMeshSize.sizeX) - 1);
				rectangleCoordinates2.upperZ = minZ + z + 1;
				rectangleCoordinates2.sizeX = rectangleCoordinates2.upperX - rectangleCoordinates2.lowerX;
				rectangleCoordinates2.sizeZ = rectangleCoordinates2.upperZ - rectangleCoordinates2.lowerZ;
				rectangleCoordinates2.area = rectangleCoordinates2.sizeX * rectangleCoordinates2.sizeZ;
				rectangleCoordinates2.isRotated = true;
				if (rectangleCoordinates2.area == dynamicMeshSize.area)
				{
					rectangleCoordinates.CopyFrom(rectangleCoordinates2);
					break;
				}
				if (rectangleCoordinates2.area > rectangleCoordinates.area)
				{
					rectangleCoordinates.CopyFrom(rectangleCoordinates2);
				}
			}
		}
		rectangleCoordinates.foundRectangle = rectangleCoordinates.area > 0;
		return rectangleCoordinates;
	}

	private static RectangleCoordinates GenerateRectangle(int z, int height, int width, int rBound, int maxSizeX, int maxSizeZ, int minX, int minZ)
	{
		RectangleCoordinates rectangleCoordinates = new RectangleCoordinates();
		rectangleCoordinates.lowerX = minX + rBound - Mathf.Min(width, maxSizeX);
		rectangleCoordinates.upperX = minX + rBound;
		rectangleCoordinates.lowerZ = minZ + z - (Mathf.Min(height, maxSizeZ) - 1);
		rectangleCoordinates.upperZ = minZ + z + 1;
		rectangleCoordinates.sizeX = rectangleCoordinates.upperX - rectangleCoordinates.lowerX;
		rectangleCoordinates.sizeZ = rectangleCoordinates.upperZ - rectangleCoordinates.lowerZ;
		rectangleCoordinates.area = rectangleCoordinates.sizeX * rectangleCoordinates.sizeZ;
		rectangleCoordinates.foundRectangle = rectangleCoordinates.area > 0;
		return rectangleCoordinates;
	}

	public static RectangleCoordinates FindFirstRectangle(int minX, int maxX, int minZ, int maxZ, int maxSizeX, int maxSizeZ, ValidCell filter)
	{
		RectangleCoordinates rectangleCoordinates = new RectangleCoordinates();
		Stack<int> stack = new Stack<int>();
		int[] histogram = new int[maxX - minX];
		int[] array = new int[maxX - minX];
		int num = 0;
		for (int i = minZ; i <= maxZ; i++)
		{
			UpdateHistogram(ref histogram, i, minX, filter);
			int num2 = -1;
			for (int j = minX; j < maxX; j++)
			{
				int num3 = j - minX;
				if (histogram[num3] != 0)
				{
					while (stack.Count > 0 && histogram[num3] <= histogram[stack.Peek()])
					{
						stack.Pop();
					}
					int num4 = num2;
					if (stack.Count != 0)
					{
						num4 = Mathff.Max(num4, stack.Peek());
					}
					array[num3] = num4;
				}
				else
				{
					array[num3] = 0;
					num2 = num3;
				}
				stack.Push(num3);
			}
			stack.Clear();
			int num5 = maxX - minX;
			for (int num6 = maxX - 1; num6 >= minX; num6--)
			{
				int num7 = num6 - minX;
				if (histogram[num7] != 0)
				{
					while (stack.Count > 0 && histogram[num7] <= histogram[stack.Peek()])
					{
						stack.Pop();
					}
					int num8 = num5;
					if (stack.Count != 0)
					{
						num8 = Mathff.Min(num8, stack.Peek());
					}
					stack.Push(num7);
					int num9 = num8 - 1 - (array[num7] + 1) + 1;
					int num10 = histogram[num7] * num9;
					if (num9 >= maxSizeX && histogram[num7] >= maxSizeZ)
					{
						rectangleCoordinates.area = maxSizeX * maxSizeZ;
						rectangleCoordinates.lowerX = minX + array[num7] + 1;
						rectangleCoordinates.lowerZ = i - (histogram[num7] - 1);
						rectangleCoordinates.upperX = rectangleCoordinates.lowerX + maxSizeX;
						rectangleCoordinates.upperZ = rectangleCoordinates.lowerZ + maxSizeZ;
						rectangleCoordinates.sizeX = maxSizeX;
						rectangleCoordinates.sizeZ = maxSizeZ;
						rectangleCoordinates.isSquare = IsSquare(rectangleCoordinates);
						return rectangleCoordinates;
					}
					if (num10 > num)
					{
						num = (rectangleCoordinates.area = num10);
						rectangleCoordinates.lowerX = minX + array[num7] + 1;
						rectangleCoordinates.lowerZ = i - (histogram[num7] - 1);
						rectangleCoordinates.upperX = minX + num8;
						rectangleCoordinates.upperZ = i + 1;
						rectangleCoordinates.sizeX = rectangleCoordinates.upperX - rectangleCoordinates.lowerX;
						rectangleCoordinates.sizeZ = rectangleCoordinates.upperZ - rectangleCoordinates.lowerZ;
					}
				}
				else
				{
					num5 = num7;
				}
			}
		}
		if (rectangleCoordinates.area != 0)
		{
			return rectangleCoordinates;
		}
		return null;
	}

	public static RectangleCoordinates FindValidRectangle(int minX, int maxX, int minZ, int maxZ, int maxSizeX, int maxSizeZ, ValidCell filter, ValidRectangle validRectangle)
	{
		RectangleCoordinates rectangleCoordinates = new RectangleCoordinates();
		Stack<int> stack = new Stack<int>();
		Stack<int> stack2 = new Stack<int>();
		int[] histogram = new int[maxX - minX];
		int[] array = new int[maxX - minX];
		int[] array2 = new int[maxX - minX];
		bool flag = maxSizeX == maxSizeZ;
		for (int i = minZ; i <= maxZ; i++)
		{
			UpdateHistogram(ref histogram, i, minX, filter);
			int num = -1;
			for (int j = minX; j < maxX; j++)
			{
				int num2 = j - minX;
				if (histogram[num2] != 0)
				{
					while (stack.Count > 0 && (histogram[num2] <= histogram[stack.Peek()] || histogram[stack.Peek()] >= maxSizeZ))
					{
						stack.Pop();
					}
					int num3 = num;
					if (stack.Count != 0)
					{
						num3 = Mathff.Max(num3, stack.Peek());
					}
					array[num2] = num3;
					if (!flag)
					{
						while (stack2.Count > 0 && (histogram[num2] <= histogram[stack2.Peek()] || histogram[stack2.Peek()] >= maxSizeX))
						{
							stack2.Pop();
						}
						num3 = num;
						if (stack2.Count != 0)
						{
							num3 = Mathff.Max(num3, stack2.Peek());
						}
						array2[num2] = num3;
					}
					else
					{
						array2[num2] = num3;
					}
				}
				else
				{
					array[num2] = 0;
					array2[num2] = 0;
					num = num2;
				}
				stack.Push(num2);
				stack2.Push(num2);
			}
			stack.Clear();
			stack2.Clear();
			for (int num4 = maxX - 1; num4 >= minX; num4--)
			{
				int num5 = num4 - minX;
				if (histogram[num5] == 0)
				{
					continue;
				}
				int num6 = num5 - (array[num5] + 1) + 1;
				int num7 = num5 - (array2[num5] + 1) + 1;
				int num8 = histogram[num5];
				bool isHorizontal = false;
				int num9 = 0;
				int num10 = 0;
				int num11 = 0;
				int num12 = 0;
				int num13 = 0;
				int num14 = 0;
				num11 = num4 + 1;
				if (num6 >= maxSizeX && num8 >= maxSizeZ)
				{
					num13 = maxSizeX;
					num14 = maxSizeZ;
					isHorizontal = true;
					num9 = Mathff.Max(minX + array[num5], num11 - num13);
				}
				else
				{
					if (flag || num7 < maxSizeZ || num8 < maxSizeX)
					{
						continue;
					}
					num13 = maxSizeZ;
					num14 = maxSizeX;
					num9 = Mathff.Max(minX + array2[num5], num11 - num13);
				}
				num12 = i + 1;
				num10 = i - Mathff.Min(histogram[num5] - 1, num14 - 1);
				if (validRectangle(num9, num10, num11, num12, maxSizeX == maxSizeZ, isHorizontal))
				{
					rectangleCoordinates.lowerX = num9;
					rectangleCoordinates.lowerZ = num10;
					rectangleCoordinates.upperX = num11;
					rectangleCoordinates.upperZ = num12;
					rectangleCoordinates.foundRectangle = true;
					rectangleCoordinates.sizeX = rectangleCoordinates.upperX - rectangleCoordinates.lowerX;
					rectangleCoordinates.sizeZ = rectangleCoordinates.upperZ - rectangleCoordinates.lowerZ;
					return rectangleCoordinates;
				}
			}
		}
		return rectangleCoordinates;
	}

	private static bool IsSquare(RectangleCoordinates coords)
	{
		return IsSquare(coords.lowerX, coords.lowerZ, coords.upperX, coords.upperZ);
	}

	public static bool IsSquare(int lowerX, int lowerZ, int upperX, int upperZ)
	{
		return upperX - lowerX == upperZ - lowerZ;
	}

	private static int RectangleArea(RectangleCoordinates coords)
	{
		return RectangleArea(coords.lowerX, coords.lowerZ, coords.upperX, coords.upperZ);
	}

	public static int RectangleArea(int lowerX, int lowerZ, int upperX, int upperZ)
	{
		if (lowerX > upperX || lowerZ > upperZ)
		{
			return 0;
		}
		return (upperX - lowerX + 1) * (upperZ - lowerZ + 1);
	}

	private static void UpdateHistogram(ref int[] histogram, int z, int minX, ValidCell filter)
	{
		for (int i = 0; i < histogram.Length; i++)
		{
			if (filter(i + minX, z))
			{
				histogram[i]++;
			}
			else
			{
				histogram[i] = 0;
			}
		}
	}

	private static void UpdateHistogram(ref int[] histogram, int z, int minX, bool[] isValidMap, int gWidth)
	{
		for (int i = 0; i < histogram.Length; i++)
		{
			if (isValidMap[minX + i + z * gWidth])
			{
				histogram[i]++;
			}
			else
			{
				histogram[i] = 0;
			}
		}
	}
}
