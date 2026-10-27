using System;
using System.Collections.Generic;
using Assets.Code;
using UnityEngine;

public static class TerminalCommands
{
	[TerminalCommand("help", "Show available commands or help for a specific command", "General", false)]
	public static void Help(string commandName = "")
	{
		TerminalManager.inst.PrintHelp(commandName);
	}

	[TerminalCommand("clear", "Clear the terminal output", "General", false)]
	public static void Clear()
	{
		TerminalUI.inst.ClearOutput();
	}

	[TerminalCommand("stop", "Stop running terminal commands (optionally specify command ID)", "General", false)]
	public static void StopRunningCommands(int id = -1)
	{
		if (id == -1)
		{
			TerminalManager.inst.StopAllRunningCommands();
			TerminalUI.inst.PrintWarning("All running commands stopped");
		}
		else if (TerminalManager.inst.StopCommandById(id))
		{
			TerminalUI.inst.PrintWarning($"Command {id} stopped");
		}
		else
		{
			TerminalUI.inst.PrintError($"Command {id} not found or already stopped");
		}
	}

	[TerminalCommand("creative", "Set the creative mode ([true]/false)", "General", true)]
	public static void CreativeMode(bool t = true)
	{
		Creative.inst.SetEnabled(t);
		TerminalUI.inst.PrintSuccess("Creative mode is " + (t ? "on" : "off"));
	}

	[TerminalCommand("disable_god_appearance", "Stop gods from appearing ([true]/false)", "General", true)]
	public static void DisableGodAppearance(bool t = true)
	{
		GodManager.inst.disableGodsAppearance = t;
		GodManager.inst.ClearGodAppearance();
		TerminalUI.inst.PrintSuccess("God appearance is " + (t ? "disabled" : "enabled"));
	}

	[TerminalCommand("spawn_god_anger", "Spawn a god anger", "General", true)]
	[TerminalParameterHints("name", new string[] { "jupiter", "venus", "ceres", "vulcan", "neptune", "mars" })]
	public static void SpawnGodAnger(string name = "")
	{
		int godIdx = GodManager.GodNameToIdx(name);
		GodManager.inst.SpawnGodAngerAtCam(godIdx, force: true);
	}

	[TerminalCommand("water_creation", "Enable water creation from water sources ([on]/off)", "General", true)]
	public static void WaterCreation(bool t = true)
	{
		if (t)
		{
			DynamicWater.inst.debug_produceWater = 1f;
		}
		else
		{
			DynamicWater.inst.debug_produceWater = 0f;
		}
		TerminalUI.inst.PrintSuccess("Water spawners are " + (t ? "on" : "off"));
	}

	[TerminalCommand("timeofday", "Set the time of day. [0-24, midnight, dawn, noon, dusk]", "General", true)]
	[TerminalParameterHints("timeInput", new string[] { "midnight", "dawn", "sunrise", "noon", "midday", "dusk", "sunset" })]
	public static void SetTimeOfDay(string timeInput = "")
	{
		if (SeasonManager.inst == null)
		{
			TerminalUI.inst.PrintError("SeasonManager not available");
			return;
		}
		if (DayNightManager.inst == null)
		{
			TerminalUI.inst.PrintError("DayNightManager not available");
			return;
		}
		if (string.IsNullOrEmpty(timeInput))
		{
			float _24HourTime = DayNightManager.inst.GameParameters._24HourTime;
			bool isDay = DayNightManager.inst.GameParameters.isDay;
			string timeOfDayString = GetTimeOfDayString(_24HourTime);
			TerminalUI.inst.PrintLine($"Current time: {_24HourTime:F1} hours ({timeOfDayString})", TerminalUI.inst.commandTextColor);
			TerminalUI.inst.PrintLine("Day/Night: " + (isDay ? "Day" : "Night"));
			TerminalUI.inst.PrintLine($"Year: {SeasonManager.inst.CurrentYear()}");
			TerminalUI.inst.PrintLine("Season: " + SeasonManager.inst.CurrentSeason.name);
			return;
		}
		float num = -1f;
		switch (timeInput.ToLower())
		{
		case "midnight":
			num = 0f;
			break;
		case "dawn":
		case "sunrise":
			num = 6f;
			break;
		case "noon":
		case "midday":
			num = 12f;
			break;
		case "dusk":
		case "sunset":
			num = 18f;
			break;
		default:
		{
			if (float.TryParse(timeInput, out var result))
			{
				num = result;
				break;
			}
			TerminalUI.inst.PrintError("Invalid time. Use 0-24 or: midnight, dawn, noon, dusk");
			return;
		}
		}
		if (num < 0f || num > 24f)
		{
			TerminalUI.inst.PrintError("Hour must be between 0 and 24");
			return;
		}
		if (num >= 24f)
		{
			num = 0f;
		}
		SeasonManager.inst.SetTime(num);
		string timeOfDayString2 = GetTimeOfDayString(num);
		TerminalUI.inst.PrintSuccess($"Time set to {num:F1} hours ({timeOfDayString2})");
	}

