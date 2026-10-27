using System.Text;
using TMPro;

public class GoldInfo : InfoBase
{
	public class WageInfo
	{
		public float soldierWage;

		public float hospitalWage;

		public float libraryWage;

		public float bathhouseWage;

		public float noriaWage;

		public float firefighterWage;

		public float cemeterykeeperWage;

		public float masonWage;

		public float totalWage;

		public float taxIncome;

		public float[] coveragePerLandmass;
	}

	private StringBuilder builder = new StringBuilder(500);

	private static int hospitalHash = "hospital".GetHashCode();

	private static int clinicHash = "clinic".GetHashCode();

	private static int bathhouseHash = "bathhouse".GetHashCode();

	private static int libraryHash = "library".GetHashCode();

	private static int greatlibraryHash = "greatlibrary".GetHashCode();

	private static int noriaHash = "noria".GetHashCode();

	private static int cemeterykeeperHash = "cemeterykeeper".GetHashCode();

	private static int firehouseHash = "firehouse".GetHashCode();

	private static int masonHash = World.masonHash;

	private WageInfo wageInfo = new WageInfo();

	public TextMeshProUGUI Text;

	public static void CalcTaxInfo(int lIdx, ref WageInfo wi)
	{
		LandmassOwner landmassOwner = World.GetLandmassOwner(lIdx);
		wi.soldierWage = 0f;
		wi.hospitalWage = 0f;
		wi.libraryWage = 0f;
		wi.bathhouseWage = 0f;
		wi.noriaWage = 0f;
		wi.firefighterWage = 0f;
		wi.cemeterykeeperWage = 0f;
		wi.masonWage = 0f;
		wi.totalWage = 0f;
		for (int i = 0; i < Player.inst.WagePayers.Count; i++)
		{
			WagePayer wagePayer = Player.inst.WagePayers.data[i];
			if (!(World.GetLandmassOwner(wagePayer.bi.GetCell().landMassIdx) != landmassOwner) && wagePayer.bi.IsOpen() && wagePayer.bi.GetWorkerPercent() > 0f && wagePayer.bi.IsBuilt())
			{
				float num = (float)wagePayer.GetGoldWage(landmassOwner) * wagePayer.PaydaysPerYear();
				if (wagePayer.bi.uniqueNameHash == hospitalHash || wagePayer.bi.uniqueNameHash == clinicHash)
				{
					wi.hospitalWage += num;
				}
				else if (wagePayer.bi.uniqueNameHash == libraryHash || wagePayer.bi.uniqueNameHash == greatlibraryHash)
				{
					wi.libraryWage += num;
				}
				else if (wagePayer.bi.uniqueNameHash == noriaHash)
				{
					wi.noriaWage += num;
				}
				else if (wagePayer.bi.uniqueNameHash == bathhouseHash)
				{
					wi.bathhouseWage += num;
				}
				else if (wagePayer.bi.uniqueNameHash == cemeterykeeperHash)
				{
					wi.cemeterykeeperWage += num;
				}
				else if (wagePayer.bi.uniqueNameHash == firehouseHash)
				{
					wi.firefighterWage += num;
				}
				else if (wagePayer.bi.uniqueNameHash == masonHash)
				{
					wi.masonWage += num;
				}
				else
				{
					wi.soldierWage += num;
				}
			}
		}
		if (landmassOwner != null)
		{
			for (int j = 0; j < ArmySystem.inst.ArmyCount(); j++)
			{
				ArmySystem.Army amry = ArmySystem.inst.GetAmry(j);
				if (amry.teamId == landmassOwner.teamId)
				{
					wi.soldierWage += amry.general.GetComponent<ArmyWages>().YearlyWage(landmassOwner);
				}
			}
			for (int k = 0; k < SiegeCatapultSystem.siegeCatapults.Count; k++)
			{
				SiegeCatapult siegeCatapult = SiegeCatapultSystem.siegeCatapults.data[k];
				if (siegeCatapult.TeamID() == landmassOwner.teamId)
				{
					wi.soldierWage += siegeCatapult.GetComponent<ArmyWages>().YearlyWage(landmassOwner);
				}
			}
		}
		wi.totalWage = wi.soldierWage + wi.hospitalWage + wi.libraryWage + wi.bathhouseWage + wi.noriaWage + wi.firefighterWage + wi.cemeterykeeperWage + wi.masonWage;
		if (wi.coveragePerLandmass == null || wi.coveragePerLandmass.Length != World.inst.NumLandMasses)
		{
			wi.coveragePerLandmass = new float[World.inst.NumLandMasses];
		}
		for (int l = 0; l < wi.coveragePerLandmass.Length; l++)
		{
			if (!(World.GetLandmassOwner(l) != landmassOwner))
			{
				wi.coveragePerLandmass[l] = Player.inst.GetTaxCollectorsEffectiveness(l);
			}
		}
		wi.taxIncome = 0f;
		for (int m = 0; m < Player.inst.Residentials.Count; m++)
		{
			Home home = Player.inst.Residentials.data[m];
			if (!(World.GetLandmassOwner(home.LandMass()) != landmassOwner))
			{
				wi.taxIncome += home.GetEstimatedTaxYield();
			}
		}
	}

	private void Update()
	{
	}
}
