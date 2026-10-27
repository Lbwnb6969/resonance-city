using System;
using System.Collections.Generic;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using UnityEngine;

public class SettlerShip : ShipBase, ISelectable
{
	[Serializable]
	public new class ShipData
	{
		public int status;

		public float unloadTimer;

		public float dockTimer;

		public int settlerProspectAmount;

		public int settlerAmount;

		public int settled;

		public int landmass;

		public int targetX;

		public int targetZ;
	}

	public static int totalSettled;

	public static int totalSettledShips;

	private int settlerProspectAmount;

	private int settlerAmount;

	private int settled;

	private int landmass = -1;

	public int status;

	public const int MOVE_TO_TARGET = 0;

	public const int UNLOAD_SETTLERS = 1;

	public const int MOVE_TO_EDGE_OF_MAP = 2;

	private Timer unloadTimer = new Timer(1f);

	private Timer dockTimer = new Timer(5f);

	private Cell targetCell;

	private ICamTrackable trackable;

	public float propMoveSpeed = 0.5f;

	public float propRotateSpeed = 0.25f;

	public AnimationCurve bounceCurve;

	public float bounceSpeed = 1f;

	public float bounceMagnitude = 1f;

	public VillagerPropsManager propManager;

	public List<VillagerPropsManager.PropData> settlerPropData = new List<VillagerPropsManager.PropData>();

	public int[] activeSettlerProps = new int[2];

	public bool hasActiveSettlerProps;

	private EventInstance eAmb;

	public int GetSettlerProspectCount()
	{
		return settlerProspectAmount;
	}

	public int GetSettlerCount()
	{
		return settlerAmount;
	}

	public int GetSettledCount()
	{
		return settled;
	}

	public int GetTargetLandmass()
	{
		return landmass;
	}

	public ShipData GetShipData()
	{
		return new ShipData
		{
			status = status,
			unloadTimer = unloadTimer.CurrTime,
			dockTimer = dockTimer.CurrTime,
			settlerProspectAmount = settlerProspectAmount,
			settlerAmount = settlerAmount,
			settled = settled,
			landmass = landmass,
			targetX = ((targetCell == null) ? 1 : targetCell.x),
			targetZ = ((targetCell == null) ? 1 : targetCell.z)
		};
	}

	public void SetFromShipData(ShipData data)
	{
		status = data.status;
		unloadTimer.CurrTime = data.unloadTimer;
		dockTimer.CurrTime = data.dockTimer;
		settlerProspectAmount = data.settlerProspectAmount;
		settlerAmount = data.settlerAmount;
		settled = data.settled;
		landmass = data.landmass;
		targetCell = World.inst.GetCellData(data.targetX, data.targetZ);
		if ((status == 0 || status == 2) && targetCell != null)
		{
			MoveTo(targetCell);
		}
	}

	public void Setup(int landmass, int settlerProspectAmount, Vector3 targetPos)
	{
		this.landmass = landmass;
		this.settlerProspectAmount = settlerProspectAmount;
		settlerAmount = 0;
		teamID = -2;
		targetCell = World.inst.GetCellData(targetPos);
		if (targetCell != null || targetCell.landMassIdx != this.landmass)
		{
			targetCell = World.inst.FindMatchingSurroundingCell(targetPos, testOrigin: false, 8, (Cell cell) => cell.landMassIdx == this.landmass);
		}
		if (targetCell == null)
		{
			ShipSystem.inst.Remove(this);
			UnityEngine.Object.Destroy(gameObject);
		}
		else
		{
			MoveTo(targetCell);
			status = 0;
		}
	}

	private void Start()
	{
		ShipSystem.inst.onShipArrived += OnShipArrived;
		eAmb = RuntimeManager.CreateInstance("event:/SFX ASITP/Ambiences/ambSpot_ship_chatter_lp");
		eAmb.start();
		propManager.SetPropType(0);
		propManager.ShowProps();
		for (int i = 0; i < settlerPropData.Count; i++)
		{
			VillagerPropsManager.PropData propData = settlerPropData[i];
			if (propData.type == 0)
			{
				MeshRenderer component = propData.prop.GetChild(0).GetComponent<MeshRenderer>();
				propData.headColorIdx = SRand.Range(0, VillagerSystem.inst.headColors.Length);
				component.material.SetVector("_HeadColor", VillagerSystem.inst.headColors[propData.headColorIdx]);
				propData.bodyColorIdx = SRand.Range(0, VillagerSystem.inst.bodyColors.Length);
				component.material.SetVector("_BodyColor", VillagerSystem.inst.bodyColors[propData.bodyColorIdx]);
				propData.hairColorIdx = SRand.Range(0, VillagerSystem.inst.hairColors.Length);
				component.material.SetVector("_HairColor", VillagerSystem.inst.hairColors[propData.hairColorIdx]);
			}
		}
		for (int j = 0; j < activeSettlerProps.Length; j++)
		{
			activeSettlerProps[j] = -1;
		}
	}