	private static string GetTimeOfDayString(float hour)
	{
		if (hour >= 0f && hour < 3f)
		{
			return "Late Night";
		}
		if (hour >= 3f && hour < 6f)
		{
			return "Early Morning";
		}
		if (hour >= 6f && hour < 9f)
		{
			return "Dawn";
		}
		if (hour >= 9f && hour < 12f)
		{
			return "Morning";
		}
		if (hour >= 12f && hour < 15f)
		{
			return "Noon";
		}
		if (hour >= 15f && hour < 18f)
		{
			return "Afternoon";
		}
		if (hour >= 18f && hour < 21f)
		{
			return "Dusk";
		}
		if (hour >= 21f && hour <= 24f)
		{
			return "Night";
		}
		return "Unknown";
	}

	[TerminalCommand("tile", "Get information about the selected tile", "General", false)]
	public static IEnumerable<object> GetTileInfo()
	{
		while (true)
		{
			Ray ray = PointingSystem.GetRay();
			string hover = "Not hovering over cell.";
			if (TerrainGen.inst.Raycast(ray, out var hitInfo))
			{
				Cell cellData = World.inst.GetCellData(hitInfo.point);
				if (cellData != null)
				{
					hover = $"Hover: ({cellData.x}, {cellData.z})";
				}
			}
			Cell cellSelected = GameUI.inst.GetCellSelected();
			string text = "No cell selected.";
			if (cellSelected != null)
			{
				text = $"Selected: ({cellSelected.x}, {cellSelected.z})";
			}
			yield return new SetLine(0, text);
			yield return new SetLine(1, hover);
		}
	}

	[TerminalCommand("timescale", "Get or set game time scale (0.0 to 20.0)", "Game", true)]
	public static void TimeScale(float scale = -1f)
	{
		if (scale < 0f)
		{
			TerminalUI.inst.PrintLine($"Current time scale: {Time.timeScale:F2}x", TerminalUI.inst.commandTextColor);
			if (Time.timeScale == 0f)
			{
				TerminalUI.inst.PrintLine("Game is paused");
			}
			else if (Time.timeScale < 0.85f)
			{
				TerminalUI.inst.PrintLine("Game is running slower than normal");
			}
			else if (Time.timeScale > 0.85f)
			{
				TerminalUI.inst.PrintLine("Game is running faster than normal");
			}
			else if (Mathf.Approximately(Time.timeScale, 0.85f))
			{
				TerminalUI.inst.PrintLine("Game is running at normal speed");
			}
		}
		else if (scale < 0f || scale > 20f)
		{
			TerminalUI.inst.PrintError("Time scale must be between 0.0 and 20.0");
		}
		else
		{
			Time.timeScale = scale;
			TerminalUI.inst.PrintSuccess($"Time scale set to {scale:F2}x");
		}
	}

	[TerminalCommand("fps", "Show current FPS", "General", false)]
	public static IEnumerable<object> ShowFPS()
	{
		while (true)
		{
			float num = 1f / Time.unscaledDeltaTime;
			yield return new SetLine(0, $"FPS: {num:F1}");
		}
	}

	[TerminalCommand("water", "Show live total water level", "General", false)]
	public static IEnumerable<object> ShowWater()
	{
		while (!(DynamicWater.inst == null))
		{
			yield return new SetLine(0, $"Total Water: {DynamicWater.inst.totalWater:F2}  Change: {DynamicWater.inst.totalWaterChange:F4}");
		}
		yield return new SetLine(0, "DynamicWater not available");
	}

