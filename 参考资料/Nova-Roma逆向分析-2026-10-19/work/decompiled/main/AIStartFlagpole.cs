using UnityEngine;

public class AIStartFlagpole : MonoBehaviour
{
	private bool held;

	public Vector3 desiredPos;

	public int landmass = -1;

	private void Start()
	{
	}

	public bool OnLandmass()
	{
		return landmass != -1;
	}

	public void SetLandMass(int landmass)
	{
		this.landmass = landmass;
		if (landmass != -1)
		{
			Debug.Log("landmass: " + landmass);
			Vector3 zero = Vector3.zero;
			ArrayExt<Cell> arrayExt = World.inst.cellsToLandmass[landmass];
			for (int i = 0; i < arrayExt.Count; i++)
			{
				zero += arrayExt.data[i].Center2D;
			}
			zero /= (float)arrayExt.Count;
			desiredPos = zero;
		}
	}

	public void SetHoldPosition(Vector3 pos)
	{
		held = true;
		transform.position = pos;
	}

	public int StopHolding(Vector3 pos)
	{
		held = false;
		transform.position = pos;
		Cell cellData = World.inst.GetCellData(pos);
		if (cellData != null && cellData.landMassIdx != -1 && World.inst.IsValidStartLandmassForAI(cellData.landMassIdx))
		{
			SetLandMass(cellData.landMassIdx);
		}
		return landmass;
	}

	public void SetFlagMaterial(Material mat)
	{
		transform.Find("Pivot/FlagHolder/Flag").GetComponent<MeshRenderer>().material = mat;
	}

	private void Update()
	{
		if (!held)
		{
			transform.position = Vector3.MoveTowards(transform.position, desiredPos, Time.deltaTime * 100f);
		}
	}

	internal void ClearFlag()
	{
		landmass = -1;
		gameObject.SetActive(value: false);
	}
}
