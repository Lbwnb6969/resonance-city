using I2.Loc;
using TMPro;
using UnityEngine;

public class ForeignRegionNameUI : MonoBehaviour
{
	public TextMeshProUGUI regionName;

	public TextMeshProUGUI desc;

	public GameObject rulerPortrait;

	public GameObject portraitLight;

	public static ForeignRegionNameUI inst;

	private GameObject[] heads;

	private float neutralAnimTime;

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		heads = new GameObject[World.inst.kingdomHeadInfo.Length];
		for (int i = 0; i < heads.Length; i++)
		{
			heads[i] = Object.Instantiate(World.inst.kingdomHeadInfo[i].headPrefabs);
			heads[i].transform.SetParent(rulerPortrait.transform);
			heads[i].transform.localScale = new Vector3(40f, 40f, 40f);
			switch (i)
			{
			case 0:
				heads[i].transform.localPosition = new Vector3(0f, -23f, 315f);
				break;
			case 1:
				heads[i].transform.localPosition = new Vector3(0f, -43f, 315f);
				break;
			default:
				heads[i].transform.localPosition = new Vector3(0f, 1f, 315f);
				break;
			}
			heads[i].transform.localRotation = Quaternion.Euler(0f, 155f, 0f);
			heads[i].SetActive(value: false);
		}
	}

	public void PlayAnimForWreckedBuilding()
	{
		if (neutralAnimTime != -1f || !gameObject.activeSelf)
		{
			return;
		}
		string text = "";
		int num = SRand.Range(0, 3);
		if (num == 0)
		{
			text = "angry";
		}
		if (num == 1)
		{
			text = "upset";
		}
		if (num == 2)
		{
			text = "skeptical";
		}
		if (!(text != ""))
		{
			return;
		}
		neutralAnimTime = 0f;
		for (int i = 0; i < heads.Length; i++)
		{
			if (heads[i].activeSelf)
			{
				heads[i].GetComponent<Animator>().CrossFadeInFixedTime(text, 0.3f);
			}
		}
	}

	private void Update()
	{
		if (LoadSave.Loading)
		{
			return;
		}
		rulerPortrait.SetActive(!GameUI.inst.diplomacyUI.gameObject.activeSelf);
		bool flag = FogOfWar.inst.HasAnyVisibilityOnLandmass(Player.inst.FocusedLandMass);
		AIKingdom kingdomByLandmass = AIKingdom.GetKingdomByLandmass(Player.inst.FocusedLandMass);
		int num = -1;
		portraitLight.SetActive(value: false);
		if (flag || (kingdomByLandmass != null && kingdomByLandmass.hasPlayerVisitedKeep))
		{
			LandmassOwner landmassOwner = World.GetLandmassOwner(Player.inst.FocusedLandMass);
			if (landmassOwner == null)
			{
				regionName.text = ScriptLocalization.UnoccupiedLand;
				desc.text = LocalizationManager.GetTranslation("islandui_settleinstructions");
			}
			else if (landmassOwner != Player.inst.PlayerLandmassOwner)
			{
				if (kingdomByLandmass != null)
				{
					num = kingdomByLandmass.headIdx;
				}
				if (kingdomByLandmass != null && kingdomByLandmass.hasPlayerVisitedKeep)
				{
					regionName.text = Player.inst.GetFocusedLandMassName();
					desc.text = string.Format(ScriptLocalization.RuledBy, kingdomByLandmass.GetLocalizedName());
					portraitLight.SetActive(value: true);
				}
				else
				{
					regionName.text = "I2.Loc.ScriptLocalization.UnknownKingdom";
					desc.text = "I2.Loc.ScriptLocalization.UnknownKingdomDesc";
				}
			}
		}
		else
		{
			regionName.text = ScriptLocalization.UnknownLand;
			desc.text = LocalizationManager.GetTranslation("islandui_settleinstructions");
		}
		if (neutralAnimTime >= 0f)
		{
			neutralAnimTime += Time.unscaledDeltaTime;
		}
		for (int i = 0; i < heads.Length; i++)
		{
			bool flag2 = false;
			if (i == num && !heads[i].activeSelf)
			{
				DiplomacyUI.SetHeadMaterials(kingdomByLandmass, heads[i]);
				flag2 = true;
			}
			heads[i].SetActive(i == num);
			if (neutralAnimTime > 1f)
			{
				heads[i].GetComponent<Animator>().CrossFadeInFixedTime("neutral_grumpy", 0.7f);
			}
			if (flag2)
			{
				if (World.inst.RelationBetween(0, kingdomByLandmass.LandmassOwner.teamId) == World.Relations.Enemy)
				{
					heads[i].GetComponent<Animator>().CrossFadeInFixedTime("neutral_grumpy", 0.3f);
				}
				else
				{
					heads[i].GetComponent<Animator>().CrossFadeInFixedTime("neutral", 0.3f);
				}
			}
		}
		if (neutralAnimTime > 1f)
		{
			neutralAnimTime = -1f;
		}
	}
}
