using Assets.Code;
using Code;
using UnityEngine;

public class BuildDockCutscene : MonoBehaviour
{
	private enum Status
	{
		Init,
		IntroWait,
		ShipArriving,
		SpawnResources,
		ZoomOutWait
	}

	private Status status;

	private Timer introWaitTimer = new Timer(0.25f);

	private Vector3 targetPos = Vector3.zero;

	private Timer waitTime = new Timer(3.5f);

	private ResourceAmount dockCost;

	private Vector3 dockPos;

	private Vector3 landPos;

	private ArrayExt<Vector3> camViewPoints = new ArrayExt<Vector3>(1);

	private float oldDesiredTheta;

	private float oldDesiredPhi;

	private float oldDesiredDist;

	public GameObject ship;

	private void Start()
	{
	}

	private void Update()
	{
		switch (status)
		{
		case Status.Init:
			TimeManager.inst.SetPlay1(skipSfx: true);
			GameUI.inst.AbortCursorObjPlacement();
			GameUI.inst.CurrPlacementMode.CancelWaitToPlace();
			status = Status.IntroWait;
			break;
		case Status.IntroWait:
		{
			if (!introWaitTimer.Update(Time.unscaledDeltaTime))
			{
				break;
			}
			status = Status.ShipArriving;
			Cinematics.inst.ShowBars(show: true);
			oldDesiredTheta = Cam.inst.desiredTheta;
			oldDesiredPhi = Cam.inst.desiredPhi;
			oldDesiredDist = Cam.inst.desiredDist;
			Cam.inst.desiredPhi = 30f;
			Cam.inst.desiredDist = 10f;
			ship.SetActive(value: true);
			int num = Mathff.Clamp((int)dockPos.x - 5, 0, World.inst.GridWidth - 1);
			int num2 = Mathff.Clamp((int)dockPos.x + 5, 0, World.inst.GridWidth - 1);
			int num3 = Mathff.Clamp((int)dockPos.z - 5, 0, World.inst.GridWidth - 1);
			int num4 = Mathff.Clamp((int)dockPos.z + 5, 0, World.inst.GridWidth - 1);
			float num5 = float.MinValue;
			Vector3 zero = Vector3.zero;
			for (int i = num; i < num2; i++)
			{
				for (int j = num3; j < num4; j++)
				{
					float num6 = Mathf.Max(Water.inst.distanceSDFTexture.GetPixel(i * 5, j * 5).r, 0f);
					if (num6 > num5)
					{
						num5 = num6;
						zero.x = i;
						zero.z = j;
					}
				}
			}
			Vector3 input = zero - dockPos;
			input.y = 0f;
			input.NonAllocateNormalize();
			Vector3 position = dockPos + input * 7f;
			position.y = TerrainGen.SeaLevel;
			targetPos = dockPos + input;
			ship.transform.position = position;
			Cam.inst.SetDesiredTrackingPos(targetPos);
			targetPos.y = TerrainGen.SeaLevel;
			break;
		}
		case Status.ShipArriving:
		{
			camViewPoints.Clear();
			camViewPoints.Add(ship.transform.position);
			Cam.inst.BringIntoView(dockPos, camViewPoints);
			if (!Mathff.MoveTowards(ship.transform.position, targetPos, Time.deltaTime * 3f, out var _, out var newPos))
			{
				ship.transform.position = newPos;
				ship.transform.rotation = Quaternion.LookRotation(targetPos - newPos);
			}
			else
			{
				status = Status.SpawnResources;
			}
			break;
		}
		case Status.SpawnResources:
		{
			ResourceAmount resourceAmount = new ResourceAmount(dockCost);
			resourceAmount.Add(0, 45);
			for (int k = 0; k < resourceAmount.resources.Count; k++)
			{
				FreeResourceManager.inst.AddOrMakeAutoStackFor(resourceAmount.resources[k].resourceID, resourceAmount.resources[k].Amount, landPos);
			}
			int num7 = 15;
			for (int l = 0; l < num7; l++)
			{
				Villager villager = Villager.CreateVillager();
				Player.inst.Workers.Add(villager);
				Player.inst.Homeless.Add(villager);
				villager.TeleportTo(landPos);
			}
			status = Status.ZoomOutWait;
			break;
		}
		case Status.ZoomOutWait:
			Cam.inst.desiredDist += Time.deltaTime * 1.5f;
			if (waitTime.Update(Time.deltaTime))
			{
				ship.gameObject.SetActive(value: false);
				EffectsMan.inst.BuildPuff.CreateAndPlay(ship.transform.position);
				Cam.inst.desiredTheta = oldDesiredTheta;
				Cam.inst.desiredPhi = oldDesiredPhi;
				Cam.inst.desiredDist = 30f;
				Cinematics.inst.ShowBars(show: false);
				Object.Destroy(gameObject);
			}
			break;
		}
	}

	public void Init(Building dock)
	{
		dockCost = dock.GetBaseCost();
		dockPos = dock.transform.GetChild(0).position;
		dockPos.y = TerrainGen.inst.GetInterpolatedHeight(dockPos);
		landPos = dockPos;
		ship.SetActive(value: false);
	}
}