	[TerminalCommand("prosperity_points", "Gets or sets available prosperity points", "General", true)]
	public static void ProsperityPoints(int amount = -1)
	{
		if (Player.inst == null)
		{
			TerminalUI.inst.PrintError("Player not available");
			return;
		}
		int prosperityPoints = Player.inst.ProsperityPoints;
		if (amount >= 0)
		{
			int num = amount - prosperityPoints;
			if (num < 0)
			{
				Player.inst.TakeProsperityPoints(Mathf.Abs(num));
			}
			else
			{
				Player.inst.GiveProsperityPoints(num);
			}
			TerminalUI.inst.PrintSuccess($"Prosperity points: {prosperityPoints} -> {Player.inst.ProsperityPoints}");
		}
		else
		{
			TerminalUI.inst.PrintSuccess($"Prosperity points: {Player.inst.ProsperityPoints}");
		}
	}

	[TerminalCommand("ui", "Turns the UI [(on), off]", "General", true)]
	public static void UIVisible(bool on = true)
	{
		KeyboardControl.inst.SetGameUIVisibility(on);
		TerminalUI.inst.PrintSuccess("UI has been " + (on ? "hidden" : "unhidden"));
	}

	[TerminalCommand("version", "Show Unity and game version", "General", false)]
	public static void ShowVersion()
	{
		TerminalUI.inst.PrintLine("Unity Version: " + Application.unityVersion);
		TerminalUI.inst.PrintLine("Product Name: " + Application.productName);
		TerminalUI.inst.PrintLine("Version: " + Application.version);
		TerminalUI.inst.PrintLine($"Platform: {Application.platform}");
	}

	[TerminalCommand("spawn_villagers", "Spawn X villagers at cursor", "General", true)]
	public static void Spawn(int villagers = 10)
	{
		Ray ray = PointingSystem.GetPointer().GetRay();
		TerrainGen.inst.Raycast(ray, out var hitInfo);
		Vector3 point = ray.GetPoint(hitInfo.distance);
		for (int i = 0; i < villagers; i++)
		{
			Villager villager = Villager.CreateVillager();
			Player.inst.Workers.Add(villager);
			Player.inst.Homeless.Add(villager);
			villager.TeleportTo(point);
		}
	}

	[TerminalCommand("despawn_villagers", "Remove X villagers around cursor", "General", true)]
	public static void Despawn(int villagers = 10)
	{
		if (Player.inst == null)
		{
			TerminalUI.inst.PrintError("Player not available");
			return;
		}
		if (Player.inst.Workers.Count == 0)
		{
			TerminalUI.inst.PrintError("No villagers to remove");
			return;
		}
		Ray ray = PointingSystem.GetPointer().GetRay();
		TerrainGen.inst.Raycast(ray, out var hitInfo);
		Vector3 cursorPosition = ray.GetPoint(hitInfo.distance);
		List<Villager> list = new List<Villager>();
		for (int i = 0; i < Player.inst.Workers.Count; i++)
		{
			list.Add(Player.inst.Workers.data[i]);
		}
		list.Sort((Villager a, Villager b) =>
		{
			float num4 = Vector3.Distance(a.Pos, cursorPosition);
			float value = Vector3.Distance(b.Pos, cursorPosition);
			return num4.CompareTo(value);
		});
		int num = Mathf.Min(villagers, list.Count);
		int num2 = 0;
		for (int num3 = 0; num3 < num; num3++)
		{
			Villager villager = list[num3];
			if (villager != null)
			{
				Vector3.Distance(villager.Pos, cursorPosition);
				Player.inst.DestroyPerson(villager, leaveBehindBody: false);
				num2++;
			}
		}
		if (num2 > 0)
		{
			TerminalUI.inst.PrintSuccess($"Successfully removed {num2} villagers");
			TerminalUI.inst.PrintLine($"Remaining villagers: {Player.inst.Workers.Count}");
		}
		else
		{
			TerminalUI.inst.PrintWarning("No villagers were removed");
		}
	}

