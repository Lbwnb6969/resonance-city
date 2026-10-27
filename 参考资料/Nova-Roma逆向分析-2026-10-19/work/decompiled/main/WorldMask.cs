using UnityEngine;
using UnityEngine.Rendering;
using UnityStandardAssets.ImageEffects;

[RequireComponent(typeof(Camera))]
public class WorldMask : PostEffectsBase
{
	public delegate void MaskingDetails(CommandBuffer buffer, Material maskingMaterial, RenderTexture renderTexture);

	public Material maskMaterial;

	public Material maskingMaterial;

	public RenderTexture rTexture;

	private CommandBuffer buffer;

	public bool activated;

	public float fade;

	public float fadeSpeed = 2f;

	private int maskShaderPass;

	public MaskingDetails ExecuteMaskingDetails;

	public static WorldMask inst;

	public void Awake()
	{
		inst = this;
	}

	public void Activate(MaskingDetails maskingFunction, int shaderPass = 0)
	{
		ExecuteMaskingDetails = maskingFunction;
		maskShaderPass = shaderPass;
		if (!activated)
		{
			if (rTexture == null)
			{
				BuildRenderTexture();
			}
			if (maskingMaterial == null)
			{
				maskMaterial = Object.Instantiate(Resources.Load<Material>("WorldMask"));
				maskingMaterial = Object.Instantiate(Resources.Load<Material>("MaskMaker"));
			}
			buffer = new CommandBuffer();
			Cam.inst.cam.AddCommandBuffer(CameraEvent.AfterReflections, buffer);
			ExecuteMaskingDetails(buffer, maskingMaterial, rTexture);
			activated = true;
		}
		Util.SetEnabled(this, active: true);
	}

	public void Deactivate()
	{
		activated = false;
	}

	public void Update()
	{
		if (!(Cam.inst?.cam == null))
		{
			fade = Mathf.Clamp01(fade + Time.unscaledDeltaTime * (float)(activated ? 1 : (-1)) * fadeSpeed);
			if (fade == 0f && !activated)
			{
				Util.SetEnabled(this, active: false);
			}
			if (rTexture == null || rTexture.width != Cam.inst.cam.pixelWidth || rTexture.height != Cam.inst.cam.pixelHeight)
			{
				BuildRenderTexture();
				ExecuteMaskingDetails(buffer, maskingMaterial, rTexture);
			}
		}
	}

	public void ForceUpdate()
	{
		ExecuteMaskingDetails(buffer, maskingMaterial, rTexture);
	}

	private void BuildRenderTexture()
	{
		if (rTexture != null)
		{
			Object.Destroy(rTexture);
		}
		rTexture = new RenderTexture(Cam.inst.cam.pixelWidth, Cam.inst.cam.pixelHeight, 16, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
		rTexture.antiAliasing = 1;
		rTexture.autoGenerateMips = false;
		rTexture.filterMode = FilterMode.Point;
		rTexture.anisoLevel = 0;
		rTexture.Create();
	}

	private void OnDisable()
	{
		activated = false;
		Cam.inst.cam.RemoveCommandBuffer(CameraEvent.AfterReflections, buffer);
		buffer.Clear();
		buffer = null;
	}

	public static void AddBuildingsOfTypeOnLandmass(ArrayExt<Renderer> array, int hashname, int landmass)
	{
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(landmass, hashname);
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			if (FogOfWar.inst.IsVisible(buildingListForLandMass.data[i].Center()))
			{
				array.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(buildingListForLandMass.data[i].gameObject));
			}
		}
	}

	public static void AddBuildingsOfType(ArrayExt<Renderer> array, int hashname)
	{
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList(hashname);
		for (int i = 0; i < buildingList.Count; i++)
		{
			if (FogOfWar.inst.IsVisible(buildingList.data[i].Center()))
			{
				array.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(buildingList.data[i].gameObject));
			}
		}
	}

	[ImageEffectOpaque]
	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if (!(maskMaterial == null))
		{
			maskMaterial.SetFloat("_Fade", fade);
			maskMaterial.SetTexture("_Source", source);
			maskMaterial.SetTexture("_Mask", rTexture);
			Graphics.Blit(source, destination, maskMaterial, maskShaderPass);
		}
	}
}