	private void OnDestroy()
	{
		ShipSystem.inst.onShipArrived -= OnShipArrived;
		if (eAmb.isValid())
		{
			eAmb.stop(STOP_MODE.IMMEDIATE);
			eAmb.release();
		}
	}

	private void Update()
	{
		float deltaTime = Time.deltaTime;
		if (status == 1)
		{
			if (settled >= settlerAmount)
			{
				if (dockTimer.Update(deltaTime))
				{
					if (Player.inst.PlayerLandmassOwner.OwnsLandMass(landmass))
					{
						totalSettled += settlerAmount;
						totalSettledShips++;
					}
					Vector3 worldPos = new Vector3(1f, TerrainGen.waterHeightTestThresold, 1f);
					World.inst.GetRandomPositionOnEdge(ref worldPos);
					targetCell = World.inst.GetCellData(worldPos);
					MoveTo(targetCell);
					status = 2;
					MilestoneManager.inst.CheckPopulationMilestones(landmass);
				}
			}
			else if (!hasActiveSettlerProps)
			{
				hasActiveSettlerProps = true;
				int num = 1;
				if (settlerAmount - settled >= 2 && SRand.Range(0, 100) < 30)
				{
					num = 2;
				}
				for (int i = 0; i < activeSettlerProps.Length; i++)
				{
					activeSettlerProps[i] = ((i < num) ? i : (-1));
					VillagerPropsManager.PropData propData = settlerPropData[i];
					propData.prop.localPosition = propData.Waypoints[0].point.localPosition;
					propData.prop.localRotation = propData.Waypoints[0].point.localRotation;
					propData.WaypointIdx = 1;
					propData.prop.gameObject.SetActive(value: true);
				}
			}
			else
			{
				hasActiveSettlerProps = false;
				for (int j = 0; j < activeSettlerProps.Length; j++)
				{
					int num2 = activeSettlerProps[j];
					if (num2 == -1)
					{
						continue;
					}
					VillagerPropsManager.PropData propData2 = settlerPropData[num2];
					Vector3 newPos = propData2.prop.localPosition;
					Vector3 forward = propData2.Waypoints[propData2.WaypointIdx].point.localPosition - newPos;
					forward.y = 0f;
					bool flag = false;
					if (Mathff.MoveTowards(propData2.prop.localPosition, propData2.Waypoints[propData2.WaypointIdx].point.localPosition, deltaTime * propMoveSpeed, out var actualAmt, out newPos))
					{
						propData2.WaypointIdx++;
						if (propData2.WaypointIdx >= propData2.Waypoints.Length)
						{
							activeSettlerProps[j] = -1;
							propData2.prop.gameObject.SetActive(value: false);
							Villager villager = Villager.CreateVillager();
							Player.inst.Workers.Add(villager);
							Player.inst.Homeless.Add(villager);
							villager.TeleportTo(targetCell.Center3D + SRand.insideUnitSquareXZ * 0.25f);
							trackable = villager;
							settled++;
							villager.headColor = VillagerSystem.inst.headColors[propData2.headColorIdx];
							villager.bodyColor = VillagerSystem.inst.bodyColors[propData2.bodyColorIdx];
							villager.hairColor = VillagerSystem.inst.hairColors[propData2.hairColorIdx];
							villager.ApplyColorChanges();
							flag = true;
						}
					}
					if (forward.magnitude > 0.0001f)
					{
						propData2.prop.localRotation = Quaternion.RotateTowards(propData2.prop.localRotation, Quaternion.LookRotation(forward), actualAmt * propRotateSpeed);
					}
					propData2.prop.localPosition = newPos;
					propData2.bounceTime = (propData2.bounceTime + deltaTime * bounceSpeed) % 1f;
					Transform child = propData2.prop.GetChild(0);
					Vector3 localPosition = child.localPosition;
					localPosition.y = bounceCurve.Evaluate(propData2.bounceTime) * bounceMagnitude;
					child.localPosition = localPosition;
					hasActiveSettlerProps |= !flag;
				}
			}
		}
		eAmb.set3DAttributes(transform.position.To3DAttributes());
	}

