using System;
using I2.Loc;
using TMPro;
using UnityEngine;

public class BuildingCemeteryUI : MonoBehaviour
{
	public static BuildingCemeteryUI inst;

	[SerializeField]
	public TextMeshProUGUI descTMP;

	[NonSerialized]
	public Building building;

	[NonSerialized]
	public Cemetery cemetery;

	private Timer time = new Timer(2f);

	private bool isVisible;

	public void Awake()
	{
		inst = this;
	}

	public void SetVisiblity(bool v)
	{
		Util.SetActive(gameObject, v);
		isVisible = v;
	}

	public void OnBuildingSelected(Building b)
	{
		building = b;
		if (!(b == null) && !((cemetery = b.GetComponent<Cemetery>()) == null))
		{
			time.ForceExpire();
			RefreshVisuals();
			SetVisiblity(v: true);
		}
	}

	public void OnDeselected()
	{
		building = null;
		cemetery = null;
		SetVisiblity(v: false);
	}

	private void Update()
	{
		if (isVisible && !(cemetery == null) && time.Update(Time.deltaTime))
		{
			RefreshVisuals();
		}
	}

	private void RefreshVisuals()
	{
		descTMP.text = string.Format(LocalizationManager.GetTranslation(cemetery.isColumbarium ? "workerui_columbarium_nichesoccupied_desc" : "workerui_cemetery_burialplotsoccupied_desc"), cemetery.GetUsedGraveCount(), cemetery.GetMaxGraveCount());
	}
}
