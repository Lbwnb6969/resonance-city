using System;
using UnityEngine;

namespace Assets;

public class Pier : MonoBehaviour
{
	[Serializable]
	public class PierSaveData : SaveClass<Pier, PierSaveData>
	{
		public override PierSaveData Pack(Pier obj)
		{
			return this;
		}

		public override Pier Unpack(Pier obj)
		{
			if (obj.GetComponent<Building>().IsBuilt())
			{
				obj.OnBuilt();
			}
			return obj;
		}
	}

	private void OnBuilt()
	{
		GetComponent<Building>().GetCell().Type = TerrainType.None;
	}

	private void Remove()
	{
		GetComponent<Building>().GetCell().Type = TerrainType.Water;
	}

	protected void OnInit()
	{
		GetComponent<Building>().PlacementValidaton = PlacementValidation;
	}

	public void PlacementValidation(ref PlacementValidationResult result)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(GetComponent<Building>().Center());
		if (cellDataClamped.SubStructure.Count > 0 && cellDataClamped.TopSubStructure.UniqueName != "moat")
		{
			result = PlacementValidationResult.ExistingStructure;
		}
	}

	private void OnDemolished()
	{
		Remove();
	}
}