	[TerminalCommand("season", "Get or set the current season (spring, summer, fall/autumn, winter)", "Game", true)]
	[TerminalParameterHints("seasonName", new string[] { "spring", "summer", "fall", "autumn", "winter" })]
	public static void Season(string seasonName = "")
	{
		if (SeasonManager.inst == null)
		{
			TerminalUI.inst.PrintError("SeasonManager not available");
			return;
		}
		if (string.IsNullOrEmpty(seasonName))
		{
			if (SeasonManager.inst.CurrentSeason != null)
			{
				TerminalUI.inst.PrintLine("Current season: " + SeasonManager.inst.CurrentSeason.name, TerminalUI.inst.commandTextColor);
				TerminalUI.inst.PrintLine($"Season ID: {SeasonManager.inst.CurrentSeason.id}");
				TerminalUI.inst.PrintLine($"Year: {SeasonManager.inst.CurrentYear()}");
			}
			else
			{
				TerminalUI.inst.PrintError("No current season set");
			}
			return;
		}
		int num = -1;
		switch (seasonName.ToLower())
		{
		case "spring":
			num = 3;
			break;
		case "summer":
			num = 0;
			break;
		case "fall":
		case "autumn":
			num = 1;
			break;
		case "winter":
			num = 2;
			break;
		default:
			TerminalUI.inst.PrintError("Invalid season. Use: spring, summer, fall/autumn, winter");
			return;
		}
		string name = SeasonManager.inst.CurrentSeason.name;
		int num2 = SeasonManager.inst.CurrentYear();
		try
		{
			SeasonManager.inst.SkipToSeason(num);
			SeasonManager.inst.SetTime(12f);
			int num3 = SeasonManager.inst.CurrentYear();
			string name2 = SeasonManager.inst.CurrentSeason.name;
			TerminalUI.inst.PrintSuccess("Season changed from " + name + " to " + name2);
			if (num3 > num2)
			{
				TerminalUI.inst.PrintLine($"Advanced to year {num3}");
			}
		}
		catch (Exception ex)
		{
			TerminalUI.inst.PrintError("Failed to change season: " + ex.Message);
		}
	}

	[TerminalCommand("set_resources", "Set resource amounts by adjusting physical resources in world (e.g. set_resources gold 1000 wood 500)", "General", true)]
	[TerminalParameterHints("args", new string[]
	{
		"gold", "wood", "stone", "food", "wheat", "charcoal", "ironore", "tools", "armament", "fish",
		"apples", "pork", "bread", "grapes", "wine", "marble", "clay", "pottery", "dirt", "olives",
		"oliveoil"
	})]
	public static void SetResources(params string[] args)
	{
		if (Player.inst == null)
		{
			TerminalUI.inst.PrintError("Player not available");
			return;
		}
		if (FreeResourceSystem.inst == null)
		{
			TerminalUI.inst.PrintError("FreeResourceSystem not available");
			return;
		}
		if (args.Length == 0 || args.Length % 2 != 0)
		{
			TerminalUI.inst.PrintError("Usage: set_resources <type> <amount> [type amount ...]");
			TerminalUI.inst.PrintLine("Available types: gold, wood, stone, food, wheat, charcoal, ironore, tools, armament, fish, apples, pork, bread, grapes, wine, marble, clay, pottery, dirt, olives, oliveoil");
			return;
		}
		Vector3 trackingPos = Cam.inst.TrackingPos;
		for (int i = 0; i < args.Length; i += 2)
		{
			string text = args[i].ToLower();
			if (!int.TryParse(args[i + 1], out var result))
			{
				TerminalUI.inst.PrintError("Invalid amount '" + args[i + 1] + "' for " + text);
				continue;
			}
			int resourceIDFromName = GetResourceIDFromName(text);
			if (resourceIDFromName == -1)
			{
				TerminalUI.inst.PrintError("Unknown resource type: " + text);
				continue;
			}
			try
			{
				SetResourceAmount(resourceIDFromName, result, trackingPos);
				TerminalUI.inst.PrintSuccess($"Set {text} to {result}");
			}
			catch (Exception ex)
			{
				TerminalUI.inst.PrintError("Failed to set " + text + ": " + ex.Message);
			}
		}
		RefreshResourceCounts();
	}