	private void OnShipArrived(ShipBase sb)
	{
		if (sb != this)
		{
			return;
		}
		switch (status)
		{
		case 0:
		{
			CalculateSettlerAmount();
			Vector3 vector = GetPos();
			targetCell = World.inst.FindMatchingSurroundingCell(vector, testOrigin: true, 6, (Cell cell) => cell.landMassIdx == landmass && cell.Type == TerrainType.None);
			if (targetCell != null)
			{
				if (Player.inst.PlayerLandmassOwner.OwnsLandMass(landmass))
				{
					MiniMapUIPing miniMapUIPing = UnityEngine.Object.Instantiate(MiniMapUI.inst.pingPrefab, MiniMapUI.inst.mapPingMarkerContainer);
					miniMapUIPing.maxflashCount = 2;
					miniMapUIPing.color = Color.green;
					miniMapUIPing.pingSpeed = 1f;
					miniMapUIPing.pingOpacityStrength = 0.75f;
					MiniMapUI.inst.PingAtWorldLocation(miniMapUIPing, vector);
				}
				status = 1;
			}
			else
			{
				Vector3 worldPos = new Vector3(1f, TerrainGen.waterHeightTestThresold, 1f);
				World.inst.GetRandomPositionOnEdge(ref worldPos);
				targetCell = World.inst.GetCellData(worldPos);
				MoveTo(targetCell);
				status = 2;
			}
			break;
		}
		case 2:
			ShipSystem.inst.Remove(this);
			UnityEngine.Object.Destroy(gameObject);
			break;
		}
	}

	private void CalculateSettlerAmount()
	{
		settlerAmount = 0;
		int num = 0;
		int num2 = 0;
		LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
		for (int i = 0; i < playerLandmassOwner.ownedLandMasses.Count; i++)
		{
			num2 += World.inst.GetVillagersForLandMass(playerLandmassOwner.ownedLandMasses.data[i]).Count;
		}
		int num3;
		if (num2 >= 300)
		{
			if (num2 < 1000)
			{
				num3 = ((num2 >= 750) ? (-7) : (-3));
			}
			else
			{
				num3 = ((num2 >= 1500) ? (-13) : (-10));
			}
		}
		else if (num2 < 50)
		{
			num3 = ((num2 >= 25) ? 20 : 30);
		}
		else
		{
			num3 = ((num2 < 75) ? 10 : 0);
		}
		num = num3;
		int num4 = Player.inst.GetLandmassHappiness(landmass).currHappiness + num;
		bool flag = RaiderSystem.inst.IsRaidInProgressAtLandmass(landmass);
		bool flag2 = Player.inst.HasHappinessMod("vikingattack", landmass);
		NotificationUI.NotificationMessage message = default;
		if (flag)
		{
			message.single = string.Format("{0} : " + ScriptLocalization.PersonArrivalScaredByInvasion, Player.inst.LandMassNames[landmass]);
		}
		else if (flag2)
		{
			message.single = LocalizationManager.GetTranslation("NotificationUI_invasionDespair");
		}
		else if (num4 < 35)
		{
			int num5 = SRand.Range(3, 5);
			int num6 = UnhappyPeopleLeave(num5, landmass);
			if (num6 > 0)
			{
				message.single = string.Format(ScriptLocalization.LogPlayerPersonAddLow, $"<color=red>{num6}</color>");
			}
			else
			{
				message.single = ScriptLocalization.LogPlayerPersonAddTooUnhappy;
			}
		}
		else if (num4 >= 35 && num4 < 50)
		{
			if (SRand.Range(0, 100) > 40)
			{
				int num7 = SRand.Range(1, 2);
				int num8 = UnhappyPeopleLeave(num7, landmass);
				if (num8 > 0)
				{
					message.single = string.Format(ScriptLocalization.LogPlayerPersonAddLow, $"<color=red>{num8}</color>");
				}
				else
				{
					message.single = ScriptLocalization.LogPlayerPersonAddTooUnhappy;
				}
			}
			else
			{
				message.single = ScriptLocalization.LogPlayerPersonAddTooUnhappy;
			}
		}
		if ((num4 < 50) | flag | flag2)
		{
			if (Player.inst.PlayerLandmassOwner.OwnsLandMass(landmass) && Player.inst.Workers.Count < 75)
			{
				NotificationUI.TryNotify(NotificationUI.HomeGroup, -1, "settlerMessage", message);
			}
			else
			{
				NotificationUI.TryLog(NotificationUI.HomeGroup, "settlerMessage", message.single, NotificationStatus.Neutral);
			}
			return;
		}
		int totalOpenResidentialSlots = Player.inst.GetTotalOpenResidentialSlots(landmass);
		bool flag3 = totalOpenResidentialSlots == 0 || totalOpenResidentialSlots < settlerProspectAmount;
		for (int j = 0; j < settlerProspectAmount; j++)
		{
			if (totalOpenResidentialSlots <= settlerAmount)
			{
				break;
			}
			if (SRand.Range(0, 100) < num4 || (j == 0 && num4 > 65))
			{
				settlerAmount++;
			}
		}
		int num9 = ((Player.inst.Workers.Count > 50) ? 30 : 15);
		int num10 = SRand.Range(0, 100);
		if (num4 >= 75 || num10 > num9)
		{
			if (settlerProspectAmount == 0)
			{
				message.single = ScriptLocalization.LogPlayerPersonAddNoneStayed;
			}
			else if (settlerAmount != settlerProspectAmount)
			{
				if (settlerAmount == 0)
				{
					if (flag3)
					{
						message.single = string.Format(ScriptLocalization.LogPlayerPersonAddVisitedNoneStayed, "<color=#00FFFF>" + settlerProspectAmount + "</color>");
					}
					else
					{
						message.single = ScriptLocalization.LogPlayerPersonAddNoneStayed;
					}
				}
				else
				{
					message.single = string.Format(ScriptLocalization.LogPlayerPersonAddVisitedSomeStayed, "<color=#00FFFF>" + settlerProspectAmount + "</color>", "<color=green>" + settlerAmount + "</color>");
					int num11 = Player.inst.GetBuildingListForLandMass(landmass, "smallinsula".GetHashCode()).Count;
					int num12 = Player.inst.GetBuildingListForLandMass(landmass, "mediuminsula".GetHashCode()).Count;
					int num13 = Player.inst.GetBuildingListForLandMass(landmass, "largeinsula".GetHashCode()).Count;
					int num14 = World.inst.GetVillagersForLandMass(landmass).Count;
					bool flag4 = false;
					if (num14 > 60 && num11 <= 0)
					{
						flag4 = true;
					}
					if (num14 > 120 && num12 <= 0)
					{
						flag4 = true;
					}
					if (num14 > 250 && num13 <= 0)
					{
						flag4 = true;
					}
					if (flag4)
					{
						ref string single = ref message.single;
						single = single + " " + LocalizationManager.GetTranslation("LogPlayerPersonAddNeedHomeVariety");
					}
				}
				if (flag3)
				{
					ref string single2 = ref message.single;
					single2 = single2 + " " + ScriptLocalization.LogPlayerPersonAddNeedMoreHomes;
				}
			}
			else if (num4 >= 75)
			{
				message.single = string.Format(ScriptLocalization.LogPlayerPersonAddLifeIsGood, "<color=green>" + settlerAmount + "</color>");
			}
			else
			{
				message.single = string.Format(ScriptLocalization.LogPlayerPersonAddFoundHomes, "<color=green>" + settlerProspectAmount + "</color>");
			}
		}
		else
		{
			message.single = ScriptLocalization.LogPlayerPersonAddNoneStayed;
			settlerAmount = 0;
		}
		if (Player.inst.PlayerLandmassOwner.OwnsLandMass(landmass) && Player.inst.Workers.Count < 75)
		{
			NotificationUI.TryNotify(NotificationUI.HomeGroup, -1, "settlerMessage", message);
		}
		else
		{
			NotificationUI.TryLog(NotificationUI.HomeGroup, "settlerMessage", message.single, NotificationStatus.Neutral);
		}
	}

