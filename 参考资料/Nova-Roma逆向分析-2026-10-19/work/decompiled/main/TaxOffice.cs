using System;
using Assets.Code;
using Assets.Code.Interface;
using I2.Loc;
using UnityEngine;

public class TaxOffice : MonoBehaviour, IOverlayUser, IWorkerUIDisplay, IOutputInfo, IProductionInfo
{
	[Serializable]
	public class TaxOfficeSaveData : SaveClass<TaxOffice, TaxOfficeSaveData>
	{
		private float rate;

		public override TaxOfficeSaveData Pack(TaxOffice obj)
		{
			rate = obj.Rate;
			return this;
		}

		public override TaxOffice Unpack(TaxOffice obj)
		{
			obj.Rate = rate;
			return obj;
		}
	}

	public float Radius;

	internal float Rate = 1f;

	public Building b;

	public bool OverlayWhenPlacing => true;

	public bool OverlayWhenSelected => true;

	private void Awake()
	{
		b = GetComponent<Building>();
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}

	string IOutputInfo.GetError()
	{
		if (b.GetWorkerPercent() < 1f)
		{
			return ScriptLocalization.OutputUINotFullyStaffed;
		}
		return "";
	}

	public float GetWorkerPercent()
	{
		return b.GetWorkerPercent();
	}

	public void DrawOverlay(Vector3 origin)
	{
		TerrainGen.inst.ClearOverlay(updateToo: false);
		TaxOfficeManager.inst.DrawOverlay();
		if (!b.IsBuilt())
		{
			TaxOfficeManager.inst.DrawTaxOfficeOverlay(this);
		}
		TerrainGen.inst.ApplyBuildingOverlayMaterial();
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}

	private void OnBuilt()
	{
		TaxOfficeManager.inst.AddTaxOffice(this);
	}

	private void OnFinishedLoad()
	{
		if (b.IsBuilt())
		{
			TaxOfficeManager.inst.AddTaxOffice(this);
		}
	}

	private void OnShutdown()
	{
		TaxOfficeManager.inst.RemoveTaxOffice(this);
	}

	public void Update()
	{
		if (b.IsBuilt() && b.IsOpen())
		{
			if (b.GetWorkerPercent() <= 0f)
			{
				b.thought.thought = ThoughtBubbleSystem.Thought.GeneralError;
				b.thought.visible = true;
			}
			else
			{
				b.thought.visible = false;
			}
		}
	}

	ResourceAmount IProductionInfo.GetCost()
	{
		throw new NotImplementedException();
	}

	int IProductionInfo.GetResult(int rID)
	{
		if (rID != 4)
		{
			return 0;
		}
		return 1;
	}

	bool IProductionInfo.ShowResultStorage()
	{
		throw new NotImplementedException();
	}

	int IProductionInfo.GetInputStorage(int rID)
	{
		return 0;
	}

	int IProductionInfo.GetInputMaxStorage(int rID)
	{
		return 0;
	}

	int IProductionInfo.GetOutputStorage(int rID)
	{
		return 0;
	}

	int IProductionInfo.GetOutputMaxStorage(int rID)
	{
		return 0;
	}

	BuildingProductionUI.CustomProductionItem[] IProductionInfo.GetCustomCost()
	{
		throw new NotImplementedException();
	}

	BuildingProductionUI.CustomProductionItem[] IProductionInfo.GetCustomResult()
	{
		throw new NotImplementedException();
	}

	float IProductionInfo.GetProgress()
	{
		throw new NotImplementedException();
	}

	int IProductionInfo.GetTotalBonus()
	{
		return 0;
	}

	string IProductionInfo.GetCustomText()
	{
		throw new NotImplementedException();
	}
}