	[TerminalCommand("remove_stacks", "Remove all world stacks", "General", true)]
	public static void RemoveStacks()
	{
		for (int num = ResourceStackAuto.stacks.Count - 1; num >= 0; num--)
		{
			GraphicalResourceStack obj = ResourceStackAuto.stacks.data[num];
			ResourceStackAuto component = obj.GetComponent<ResourceStackAuto>();
			if (component != null)
			{
				component.Unhook();
			}
			UnityEngine.Object.Destroy(obj.gameObject);
		}
	}

	private static int GetResourceIDFromName(string name)
	{
		switch (name.ToLower())
		{
		case "wheat":
		case "food":
			return 0;
		case "tree":
		case "wood":
			return 1;
		case "stone":
			return 2;
		case "charcoal":
			return 3;
		case "gold":
			return 4;
		case "ironore":
		case "iron":
			return 5;
		case "tools":
			return 6;
		case "armament":
		case "armaments":
			return 7;
		case "fish":
			return 8;
		case "apples":
			return 9;
		case "pork":
			return 10;
		case "bread":
			return 11;
		case "grapes":
			return 12;
		case "wine":
			return 13;
		case "marble":
			return 14;
		case "clay":
			return 15;
		case "pottery":
			return 16;
		case "dirt":
			return 17;
		case "olives":
			return 18;
		case "oliveoil":
		case "olive_oil":
			return 19;
		default:
			return -1;
		}
	}

	private static void SetResourceAmount(int resourceID, int targetAmount, Vector3 centerPos)
	{
		if (resourceID == 4)
		{
			Player.inst.PlayerLandmassOwner.Gold = targetAmount;
			return;
		}
		int num = CountPhysicalResources(resourceID);
		int num2 = targetAmount - num;
		if (num2 != 0)
		{
			if (num2 > 0)
			{
				AddPhysicalResources(resourceID, num2, centerPos);
			}
			else
			{
				RemovePhysicalResources(resourceID, -num2, centerPos);
			}
		}
	}

	private static int CountPhysicalResources(int resourceID)
	{
		if (Player.inst?.PlayerLandmassOwner == null)
		{
			return 0;
		}
		int num = 0;
		for (int i = 0; i < Player.inst.PlayerLandmassOwner.ownedLandMasses.Count; i++)
		{
			int num2 = Player.inst.PlayerLandmassOwner.ownedLandMasses.data[i];
			ResourceAmount resourceAmount = Player.inst.resourcesPerLandmass[num2];
			num += resourceAmount.Get(resourceID);
		}
		return num;
	}

	private static void AddPhysicalResources(int resourceID, int amount, Vector3 centerPos)
	{
		Vector3 pos = FindValidPlacementPosition(centerPos);
		FreeResourceManager.inst.AddOrMakeAutoStackFor(resourceID, amount, pos);
	}

	private static void RemovePhysicalResources(int resourceID, int amountToRemove, Vector3 centerPos)
	{
		int num = amountToRemove;
		for (int i = 0; i < Player.inst.PlayerLandmassOwner.ownedLandMasses.Count; i++)
		{
			if (num <= 0)
			{
				break;
			}
			int landMass = Player.inst.PlayerLandmassOwner.ownedLandMasses.data[i];
			num -= FreeResourceManager.inst.RemovePhysicalResources(resourceID, num, landMass);
		}
		if (num > 0)
		{
			TerminalUI.inst.PrintWarning($"Could only remove {amountToRemove - num} out of {amountToRemove} {GetResourceName(resourceID)} resources");
		}
	}

	private static string GetResourceName(int resourceID)
	{
		FreeResourceSystem inst = FreeResourceSystem.inst;
		if ((object)inst != null && inst.resourceDefMap?.ContainsKey(resourceID) == true)
		{
			return FreeResourceSystem.inst.resourceDefMap[resourceID].name;
		}
		return $"ResourceID_{resourceID}";
	}

