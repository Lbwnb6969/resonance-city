using System;
using UnityEngine;

public class PhotoboothEntry : MonoBehaviour
{
	public string iconName;

	public string path = "Sprites\\Photobooth";

	public int textureWidth = 256;

	public int textureHeight = 256;

	public bool lightEnabled = true;

	public Vector3 lightEuler = new Vector3(45f, -90f, 0f);

	public float lightIntensity = 1f;

	public Color lightColor = Color.white;

	public bool ssaoEnabled = true;

	public int downSampling = 1;

	public float intensity = 6f;

	public float radius = 0.1f;

	public float distance = 1.5f;

	public float bias = 0.15f;

	public float lightingContribution = 0.6f;

	public int blurPasses = 4;

	public int blurThreshold = 10;

	public float cutoffMaxDistance = 150f;

	public float cutoffFalloff = 50f;

	public bool whiteBalanceEnabled = true;

	public Color whitePoint = new Color(0.5333334f, 0.6f, 0.6705883f);

	public bool levelsEnabled = true;

	public Vector2 contrast = new Vector2(7f, 255f);

	[Range(0f, 10f)]
	public float gamma = 1f;

	public Transform target;

	[NonSerialized]
	public bool isDirty;

	[NonSerialized]
	public bool isLightDirty;

	[NonSerialized]
	public bool isLevelsDirty;

	[NonSerialized]
	public bool isSSAODirty;

	[NonSerialized]
	public bool isWhiteBalanceDirty;

	[NonSerialized]
	public bool isCameraDirty;

	private void SetLightDirty()
	{
		isLightDirty = true;
	}

	private void SetSSAODirty()
	{
		isSSAODirty = true;
	}

	private void SetWhiteBalanceDirty()
	{
		isWhiteBalanceDirty = true;
	}

	private void SetLevelsDirty()
	{
		isLevelsDirty = true;
	}

	private void SetCameraDirty()
	{
		isCameraDirty = true;
	}
}