	private int UnhappyPeopleLeave(int num, int landMass)
	{
		if (!Creative.inst.IsCreativeOptionOn(3))
		{
			return 0;
		}
		int num2 = 0;
		if (Player.inst.TotalWorkersForLandMass(landMass) > 10)
		{
			for (int i = 0; i < num; i++)
			{
				Villager randomPersonForLandMass = Player.inst.GetRandomPersonForLandMass(landMass);
				if (randomPersonForLandMass != null)
				{
					num2++;
					Player.inst.DestroyPerson(randomPersonForLandMass, leaveBehindBody: false);
				}
			}
		}
		return num2;
	}

	public bool ExclusiveSelect()
	{
		return true;
	}

	public bool ValidToSelect()
	{
		return true;
	}

	public void SetHighlightImmediate(int colorIdx)
	{
		highlighter.SetOutlineImmediate(colorIdx);
	}

	public void OnSelected()
	{
		GameUI.inst.ClearUIForClick();
		SettlerShipUI.inst.Select(this);
		Cam.inst.Track(this);
		RuntimeManager.PlayOneShot("event:/OldSFX/TransportShipSelect", GetPos());
	}

	public bool InsideSelectionBounds(int minx, int minz, int maxx, int maxz)
	{
		int num = (int)GetPos().x;
		int num2 = (int)GetPos().z;
		if (minx <= num && num <= maxx && minz <= num2)
		{
			return num2 <= maxz;
		}
		return false;
	}

	public int TeamID()
	{
		return -2;
	}
}
