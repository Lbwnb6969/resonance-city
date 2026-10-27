using System.Collections.Generic;
using UnityEngine;

public class LegionPhysicsSystem : MonoBehaviour
{
	public float maxUphillInclineDampening = 0.5f;

	public float uphillDamping = 1f;

	public float cellDamping = 1f;

	public float cellAccel = 5f;

	public float cellAccelForCharge = 10f;

	public float cellSpeed = 1f;

	public float springConstant = 20f;

	public float antiPenetrationForce = 10f;

	public float physicsStepSize = 0.016f;

	public float springBreakThreshold = 0.25f;

	private static LegionPhysicsSystem inst;

	public List<Vector2Int> obstacles = new List<Vector2Int>();

	public static LegionPhysicsSystem Inst => inst;

	public void Awake()
	{
		inst = this;
	}
}
