using Assets;
using UnityEngine;

public class CommandPathMarker : OneOffEffect
{
	private Selector destClickMarker;

	public const string Selector_CommandPath = "selector_commandpath";

	public float pathMarkerFullScaleTime = 0.5f;

	private float pathMarkerTime;

	private int markerCount;

	private Vector3 pathMarkerScale = new Vector3(0.1f, 0.1f, 0.1f);

	private Vector3 pathMarkerHideScale = new Vector3(0f, 1f, 0f);

	public Mesh pathMarkerMesh;

	private Material currMarkerMaterial;

	public Material pathMarkerMaterial;

	public Material pathMarkerMaterialArmyTarget;

	private Matrix4x4[] pathMarkers = new Matrix4x4[64];

	private void InitDestClickMarker()
	{
		if (!destClickMarker)
		{
			destClickMarker = Object.Instantiate(GameUI.inst.HighlightPrefab);
			destClickMarker.SetSingleCellMesh();
			destClickMarker.SetupSelectorLookup("selector_commandpath");
			destClickMarker.DisableCorners();
			destClickMarker.transform.Rotate(0f, 45f, 0f);
			destClickMarker.SetTargetWorldBounds(0, 1, 0, 1);
			destClickMarker.SetVisibility(v: false);
		}
	}

	private void OnDestroy()
	{
		Object.Destroy(destClickMarker);
		destClickMarker = null;
	}

	public override void Init()
	{
		base.Init();
		if ((bool)destClickMarker)
		{
			destClickMarker.SetVisibility(v: true);
		}
	}

	public override void Shutdown()
	{
		base.Shutdown();
		if ((bool)destClickMarker)
		{
			destClickMarker.SetVisibility(v: false);
		}
	}

	public void ShowPath(ArrayExt<Vector3> displayPath, bool isEnemyTarget = false)
	{
		InitDestClickMarker();
		if (displayPath.Count <= 0)
		{
			return;
		}
		pathMarkerScale = new Vector3(0.1f, 0.1f, 0.1f);
		pathMarkerTime = pathMarkerFullScaleTime;
		markerCount = 0;
		if (displayPath.Count > 1)
		{
			for (int i = 0; i < displayPath.Count; i++)
			{
				if (markerCount >= pathMarkers.Length)
				{
					break;
				}
				Mathff.SetTS(ref pathMarkers[markerCount++], displayPath.data[i], pathMarkerScale);
			}
		}
		currMarkerMaterial = (isEnemyTarget ? pathMarkerMaterialArmyTarget : pathMarkerMaterial);
		if (isEnemyTarget)
		{
			destClickMarker.SetHighlightColor(new Color(1f, 0f, 0f, 0.5f));
		}
		else
		{
			destClickMarker.SetHighlightColor(new Color(0f, 1f, 1f, 0.5f));
		}
		Vector3 vector = displayPath.Last();
		destClickMarker.SetTargetWorldBounds((int)vector.x, (int)vector.x + 1, (int)vector.z, (int)vector.z + 1);
		destClickMarker.transform.localScale = (isEnemyTarget ? new Vector3(0.6f, 1f, 0.6f) : new Vector3(0.9f, 1f, 0.9f));
		destClickMarker.SetVisibility(v: true);
	}

	public override bool IsAlive()
	{
		Vector3 localScale = destClickMarker.transform.localScale;
		if (!(pathMarkerScale.x >= 0.001f) || !(pathMarkerScale.y >= 0.001f) || !(pathMarkerScale.z >= 0.001f))
		{
			if (localScale.x >= 0.001f && localScale.y >= 0.001f)
			{
				return localScale.z >= 0.001f;
			}
			return false;
		}
		return true;
	}

	private void LateUpdate()
	{
		if (currMarkerMaterial == null)
		{
			currMarkerMaterial = pathMarkerMaterial;
		}
		if (Settings.inst.supportsInstancing)
		{
			Graphics.DrawMeshInstanced(pathMarkerMesh, 0, currMarkerMaterial, pathMarkers, markerCount);
		}
		else
		{
			for (int i = 0; i < markerCount; i++)
			{
				Graphics.DrawMesh(pathMarkerMesh, pathMarkers[i], currMarkerMaterial, 0);
			}
		}
		pathMarkerTime -= Time.unscaledDeltaTime;
		if (pathMarkerTime < 0f)
		{
			pathMarkerScale = Vector3.MoveTowards(pathMarkerScale, Vector3.zero, 2f * Time.unscaledDeltaTime);
			destClickMarker.transform.localScale = Vector3.MoveTowards(destClickMarker.transform.localScale, pathMarkerHideScale, 5f * Time.unscaledDeltaTime);
			markerCount = 0;
		}
	}
}
