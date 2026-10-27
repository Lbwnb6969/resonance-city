using UnityEngine;
using UnityEngine.UI;

public class AqueductBuildingFlowCard : MonoBehaviour
{
	public float lastFlow;

	public float minV;

	public float maxV = 1f;

	public float waterSpeed = 4f;

	public Image waterImage;

	public void Init()
	{
		waterImage.material = Object.Instantiate(waterImage.material);
		SetShaderValues();
	}

	private void SetShaderValues()
	{
		waterImage.material.SetFloat("_MinV", minV);
		waterImage.material.SetFloat("_MaxV", maxV);
		waterImage.material.SetFloat("_WaterSpeed", waterSpeed);
		waterImage.materialForRendering.SetFloat("_MinV", minV);
		waterImage.materialForRendering.SetFloat("_MaxV", maxV);
		waterImage.materialForRendering.SetFloat("_WaterSpeed", waterSpeed);
	}

	public void SetFullness(float fullness)
	{
		fullness = Mathf.Clamp01(fullness);
		waterImage.material.SetFloat("_Fullness", fullness);
		waterImage.materialForRendering.SetFloat("_Fullness", fullness);
	}
}
