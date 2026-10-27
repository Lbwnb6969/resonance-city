using System;
using Sirenix.OdinInspector;
using UnityEngine;

public class VillagerPropsManager : MonoBehaviour
{
	[Serializable]
	public class PropData
	{
		[Serializable]
		public struct Waypoint
		{
			public Transform point;

			public int Type;
		}

		public const int TYPE_VILLAGER = 0;

		public const int TYPE_LEGION = 1;

		public const int TYPE_MILITIA = 2;

		public const int TYPE_INVADER = 3;

		public static ValueDropdownList<int> TypeDropDownList = new ValueDropdownList<int>
		{
			{ "Villager", 0 },
			{ "Legion", 1 },
			{ "Militia", 2 },
			{ "Invader", 3 }
		};

		public int type;

		public const int STATUS_IDLE = 0;

		public const int STATUS_TRAVELING = 1;

		public const int TYPE_IDLE_POINT = 0;

		public const int TYPE_TRAVEL_POINT = 1;

		public static ValueDropdownList<int> TypeOptions = new ValueDropdownList<int>
		{
			{ "IdlePoint", 0 },
			{ "TravelPoint", 1 }
		};

		[NonSerialized]
		public int WaypointIdx;

		public Waypoint[] Waypoints;

		[NonSerialized]
		public int status;

		public const float MIN_TIMER_DURATION = 0.5f;

		public const float MAX_TIMER_DURATION = 3f;

		[NonSerialized]
		public Timer idleTimer;

		[NonSerialized]
		public int currRotate;

		public const int MAX_ROTATE_AMOUNT = 2;

		[NonSerialized]
		public Vector3 origLookDir;

		[NonSerialized]
		public Vector3 targetLookDir;

		public Transform prop;

		[NonSerialized]
		public float bounceTime;

		[NonSerialized]
		public int headColorIdx;

		[NonSerialized]
		public int bodyColorIdx;

		[NonSerialized]
		public int hairColorIdx;

		[NonSerialized]
		public MeshFilter mFilter;

		[NonSerialized]
		public MeshRenderer mRenderer;

		public void CalculateLookDirection()
		{
			targetLookDir = Quaternion.AngleAxis(SRand.Range(-75f, 75f), Vector3.forward) * origLookDir;
			targetLookDir.y = 0f;
		}

		public void SetStatus(int s)
		{
			if (s == 0)
			{
				idleTimer.Duration = SRand.Range(0.5f, 3f);
				idleTimer.CurrTime = 0f;
				currRotate = 0;
				origLookDir = Waypoints[WaypointIdx].point.forward;
				origLookDir.y = 0f;
				origLookDir.Normalize();
				CalculateLookDirection();
				bounceTime = 0f;
				prop.GetChild(0).localPosition = Vector3.zero;
			}
			status = s;
		}

		public void NextWaypoint()
		{
			WaypointIdx = (WaypointIdx + 1) % Waypoints.Length;
		}
	}

	public float propMoveSpeed = 0.5f;

	public float propRotateSpeed = 0.25f;

	public AnimationCurve bounceCurve;

	public float bounceSpeed = 1f;

	public float bounceMagnitude = 1f;

	public PropData[] props;

	public Material personMaterial;

	public Mesh villagerMaleMesh;

	public Mesh villagerFemaleMesh;

	public Mesh militiaMesh;

	public Mesh legionMesh;

	private bool isShowing = true;

	private void Awake()
	{
		for (int i = 0; i < props.Length; i++)
		{
			PropData propData = props[i];
			Transform child = propData.prop.GetChild(0);
			propData.mRenderer = child.GetComponent<MeshRenderer>();
			propData.mFilter = child.GetComponent<MeshFilter>();
			propData.WaypointIdx = 0;
			PropData.Waypoint waypoint = propData.Waypoints[propData.WaypointIdx];
			propData.prop.localPosition = waypoint.point.localPosition;
			propData.prop.localRotation = waypoint.point.localRotation;
			propData.idleTimer = new Timer(SRand.Range(0.5f, 3f));
			propData.idleTimer.CurrTime = 0f;
			propData.SetStatus(0);
		}
	}

