using UnityEngine;

public class TransportShipPort : MonoBehaviour
{
	public Building b;

	[SerializeField]
	private Transform[] landPositons;

	[SerializeField]
	private Transform[] waterPositions;

	private void Awake()
	{
		b = GetComponent<Building>();
		b.PlacementValidaton = PlacementValidation;
	}

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		if (b.transform.position.y > 0.35f)
		{
			validationResult = PlacementValidationResult.DockIsTooSteep;
		}
		int num = 0;
		int num2 = 0;
		for (int i = 0; i < waterPositions.Length; i++)
		{
			Cell cellDataClamped = World.inst.GetCellDataClamped(waterPositions[i].position);
			if (cellDataClamped.Type == TerrainType.Water)
			{
				num++;
			}
			else if (cellDataClamped.Type == TerrainType.Obstruction)
			{
				num2++;
			}
		}
		if (num == 0)
		{
			validationResult = PlacementValidationResult.DockNearWater;
		}
		else
		{
			if (validationResult != PlacementValidationResult.MustBeOnFlatLand || num2 != 0)
			{
				return;
			}
			for (int j = 0; j < landPositons.Length; j++)
			{
				Cell cellData = World.inst.GetCellData(landPositons[j].position);
				if (cellData != null && (cellData.Type == TerrainType.Obstruction || cellData.Type == TerrainType.Water))
				{
					return;
				}
			}
			validationResult = PlacementValidationResult.Valid;
		}
	}
}
