using Sirenix.OdinInspector;
using UnityEngine;

public class AutoSave : MonoBehaviour
{
	public const int SAVETYPE_OFF = 0;

	public const int SAVETYPE_SEASON = 1;

	public const int SAVETYPE_ONE_YEAR = 2;

	public const int SAVETYPE_FIVE_YEARS = 3;

	public const int SAVETYPE_TEN_YEARS = 4;

	public const int SAVETYPE_HALF_YEAR = 6;

	public static ValueDropdownList<int> ValueDropdown = new ValueDropdownList<int>
	{
		{ "OFF", 0 },
		{ "Season", 1 },
		{ "One Year", 2 },
		{ "Five Years", 3 },
		{ "Ten Years", 4 },
		{ "Half Year", 6 }
	};

	public int type = 6;

	public static AutoSave inst;

	public int YearCount;

	private bool doAutoSave;

	public void Awake()
	{
		inst = this;
	}

	private void LateUpdate()
	{
		if (doAutoSave)
		{
			doAutoSave = false;
			RunAutoSave();
		}
	}

	public void SetAutoSaveInterval(int saveType)
	{
		YearCount = 0;
		type = saveType;
	}

	public void OnSeasonChange(object sender, SeasonEventData seasonChangeArgs)
	{
		bool markNewYear = seasonChangeArgs.SeasonDefinition.markNewYear;
		if (markNewYear)
		{
			YearCount++;
		}
		switch (type)
		{
		case 1:
			doAutoSave = true;
			break;
		case 2:
			if (markNewYear)
			{
				doAutoSave = true;
			}
			break;
		case 3:
			if (YearCount == 5)
			{
				doAutoSave = true;
			}
			break;
		case 4:
			if (YearCount == 10)
			{
				doAutoSave = true;
			}
			break;
		case 6:
			if (seasonChangeArgs.SeasonDefinition.name == "Winter" || seasonChangeArgs.SeasonDefinition.name == "Summer")
			{
				doAutoSave = true;
			}
			break;
		case 0:
		case 5:
			break;
		}
	}

	public void RunAutoSave()
	{
		if (GameState.inst.IsPlayMode())
		{
			LoadSave.AutoSave(World.inst.guid);
			YearCount = 0;
		}
	}
}