	private void Update()
	{
		if (!isShowing)
		{
			return;
		}
		float deltaTime = Time.deltaTime;
		for (int i = 0; i < props.Length; i++)
		{
			PropData propData = props[i];
			PropData.Waypoint waypoint = propData.Waypoints[propData.WaypointIdx];
			switch (propData.status)
			{
			case 0:
				if (propData.idleTimer.Update(deltaTime))
				{
					propData.currRotate++;
					if (propData.currRotate == 2)
					{
						propData.NextWaypoint();
						propData.SetStatus(1);
					}
					else
					{
						propData.CalculateLookDirection();
					}
				}
				else
				{
					float t = propData.idleTimer.CurrTime / propData.idleTimer.Duration;
					propData.prop.localRotation = Quaternion.Lerp(propData.prop.localRotation, Quaternion.LookRotation(transform.InverseTransformDirection(propData.targetLookDir)), t);
				}
				break;
			case 1:
			{
				Vector3 newPos = propData.prop.localPosition;
				Vector3 forward = propData.Waypoints[propData.WaypointIdx].point.localPosition - newPos;
				forward.y = 0f;
				if (Mathff.MoveTowards(propData.prop.localPosition, propData.Waypoints[propData.WaypointIdx].point.localPosition, deltaTime * propMoveSpeed, out var actualAmt, out newPos))
				{
					if (waypoint.Type != 1)
					{
						propData.SetStatus(0);
					}
					else
					{
						propData.NextWaypoint();
					}
				}
				if (forward.magnitude > 0.0001f)
				{
					propData.prop.localRotation = Quaternion.RotateTowards(propData.prop.localRotation, Quaternion.LookRotation(forward), actualAmt * propRotateSpeed);
				}
				propData.prop.localPosition = newPos;
				propData.bounceTime = (propData.bounceTime + deltaTime * bounceSpeed) % 1f;
				Transform child = propData.prop.GetChild(0);
				Vector3 localPosition = child.localPosition;
				localPosition.y = bounceCurve.Evaluate(propData.bounceTime) * bounceMagnitude;
				child.localPosition = localPosition;
				break;
			}
			}
		}
	}

	public bool IsShowing()
	{
		return isShowing;
	}

	public void HideProps()
	{
		for (int i = 0; i < props.Length; i++)
		{
			Util.SetActive(props[i].prop.gameObject, active: false);
		}
		isShowing = false;
	}

	public void ShowProps()
	{
		for (int i = 0; i < props.Length; i++)
		{
			Util.SetActive(props[i].prop.gameObject, active: true);
		}
		isShowing = true;
	}

	public void SetPropType(int type)
	{
		for (int i = 0; i < props.Length; i++)
		{
			PropData propData = props[i];
			switch (type)
			{
			case 1:
				propData.mFilter.mesh = legionMesh;
				propData.mRenderer.sharedMaterial = World.inst.romeUnimaterial;
				break;
			case 2:
				propData.mFilter.mesh = militiaMesh;
				propData.mRenderer.sharedMaterial = World.inst.romeUnimaterial;
				break;
			case 0:
			{
				propData.mFilter.mesh = (SRand.CoinFlip() ? villagerMaleMesh : villagerFemaleMesh);
				Material material = UnityEngine.Object.Instantiate(personMaterial);
				material.SetVector("_HeadColor", VillagerSystem.inst.headColors[SRand.Range(0, VillagerSystem.inst.headColors.Length)]);
				material.SetVector("_BodyColor", VillagerSystem.inst.bodyColors[SRand.Range(0, VillagerSystem.inst.bodyColors.Length)]);
				material.SetVector("_HairColor", VillagerSystem.inst.hairColors[SRand.Range(0, VillagerSystem.inst.hairColors.Length)]);
				propData.mRenderer.material = material;
				break;
			}
			}
			propData.type = type;
		}
	}
}
