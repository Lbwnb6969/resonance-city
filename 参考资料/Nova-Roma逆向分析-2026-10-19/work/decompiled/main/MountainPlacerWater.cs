using UnityEngine;

public class MountainPlacerWater : MonoBehaviour
{
	public static ArrayExt<ArrayExt<Vector3>> mountainWaterPositions = new ArrayExt<ArrayExt<Vector3>>(8);

	public static void ProcessMountainWater(int targetAmt, ArrayExt<Vector4>[] interiorBounds)
	{
		for (int i = 0; i < mountainWaterPositions.Count; i++)
		{
			ArrayExt<Vector4> arrayExt = interiorBounds[i];
			float num = float.MaxValue;
			float num2 = float.MaxValue;
			float num3 = float.MinValue;
			float num4 = float.MinValue;
			for (int j = 0; j < arrayExt.Count; j++)
			{
				if (arrayExt.data[j].x < num)
				{
					num = arrayExt.data[j].x;
				}
				if (arrayExt.data[j].y < num2)
				{
					num2 = arrayExt.data[j].y;
				}
				if (arrayExt.data[j].z > num3)
				{
					num3 = arrayExt.data[j].z;
				}
				if (arrayExt.data[j].w > num4)
				{
					num4 = arrayExt.data[j].w;
				}
			}
			Vector3 b = new Vector3((num3 + num) / 2f, 0f, (num4 + num2) / 2f);
			ArrayExt<Vector3> arrayExt2 = mountainWaterPositions.data[i];
			for (int k = 0; k < targetAmt; k++)
			{
				if (arrayExt2.Count <= 0)
				{
					break;
				}
				float num5 = float.MaxValue;
				int num6 = -1;
				for (int l = 0; l < arrayExt2.Count; l++)
				{
					float num7 = Mathff.DistSqrdXZ(arrayExt2.data[l], b);
					if (num7 < num5)
					{
						num5 = num7;
						num6 = l;
					}
				}
				if (num6 != -1)
				{
					Cell cellData = World.inst.GetCellData(arrayExt2.data[num6]);
					DynamicWater.inst.CreateWaterSourceNewMap(cellData, DynamicWater.inst.sourceAmount);
					arrayExt2.RemoveAt(num6);
				}
			}
		}
	}

	public void AddWaterPositions(int landmass)
	{
		ArrayExt<Vector3> arrayExt = mountainWaterPositions.data[landmass];
		for (int i = 0; i < transform.childCount; i++)
		{
			Transform child = transform.GetChild(i);
			arrayExt.Add(child.position);
		}
	}
}
