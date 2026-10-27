using UnityEngine;

public struct LegionCell
{
	public int id;

	public int type;

	public Vector3 position;

	public Vector3 direction;

	public bool inUse;

	public bool dead;

	public bool onBridge;

	public float deadTime;

	public Vector3 velocity;

	public Vector3 acceleration;

	public Vector3 dampForceThisFrame;

	public int attackingCellId;

	public int spearTargetCellId;

	public int attackBuildingX;

	public int attackBuildingZ;

	public bool hitObstruction;

	public Vector3 contactNormal;
}
