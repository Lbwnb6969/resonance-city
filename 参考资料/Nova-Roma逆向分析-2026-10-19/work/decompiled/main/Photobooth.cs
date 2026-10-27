using System.Collections.Generic;
using System.IO;
using Colorful;
using UnityEngine;

[ExecuteInEditMode]
public class Photobooth : MonoBehaviour
{
	public Camera camera;

	public Transform booth;

	public Light light;

	public SSAOPro ssao;

	public Levels levels;

	public WhiteBalance whiteBalance;

	public List<PhotoboothEntry> targets = new List<PhotoboothEntry>(8);

	public RenderTexture renderTexture;

	private PhotoboothEntry currEntry;

	public PhotoboothEntry GetCurrentEntry()
	{
		return currEntry;
	}

	private void Update()
	{
		int num = 0;
		for (int i = 0; i < booth.childCount; i++)
		{
			Transform child = booth.GetChild(i);
			if (!child.gameObject.activeSelf)
			{
				continue;
			}
			PhotoboothEntry photoboothEntry = child.gameObject.GetComponent<PhotoboothEntry>();
			if (photoboothEntry == null)
			{
				photoboothEntry = child.gameObject.AddComponent<PhotoboothEntry>();
				photoboothEntry.target = child;
			}
			if (num < targets.Count)
			{
				if (child != targets[num])
				{
					targets[num] = photoboothEntry;
				}
			}
			else
			{
				targets.Add(photoboothEntry);
			}
			num++;
		}
		if (targets.Count == 0)
		{
			currEntry = null;
		}
		else if (currEntry == null || currEntry != targets[0])
		{
			SetEntryTarget(targets[0]);
		}
		if (currEntry != null)
		{
			UpdateEntryTarget();
		}
		for (int num2 = targets.Count - 1; num2 >= num; num2--)
		{
			targets.RemoveAt(num2);
		}
	}

	private void SetEntryTarget(PhotoboothEntry entry)
	{
		entry.isDirty = true;
		currEntry = entry;
	}

	private void UpdateEntryTarget()
	{
		if (currEntry.isLightDirty || currEntry.isDirty)
		{
			Util.SetEnabled(light, currEntry.lightEnabled);
			light.transform.localRotation = Quaternion.Euler(currEntry.lightEuler);
			light.intensity = currEntry.lightIntensity;
			light.color = currEntry.lightColor;
			currEntry.isLightDirty = false;
		}
		if (currEntry.isSSAODirty || currEntry.isDirty)
		{
			Util.SetEnabled(ssao, currEntry.ssaoEnabled);
			ssao.Downsampling = currEntry.downSampling;
			ssao.Intensity = currEntry.intensity;
			ssao.Radius = currEntry.radius;
			ssao.Distance = currEntry.distance;
			ssao.Bias = currEntry.bias;
			ssao.LumContribution = currEntry.lightingContribution;
			ssao.BlurPasses = currEntry.blurPasses;
			ssao.BlurBilateralThreshold = currEntry.blurThreshold;
			ssao.CutoffDistance = currEntry.cutoffMaxDistance;
			ssao.CutoffFalloff = currEntry.cutoffFalloff;
			currEntry.isSSAODirty = false;
		}
		if (currEntry.isWhiteBalanceDirty || currEntry.isDirty)
		{
			Util.SetEnabled(whiteBalance, currEntry.whiteBalanceEnabled);
			whiteBalance.White = currEntry.whitePoint;
			currEntry.isWhiteBalanceDirty = false;
		}
		if (currEntry.isLevelsDirty || currEntry.isDirty)
		{
			Util.SetEnabled(levels, currEntry.levelsEnabled);
			levels.InputL.x = currEntry.contrast.x;
			levels.InputL.y = currEntry.contrast.y;
			levels.InputL.z = currEntry.gamma;
			currEntry.isLevelsDirty = false;
		}
		if (currEntry.isCameraDirty || currEntry.isDirty)
		{
			if (camera != null)
			{
				if (renderTexture == null || renderTexture.width != currEntry.textureWidth || renderTexture.height != currEntry.textureHeight)
				{
					renderTexture = new RenderTexture(currEntry.textureWidth, currEntry.textureHeight, 32);
				}
				camera.aspect = (float)currEntry.textureWidth / (float)currEntry.textureHeight;
				camera.targetTexture = renderTexture;
			}
			currEntry.isCameraDirty = false;
		}
		currEntry.isDirty = false;
	}

	public void CaptureIcon()
	{
		if (!(currEntry != null) || !(camera != null) || !(renderTexture != null) || renderTexture.width != currEntry.textureWidth || renderTexture.height != currEntry.textureHeight)
		{
			return;
		}
		Texture2D texture2D = new Texture2D(currEntry.textureWidth, currEntry.textureHeight, TextureFormat.RGBA32, mipChain: false);
		texture2D.name = "PhotoboothCapture";
		camera.Render();
		RenderTexture.active = renderTexture;
		texture2D.ReadPixels(new Rect(0f, 0f, currEntry.textureWidth, currEntry.textureHeight), 0, 0);
		Vector4 vector = Color.magenta;
		Color[] pixels = texture2D.GetPixels();
		for (int i = 0; i < pixels.Length; i++)
		{
			if (((Vector4)pixels[i] - vector).magnitude < 0.5f)
			{
				pixels[i].a = 0f;
			}
		}
		texture2D.SetPixels(pixels);
		byte[] bytes = texture2D.EncodeToPNG();
		File.WriteAllBytes(Application.dataPath + "/" + currEntry.path + "/" + currEntry.iconName + ".png", bytes);
	}
}
