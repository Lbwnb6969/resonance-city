using System;
using Assets.Code;
using UnityEngine;

public class Envoy : MonoBehaviour
{
	public InWorldExclamation issuePrefab;

	[NonSerialized]
	public InWorldExclamation issueButton;

	[NonSerialized]
	public ResourceAmount giftAmount;

	[NonSerialized]
	public General general;

	[NonSerialized]
	public bool rightClickNeedsConsumed;

	public GameObject gift;

	public GameObject gift_icon;

	private bool hasUpdatedGiftMaterial;

	private int lastLandmassIdx = -1;

	public int TeamID()
	{
		return general.army.teamId;
	}

	private void Start()
	{
		issueButton = UnityEngine.Object.Instantiate(issuePrefab);
		issueButton.transform.SetParent(transform);
		issueButton.transform.localPosition = new Vector3(0f, 2.25f, 0f);
		issueButton.gameObject.SetActive(value: false);
		issueButton.onClick = () =>
		{
			TryConsumeIssue();
		};
		general = GetComponent<General>();
	}

	public void TryConsumeIssue()
	{
		if (issueButton.gameObject.activeSelf && !GameUI.inst.IsDragSelecting())
		{
			Building building = general.army.moveTarget as Building;
			if ((bool)building)
			{
				int num = building.LandMass();
				LandmassOwner landmassOwner = World.GetLandmassOwner(num);
				int teamId = general.army.TeamID();
				AIKingdom kingdomFromTeamId = AIBrainsContainer.inst.GetKingdomFromTeamId(teamId);
				GameUI.inst.diplomacyUI.Show(this, landmassOwner, num, kingdomFromTeamId);
				GameUI.inst.diplomacyUI.StartEnvoyConvo(kingdomFromTeamId.manageDiplomacyIntention.objective);
				issueButton.gameObject.SetActive(value: false);
				GameUI.inst.diplomacyNotificationUI.CloseBanner(TeamID());
				kingdomFromTeamId.hasPlayerVisitedKeep = true;
				kingdomFromTeamId.unitControl.GetUnitDataFor(general.army).objective.Complete();
			}
		}
	}

	public void OnDestroy()
	{
		UnityEngine.Object.Destroy(issueButton.gameObject);
	}

	private void Update()
	{
		float deltaTime = Time.deltaTime;
		if (!ArmySystem.inst.IsAlive(general.army))
		{
			return;
		}
		int landMassIdx = World.inst.GetCellDataClamped(transform.position).landMassIdx;
		if ((landMassIdx == -1 && lastLandmassIdx != -1) || (landMassIdx != -1 && lastLandmassIdx == -1))
		{
			if (landMassIdx != -1)
			{
				Player.inst.RefreshVisibilityFor(landMassIdx, force: false);
			}
			else
			{
				Player.inst.RefreshVisibilityFor(lastLandmassIdx, force: false);
			}
		}
		lastLandmassIdx = landMassIdx;
		if (general.army.teamId == 0 && general.army.moveStatus == ArmySystem.MoveStatus.Complete && rightClickNeedsConsumed)
		{
			if (GeometryUtility.TestPlanesAABB(GeometryUtility.CalculateFrustumPlanes(Cam.inst.cam), GetComponentInChildren<Renderer>().bounds))
			{
				IMoveTarget moveTarget = general.army.moveTarget;
				if (moveTarget is Building)
				{
					Building building = moveTarget as Building;
					if (building.TeamID() != general.army.TeamID() && (building.uniqueNameHash == World.keepHash || building.uniqueNameHash == World.hallofdiplomacyHash))
					{
						int num = building.LandMass();
						LandmassOwner landmassOwner = World.GetLandmassOwner(num);
						AIKingdom kingdomByLandmass = AIKingdom.GetKingdomByLandmass(num);
						GameUI.inst.diplomacyUI.Show(this, landmassOwner, num, kingdomByLandmass);
						Cam.inst.SetDesiredTrackingPos(building.Center());
					}
				}
			}
			rightClickNeedsConsumed = false;
		}
		if (general.army.teamId != 0)
		{
			AIUnitControlSystem.UnitData unitDataFor = AIBrainsContainer.inst.GetKingdomFromTeamId(general.army.teamId).unitControl.GetUnitDataFor(general.army);
			if (unitDataFor.objective != null && unitDataFor.objective.type == AIUnitControlSystem.ObjectiveType.WaitForComplete && !unitDataFor.objective.IsComplete() && unitDataFor.objective.target == Player.inst.keep.GetComponent<Building>())
			{
				GameUI.inst.diplomacyNotificationUI.NotifyArrived(this);
				issueButton.gameObject.SetActive(value: true);
			}
		}
		TryGrabbingGift();
		gift_icon.transform.Rotate(0f, deltaTime * 60f, 0f);
	}

	private void TryGrabbingGift()
	{
		if (giftAmount.IsNone())
		{
			gift.SetActive(value: false);
			gift_icon.SetActive(value: false);
			LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(general.army.teamId);
			gift_icon.GetComponent<MeshRenderer>().material = landmassOwnerByTeamId.UniMaterialFogClip;
			hasUpdatedGiftMaterial = true;
			if (!(World.GetLandmassOwner(lastLandmassIdx) == landmassOwnerByTeamId))
			{
				return;
			}
			bool flag = false;
			Vector3 position = transform.position;
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(lastLandmassIdx, World.hallofdiplomacyHash);
			for (int i = 0; i < buildingListForLandMass.Count; i++)
			{
				Building building = buildingListForLandMass.data[i];
				HallOfDiplomacy component = building.GetComponent<HallOfDiplomacy>();
				if (!component.HasGift())
				{
					continue;
				}
				if (!flag)
				{
					if (general.army.teamId == 0)
					{
						flag = true;
					}
					else
					{
						AIUnitControlSystem.UnitData unitDataFor = AIBrainsContainer.inst.GetKingdomFromTeamId(general.army.teamId).unitControl.GetUnitDataFor(general.army);
						if (unitDataFor.objective != null && unitDataFor.objective.type == AIUnitControlSystem.ObjectiveType.PickUpGift && unitDataFor.objective.GetTarget() == building)
						{
							flag = true;
						}
					}
				}
				if (flag && Mathff.DistSqrdXZ(position, building.Center()) < 12.25f)
				{
					giftAmount = component.TakeGift();
					EffectsMan.inst.HealthEffect.CreateAndPlay(transform.position);
				}
			}
		}
		else
		{
			gift.SetActive(value: true);
			gift_icon.SetActive(value: true);
			if (!hasUpdatedGiftMaterial)
			{
				LandmassOwner landmassOwnerByTeamId2 = World.GetLandmassOwnerByTeamId(general.army.teamId);
				gift_icon.GetComponent<MeshRenderer>().material = landmassOwnerByTeamId2.UniMaterialFogClip;
				hasUpdatedGiftMaterial = true;
			}
		}
	}

	public void TryDropGift()
	{
		if (!giftAmount.IsNone())
		{
			World.DropResources(transform.position, giftAmount);
			giftAmount = new ResourceAmount();
		}
	}

	internal void OnSelected()
	{
		TryConsumeIssue();
	}
}
