using UnityEngine;

public class EmptyCave : MonoBehaviour
{
	private bool hadKeep;

	public bool replaceOnKeepPlacement;

	private bool firstUpdate = true;

	private void Update()
	{
		if (firstUpdate)
		{
			int num = (int)transform.position.z * World.inst.GridHeight + (int)transform.position.x;
			transform.GetChild(0).localRotation = Quaternion.Euler(0f, num % 4 * 90, 0f);
			firstUpdate = false;
		}
		if (hadKeep || !replaceOnKeepPlacement || World.inst.GetCellData(transform.position).landMassIdx == -1 || Player.inst.GetBuildingList(World.keepHash).Count <= 0)
		{
			return;
		}
		hadKeep = true;
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList(World.keepHash);
		bool flag = false;
		for (int i = 0; i < buildingList.Count; i++)
		{
			flag |= Mathff.DistXZ(buildingList.data[i].transform.position, transform.position) < 15f;
		}
		if (!flag && Player.inst.difficulty != Player.Difficulty.Peaceful)
		{
			Object.Destroy(gameObject);
			WolfDen wolfDen = World.inst.AddWolfDen((int)transform.position.x, (int)transform.position.z);
			int num2 = SRand.Range(3, 5);
			for (int j = 0; j < num2; j++)
			{
				wolfDen.AddWolf();
			}
		}
	}
}