	private static Vector3 FindValidPlacementPosition(Vector3 centerPos)
	{
		for (int i = 0; i <= 10; i++)
		{
			for (int j = 0; j < 8; j++)
			{
				float f = (float)j / 8f * 2f * MathF.PI;
				Vector3 vector = centerPos + new Vector3(Mathf.Cos(f) * (float)i, 0f, Mathf.Sin(f) * (float)i);
				vector.x = Mathf.Clamp(vector.x, 1f, World.inst.GridWidth - 1);
				vector.z = Mathf.Clamp(vector.z, 1f, World.inst.GridHeight - 1);
				vector.y = TerrainGen.inst.GetGroundHeight(vector.x, vector.z);
				Cell cellDataClamped = World.inst.GetCellDataClamped(vector);
				if (cellDataClamped != null && !cellDataClamped.deepWater && cellDataClamped.landMassIdx != -1)
				{
					return vector;
				}
			}
		}
		Vector3 result = centerPos;
		result.x = Mathf.Clamp(result.x, 1f, World.inst.GridWidth - 1);
		result.z = Mathf.Clamp(result.z, 1f, World.inst.GridHeight - 1);
		result.y = TerrainGen.inst.GetGroundHeight(result.x, result.z);
		return result;
	}

	private static void RefreshResourceCounts()
	{
		if (Player.inst?.resourcesPerLandmass == null)
		{
			return;
		}
		for (int i = 0; i < Player.inst.resourcesPerLandmass.Length; i++)
		{
			Player.inst.CountResources(i, Player.inst.resourcesPerLandmass[i]);
		}
		for (int j = 0; j < World.LandMassOwners.Count; j++)
		{
			LandmassOwner landmassOwner = World.LandMassOwners.data[j];
			for (int k = 0; k < landmassOwner.ownedLandMasses.Count; k++)
			{
				int num = landmassOwner.ownedLandMasses.data[k];
				Player.inst.resourcesPerLandmass[num].Set(4, landmassOwner.Gold);
			}
		}
	}

	[TerminalCommand("hold_time_progression", "Toggle the progression of day/night, seasons, and year progression", "General", true)]
	public static void HoldTimeProgression()
	{
		if (SeasonManager.inst == null)
		{
			TerminalUI.inst.PrintError("SeasonManager not available");
			return;
		}
		if (DayNightManager.inst == null)
		{
			TerminalUI.inst.PrintError("DayNightManager not available");
			return;
		}
		if (SeasonManager.inst.holdTimeNow)
		{
			SeasonManager.inst.CancelHold();
			TerminalUI.inst.PrintSuccess("Progression Resumed");
			return;
		}
		SeasonManager.inst.SetHold();
		float _24HourTime = DayNightManager.inst.GameParameters._24HourTime;
		bool isDay = DayNightManager.inst.GameParameters.isDay;
		string timeOfDayString = GetTimeOfDayString(_24HourTime);
		TerminalUI.inst.PrintSuccess("Progression stopped at:");
		TerminalUI.inst.PrintLine($"Current time: {_24HourTime:F1} hours ({timeOfDayString})", TerminalUI.inst.commandTextColor);
		TerminalUI.inst.PrintLine("Day/Night: " + (isDay ? "Day" : "Night"));
		TerminalUI.inst.PrintLine($"Year: {SeasonManager.inst.CurrentYear()}");
		TerminalUI.inst.PrintLine("Season: " + SeasonManager.inst.CurrentSeason.name);
	}

	[TerminalCommand("year", "Get or set the current year", "General", true)]
	public static void Year(int newYear = -1)
	{
		if (SeasonManager.inst == null)
		{
			TerminalUI.inst.PrintError("SeasonManager not available");
			return;
		}
		if (newYear < 0)
		{
			int num = SeasonManager.inst.CurrentYear();
			TerminalUI.inst.PrintLine($"Current year: {num}", TerminalUI.inst.commandTextColor);
			if (SeasonManager.inst.CurrentSeason != null)
			{
				TerminalUI.inst.PrintLine("Season: " + SeasonManager.inst.CurrentSeason.name);
			}
			return;
		}
		if (newYear <= 0)
		{
			TerminalUI.inst.PrintError("Year must be greater than 0");
			return;
		}
		int num2 = SeasonManager.inst.CurrentYear();
		try
		{
			SeasonManager.inst.SetCurrentYear(newYear);
			TerminalUI.inst.PrintSuccess($"Year changed from {num2} to {newYear}");
		}
		catch (Exception ex)
		{
			TerminalUI.inst.PrintError("Failed to set year: " + ex.Message);
		}
	}

