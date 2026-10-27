using Assets.Code.Interface;
using I2.Loc;
using UnityEngine;

public class PublicToilet : MonoBehaviour, IOverlayUser, IOutputInfo, IWorkerUIDisplay
{
	public float minProtectionRadius = 4f;

	public float maxProtectionRadius = 8f;

	public WaterConsumer waterConsumer;

	internal bool receivingWater;

	public Building b;

	public bool OverlayWhenPlacing => true;

	public bool OverlayWhenSelected => true;

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}

	private void OnInit()
	{
		waterConsumer.SetupChangeCallback(WaterConsumptionChanged);
	}

	private void RefreshWaterDisplay()
	{
		if (receivingWater)
		{
			PublicToiletManager.inst.AddWell(this);
			b.thought.thought = ThoughtBubbleSystem.Thought.Satisfied;
			b.thought.visible = false;
		}
		else
		{
			PublicToiletManager.inst.RemoveWell(this);
			b.thought.thought = ThoughtBubbleSystem.Thought.Water;
			b.thought.visible = true;
		}
	}

	public void WaterConsumptionChanged()
	{
		receivingWater = waterConsumer.availableWaterPercentage > 0.25f;
		RefreshWaterDisplay();
	}

	private void OnBuilt()
	{
		if (receivingWater)
		{
			PublicToiletManager.inst.AddWell(this);
		}
		RefreshWaterDisplay();
	}

	private void OnFinishedLoad()
	{
		if (b.IsBuilt() && receivingWater)
		{
			PublicToiletManager.inst.AddWell(this);
		}
		RefreshWaterDisplay();
	}

	private void OnShutdown()
	{
		PublicToiletManager.inst.RemoveWell(this);
		waterConsumer.ClearChangeCallback();
	}

	public void DrawOverlay(Vector3 origin)
	{
		TerrainGen.inst.ClearOverlay(updateToo: false);
		if (GameUI.inst.CurrPlacementMode.IsPlacing() || (!b.IsBuilt() && receivingWater))
		{
			WaterTower.DrawWaterTowerOverlayForConsumers();
		}
		PublicToiletManager.inst.DrawOverlay();
		if (GameUI.inst.CurrPlacementMode.IsPlacing() || (!b.IsBuilt() && receivingWater))
		{
			PublicToiletManager.inst.DrawWellOverlay(this);
		}
		TerrainGen.inst.ApplyBuildingOverlayMaterial();
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}

	private void Update()
	{
	}

	public string GetError()
	{
		if (b.thought.thought == ThoughtBubbleSystem.Thought.Water)
		{
			return LocalizationManager.GetTranslation("FountainErrorNotConnected");
		}
		return "";
	}
}
