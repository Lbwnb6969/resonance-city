using UnityEngine;

public class MountainPlacerItem : MonoBehaviour
{
	public enum PlacementType
	{
		Absolute,
		Drop
	}

	public PlacementType placementType;

	public float appearanceProbability = 1f;

	public bool rotate180X;

	public bool rotate180Y;

	public bool rotate180Z;

	public MinMax scaleMod = new MinMax(1f, 1f);
}
