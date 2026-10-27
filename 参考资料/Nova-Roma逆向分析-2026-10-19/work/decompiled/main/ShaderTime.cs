using UnityEngine;

public class ShaderTime : MonoBehaviour
{
	private static readonly int UnscaledTime = Shader.PropertyToID("_UnscaledTime");

	private static readonly int FoliageWindPhaseTime = Shader.PropertyToID("_FoliageWindPhaseTime");

	private static readonly int FoliageWindSpatialTimeX = Shader.PropertyToID("_FoliageWindSpatialTimeX");

	private static readonly int FoliageWindSpatialTimeZ = Shader.PropertyToID("_FoliageWindSpatialTimeZ");

	private static readonly int TreeWindSpatialTime = Shader.PropertyToID("_TreeWindSpatialTime");

	private const float UnityShaderTimeScale = 0.05f;

	private void Update()
	{
		Shader.SetGlobalFloat(UnscaledTime, Time.unscaledTime);
		float num = Time.time * 0.05f;
		Shader.SetGlobalFloat(FoliageWindPhaseTime, num * 100f);
		Shader.SetGlobalFloat(FoliageWindSpatialTimeX, num * 8f);
		Shader.SetGlobalFloat(FoliageWindSpatialTimeZ, num * 16f);
		Shader.SetGlobalFloat(TreeWindSpatialTime, num * 3f);
	}
}
