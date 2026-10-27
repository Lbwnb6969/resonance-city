using System;
using TMPro;
using UnityEngine;
using UnityEngine.Serialization;
using UnityEngine.UI;

public class BuildButton : MonoBehaviour
{
	[SerializeField]
	private Button btn;

	[SerializeField]
	private StaticTooltipHook sTooltip;

	[FormerlySerializedAs("unlockedTxt")]
	[SerializeField]
	private TextMeshProUGUI unlockedTMP;

	[SerializeField]
	private GameObject unlockedContainer;

	[SerializeField]
	private GameObject lockedOverlay;

	private int unlockedCount;

	private bool isUnlocked;

	public string category;

	public string categoryReq;

	[NonSerialized]
	public int categoryReqHash;

	[NonSerialized]
	public BuildUI.BuildGroup group;

	public bool IsUnlocked()
	{
		return isUnlocked;
	}

	public void Init(BuildUI.BuildGroup group)
	{
		this.group = group;
	}

	private void Start()
	{
		categoryReqHash = categoryReq.GetHashCode();
		btn.onClick.AddListener(() =>
		{
			unlockedContainer.SetActive(value: false);
			unlockedCount = 0;
			GameUI.inst.OnDownBuildTabButton();
		});
	}

	private void OnDestroy()
	{
	}

	public void Reset()
	{
		unlockedCount = 0;
		unlockedContainer.SetActive(value: false);
		unlockedTMP.text = unlockedCount.ToString();
		isUnlocked = false;
	}

	private void OnBuildingUnlocked(BuildTab tab, BuildingCostUpdater item)
	{
		if (tab.title == category)
		{
			unlockedContainer.SetActive(unlockedCount > 0);
			unlockedTMP.text = unlockedCount.ToString();
		}
	}

	private void SetUnlocked(bool unlock)
	{
		sTooltip.enabled = unlock;
		isUnlocked = unlock;
	}

	private void Update()
	{
		int focusedLandMass = Player.inst.FocusedLandMass;
		if (!isUnlocked && focusedLandMass != -1)
		{
			if (string.IsNullOrEmpty(categoryReq))
			{
				SetUnlocked(unlock: true);
			}
			else
			{
				for (int i = 0; i < World.inst.NumLandMasses; i++)
				{
					if (Player.inst.PlayerLandmassOwner.OwnsLandMass(i) && Player.inst.DoesBuildingExistInCategoryForLandmass(focusedLandMass, categoryReqHash))
					{
						SetUnlocked(unlock: true);
						break;
					}
				}
			}
		}
		lockedOverlay.SetActive(focusedLandMass == -1 || !isUnlocked);
	}
}