	[TerminalCommand("water_conservation", "Toggle logging of tap-removed vs outlet-added water (ratio should be ~1.00)", "General", true)]
	public static void WaterConservation()
	{
		WaterFlowDiagnostics.Enabled = !WaterFlowDiagnostics.Enabled;
		if (!WaterFlowDiagnostics.Enabled)
		{
			WaterFlowDiagnostics.Clear();
		}
		TerminalUI.inst.PrintSuccess("Water conservation logging " + (WaterFlowDiagnostics.Enabled ? "ON" : "OFF"));
	}

	[TerminalCommand("water_source", "Add/Remove water source at mouse pointer", "General", true)]
	public static void WaterSource(int sourceAmt = 10, bool doRiver = false)
	{
		DynamicWater.inst.dynamicWaterJobHandle.Complete();
		Vector3 worldPos = GameUI.inst.GridPointerIntersection();
		Cell cellData = World.inst.GetCellData(worldPos);
		if (cellData == null)
		{
			return;
		}
		int index = DynamicWater.MapIndexWorldToMesh(cellData.index, World.inst.GridWidth);
		DynamicWater.WaterCell waterCell = DynamicWater.inst.waterGrid[index];
		if (waterCell.waterProductionRate <= 0f)
		{
			DynamicWater.inst.CreateWaterSource(index, sourceAmt);
			if (doRiver)
			{
				DynamicWater.inst.CutRiver(waterCell.index);
			}
		}
		else
		{
			DynamicWater.inst.RemoveWaterSource(index);
		}
	}

	[TerminalCommand("add_fish", "Add fish at mouse position", "General", true)]
	public static void AddFish(int radius = 0)
	{
		Vector3 worldPos = GameUI.inst.GridPointerIntersection();
		Cell cellData = World.inst.GetCellData(worldPos);
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		float num = radius * radius;
		int num2 = Mathff.Clamp(cellData.x - radius, 0, gridWidth);
		int num3 = Mathff.Clamp(cellData.x + radius, 0, gridWidth);
		int num4 = Mathff.Clamp(cellData.z - radius, 0, gridHeight);
		int num5 = Mathff.Clamp(cellData.z + radius, 0, gridHeight);
		for (int i = num2; i <= num3; i++)
		{
			for (int j = num4; j <= num5; j++)
			{
				if (World.inst.GetCellDataUnsafe(i, j).Type == TerrainType.Water && !(Mathff.DistSqrdXZ(i, j, cellData.x, cellData.z) > num))
				{
					FishSystem.inst.ForceFish(i, j);
				}
			}
		}
	}

	[TerminalCommand("start_plague", "Start plague at position", "General", true)]
	public static void StartPlague(int radius = 3, int strength = 40)
	{
		Vector3 worldPos = GameUI.inst.GridPointerIntersection();
		Cell cellData = World.inst.GetCellData(worldPos);
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		int num = Mathff.Clamp(cellData.x - radius, 0, gridWidth);
		int num2 = Mathff.Clamp(cellData.x + radius, 0, gridWidth);
		int num3 = Mathff.Clamp(cellData.z - radius, 0, gridHeight);
		int num4 = Mathff.Clamp(cellData.z + radius, 0, gridHeight);
		int num5 = 0;
		for (int i = num; i <= num2; i++)
		{
			for (int j = num3; j <= num4; j++)
			{
				ArrayExtRef<Villager> villagersAt = World.inst.GetVillagersAt(i, j);
				for (int k = 0; k < villagersAt.Count; k++)
				{
					if (SRand.Range(0, 100) < strength && !villagersAt.data[k].sick)
					{
						num5++;
						villagersAt.data[k].BecomeSick(strength / 2);
					}
				}
			}
		}
	}

	[TerminalCommand("spawn_merchants", "Spawn foreign merchant ships", "General", true)]
	public static void SpawnMerchants()
	{
		for (int i = 0; i < ShipSystem.inst.merchantSpawnTimers.Length; i++)
		{
			ShipSystem.inst.merchantSpawnTimers[i] = float.MinValue;
		}
	}

	[TerminalCommand("refresh_govenors", "Refresh govenor selection", "General", true)]
	public static void RefreshGovenors()
	{
		AdvisorUI.inst.GenerateGovenorOptions();
	}
}
