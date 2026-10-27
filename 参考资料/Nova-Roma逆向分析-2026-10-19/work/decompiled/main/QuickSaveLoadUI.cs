using Assets.Code;
using Assets.Code.UI;
using UnityEngine;
using UnityEngine.UI;

public class QuickSaveLoadUI : MonoBehaviour
{
	public static QuickSaveLoadUI inst;

	[SerializeField]
	private Confirmation loadConfirmation;

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster raycaster;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisiblity(bool v)
	{
		isVisible = v;
		if (!v)
		{
			loadConfirmation.Reset();
		}
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(raycaster, v);
	}

	private void Awake()
	{
		inst = this;
	}

	private void Update()
	{
		if (isVisible)
		{
			return;
		}
		if (!InvalidToSave() && ConfigurableControls.inst.GetInputActionKeyDown(804))
		{
			LoadSave.AutoSave(World.inst.guid);
			GameSavedUI.inst.SetVisibility(v: true);
		}
		else
		{
			if (!ConfigurableControls.inst.GetInputActionKeyDown(805))
			{
				return;
			}
			SetVisiblity(v: true);
			TimeManager.inst.SetPaused(skipSfx: true);
			loadConfirmation.ShowConfirmation(() =>
			{
				int num = 0;
				while (!KeyboardControl.inst.HandleEscape(forceClose: true) && num < 20)
				{
					num++;
				}
				LoadSave.LoadAutoSave();
				TimeManager.inst.ReturnToPlaySpeed(skipSfx: true);
			}, () =>
			{
				SetVisiblity(v: false);
				TimeManager.inst.ReturnToPrevious(skipSfx: true);
			});
		}
	}

	private bool InvalidToSave()
	{
		if (!GameUI.inst.EditTerrainCursorModeActive())
		{
			return GameUI.inst.DamPlannerCursorModeActive();
		}
		return true;
	}
}
