using UnityEngine;

public class TransportShipLaunch : MonoBehaviour
{
	private Building b;

	public Transform actualTransformShipPrefab;

	private bool doDemolish;

	private void OnBuilt()
	{
		Transform transform = Object.Instantiate(actualTransformShipPrefab);
		b = GetComponent<Building>();
		if (b.uniqueNameHash == World.transportCartHash)
		{
			Vector3 position = base.transform.position;
			position.x += 0.5f;
			position.z += 0.5f;
			transform.position = position;
			transform.GetComponent<LogisticCart>().SetTeamID(GetComponent<Building>().TeamID());
			transform.rotation = base.transform.GetChild(0).rotation;
		}
		else
		{
			transform.GetComponent<ShipBase>().SetPos(GetComponent<Building>().Center());
			transform.GetComponent<ShipBase>().Init(GetComponent<Building>().TeamID());
			transform.rotation = base.transform.GetChild(0).rotation;
		}
		doDemolish = true;
	}

	private void Update()
	{
		if (doDemolish)
		{
			World.inst.DemolishBuilding(GetComponent<Building>(), reclaimResources: false);
			doDemolish = false;
		}
	}

	private void Start()
	{
		b = GetComponent<Building>();
		b.PlacementValidaton = CanPlace;
	}

	public void CanPlace(ref PlacementValidationResult result)
	{
		b = GetComponent<Building>();
		if (b.uniqueNameHash != World.transportCartHash)
		{
			return;
		}
		PlacementValidationResult newResult = result;
		b.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			if (cell.Type != TerrainType.None)
			{
				newResult = PlacementValidationResult.MustBeOnFlatLand;
			}
			if ((bool)cell.StructureFindByCategory(World.pathHash) && !cell.StructureFindByCategory(World.gateHash))
			{
				newResult = PlacementValidationResult.Valid;
			}
		});
		result = newResult;
	}
}
