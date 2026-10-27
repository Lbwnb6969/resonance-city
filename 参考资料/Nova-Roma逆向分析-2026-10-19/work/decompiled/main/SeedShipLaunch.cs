using UnityEngine;

public class SeedShipLaunch : MonoBehaviour
{
	public Transform actualTransformShipPrefab;

	private bool doDemolish;

	private void OnBuilt()
	{
		Transform transform = Object.Instantiate(actualTransformShipPrefab);
		transform.GetComponent<ShipBase>().SetPos(GetComponent<Building>().Center());
		transform.GetComponent<ShipBase>().Init(GetComponent<Building>().TeamID());
		transform.rotation = base.transform.GetChild(0).rotation;
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
}
