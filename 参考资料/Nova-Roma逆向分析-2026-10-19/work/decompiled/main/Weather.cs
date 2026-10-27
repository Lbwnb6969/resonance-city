using System;
using Assets.Code;
using FMODUnity;
using UnityEngine;

public class Weather : MonoBehaviour
{
	[Serializable]
	public class WeatherSettings
	{
		public float windSpeed;

		public float rainAmount;

		public float lightingIntervalBase;

		public float lightingVariation;
	}

	[Serializable]
	public class WeatherSaveData : SaveClass<Weather, WeatherSaveData>
	{
		public override WeatherSaveData Pack(Weather w)
		{
			return this;
		}

		public override Weather Unpack(Weather w)
		{
			return w;
		}
	}

	[NonSerialized]
	public static Weather inst;

	private Texture2D snowMask;

	public Light Light;

	public AudioSource thunder;

	public AudioClip[] SFX_thunder;

	private Timer lightningTimer;

	public float windAngle;

	public float windIntensity;

	public float desiredWindIntensity;

	public static int MinPopulationLightning = 20;

	public float GetSnowFade()
	{
		return 0f;
	}

	public Texture2D GetSnowMask()
	{
		return snowMask;
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		lightningTimer = new Timer(7.5f);
		lightningTimer.Enabled = false;
	}

	private void Update()
	{
	}

	public void LightningStrike(Vector3 strikePos, bool doFire = true, bool smallstrike = false)
	{
		if (smallstrike)
		{
			EffectsMan.inst.LightingStrikeFocusEffect.CreateAndPlay(strikePos);
		}
		else
		{
			EffectsMan.inst.LightingStrikeEffect.CreateAndPlay(strikePos);
		}
		RuntimeManager.PlayOneShot("event:/OldSFX/Thunder", strikePos);
		strikePos.y = 0f;
		float num = 1f;
		ShipBase shipBase = ShipSystem.inst.GetClosestShipToAttack(strikePos, -2, 0f) as ShipBase;
		if (shipBase != null && Vector3.Distance(shipBase.GetPosition(), strikePos) <= num)
		{
			if (shipBase.teamID == 0)
			{
				if (shipBase.type == ShipBase.ShipType.TroopTransport)
				{
					shipBase.life -= shipBase.maxLife / 2f;
				}
			}
			else if (shipBase.teamID == 1)
			{
				shipBase.life = 0f;
			}
		}
		if (doFire)
		{
			Vector3 worldPos = strikePos;
			worldPos.y = 0f;
			Cell cellData = World.inst.GetCellData(worldPos);
			Cell cell = World.inst.FindMatchingSurroundingCell(cellData, testOrigin: true, 4, (Cell c) => c.BottomStructure != null);
			if (Player.inst.TotalWorkers() > MinPopulationLightning && cellData != null && cell != null && (World.inst.treeSystem.ItemAmount(cellData) > 0 || cellData.BottomStructure != null))
			{
				FireManager.inst.StartFireAt(cellData);
			}
		}
	}
}
