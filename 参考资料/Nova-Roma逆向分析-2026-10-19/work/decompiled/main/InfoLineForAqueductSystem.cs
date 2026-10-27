using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.Rendering;

public class InfoLineForAqueductSystem : MonoBehaviour
{
	private LineRenderer lineRenderer;

	private TextMeshPro textMesh;

	public Color invalidColor;

	public Color normalValidColor;

	public Color highPressureValidColor;

	private Color statusColor = Color.green;

	private const float guideWidth = 0.1f;

	private const int arcSegments = 24;

	private Material guideDashedMat;

	private Material guideSolidMat;

	private Material guideArcMat;

	private LineRenderer flatLine;

	private LineRenderer rayLine;

	private LineRenderer arcLine;

	private readonly List<LineRenderer> dropLines = new List<LineRenderer>();

	private Vector3 arcTopPoint;

	private Vector3 lineDirXZ;

	private Vector3[] scratch = new Vector3[0];

	private const float textPadAboveArc = 0.25f;

	private const float textSidePushMargin = 0.3f;

	public void Init()
	{
		lineRenderer = GetComponent<LineRenderer>();
		lineRenderer.alignment = LineAlignment.Local;
		textMesh = GetComponentInChildren<TextMeshPro>();
		textMesh.horizontalAlignment = HorizontalAlignmentOptions.Center;
		textMesh.verticalAlignment = VerticalAlignmentOptions.Bottom;
		textMesh.rectTransform.pivot = new Vector2(0.5f, 0f);
		transform.rotation = Quaternion.LookRotation(Vector3.up, Vector3.forward);
		Material material = Resources.Load<Material>("AqueductGuideLine");
		material.SetFloat("_LineWidth", 0.1f);
		guideDashedMat = new Material(material);
		guideSolidMat = new Material(material);
		guideSolidMat.SetFloat("_GapLength", 0f);
		guideArcMat = new Material(material);
		guideArcMat.SetFloat("_GapLength", 0f);
		guideArcMat.SetColor("_Color", statusColor);
		flatLine = CreateGuide("FlatGuide", guideDashedMat);
		rayLine = CreateGuide("RayGuide", guideSolidMat);
		arcLine = CreateGuide("ArcGuide", guideArcMat);
	}

	private LineRenderer CreateGuide(string name, Material mat)
	{
		GameObject gameObject = new GameObject(name);
		gameObject.transform.SetParent(transform, worldPositionStays: false);
		LineRenderer lineRenderer = gameObject.AddComponent<LineRenderer>();
		lineRenderer.sharedMaterial = mat;
		lineRenderer.useWorldSpace = true;
		lineRenderer.textureMode = LineTextureMode.Tile;
		lineRenderer.alignment = LineAlignment.View;
		lineRenderer.widthMultiplier = 0.1f;
		lineRenderer.numCornerVertices = 2;
		lineRenderer.shadowCastingMode = ShadowCastingMode.Off;
		lineRenderer.receiveShadows = false;
		return lineRenderer;
	}

	private void OnDestroy()
	{
		Object.Destroy(guideDashedMat);
		Object.Destroy(guideSolidMat);
		Object.Destroy(guideArcMat);
	}

	public void Set(Vector3 startLine, List<Vector3> waypoints, Vector3 endLine, AqueductBuilding startBuilding, AqueductBuilding endBuilding, bool placing)
	{
		if (scratch.Length != waypoints.Count + 2)
		{
			scratch = new Vector3[waypoints.Count + 2];
		}
		scratch[0] = startLine;
		for (int i = 0; i < waypoints.Count; i++)
		{
			scratch[i + 1] = waypoints[i];
		}
		scratch[^1] = endLine;
		AqueductLine.GradeWaypoints(ref scratch);
		lineRenderer.positionCount = scratch.Length;
		for (int j = 0; j < scratch.Length; j++)
		{
			lineRenderer.SetPosition(j, scratch[j] + new Vector3(0f, 0f, 0f));
		}
		UpdateGuides();
	}

	private void UpdateGuides()
	{
		int positionCount = lineRenderer.positionCount;
		float y = lineRenderer.GetPosition(0).y;
		flatLine.positionCount = positionCount;
		for (int i = 0; i < positionCount; i++)
		{
			Vector3 position = lineRenderer.GetPosition(i);
			position.y = y;
			flatLine.SetPosition(i, position);
		}
		int num = positionCount - 1;
		while (dropLines.Count < num)
		{
			dropLines.Add(CreateGuide($"DropGuide{dropLines.Count}", guideDashedMat));
		}
		for (int j = 0; j < dropLines.Count; j++)
		{
			bool flag = j < num;
			if (dropLines[j].gameObject.activeSelf != flag)
			{
				dropLines[j].gameObject.SetActive(flag);
			}
			if (flag)
			{
				Vector3 position2 = lineRenderer.GetPosition(j + 1);
				Vector3 position3 = position2;
				position3.y = y;
				dropLines[j].positionCount = 2;
				dropLines[j].SetPosition(0, position2);
				dropLines[j].SetPosition(1, position3);
			}
		}
		Vector3 position4 = lineRenderer.GetPosition(positionCount - 2);
		Vector3 position5 = lineRenderer.GetPosition(positionCount - 1);
		float b = Vector3.Distance(position4, position5);
		Vector3 normalized = (position5 - position4).normalized;
		float num2 = Mathf.Min(0.5f, b);
		float num3 = Mathf.Min(1.5f, b);
		rayLine.positionCount = 2;
		rayLine.SetPosition(0, position5 - normalized * num2);
		rayLine.SetPosition(1, position5 - normalized * num3);
		float num4 = Mathf.Min(1f, b);
		Vector3 vector = position5 - normalized * num4;
		Vector3 vector2 = vector;
		vector2.y = y;
		float y2 = normalized.y;
		float value = ((Mathf.Abs(y2) > 0.001f) ? ((y - position5.y) / y2) : float.NegativeInfinity);
		value = Mathf.Clamp(value, -100f, -1.5f);
		Vector3 vector3 = position5 + normalized * value;
		Vector3 a = vector - vector3;
		Vector3 b2 = vector2 - vector3;
		arcLine.positionCount = 25;
		for (int k = 0; k <= 24; k++)
		{
			float t = (float)k / 24f;
			arcLine.SetPosition(k, vector3 + Vector3.Slerp(a, b2, t));
		}
		arcTopPoint = ((vector2.y >= vector.y) ? vector2 : vector);
		lineDirXZ = normalized;
		lineDirXZ.y = 0f;
		lineDirXZ.Normalize();
	}

	public void UpdateStatus()
	{
		Vector3 position = this.lineRenderer.GetPosition(0);
		Vector3 position2 = this.lineRenderer.GetPosition(1);
		float num = 0f;
		for (int i = 0; i < this.lineRenderer.positionCount - 1; i++)
		{
			num += Vector3.Distance(this.lineRenderer.GetPosition(i), this.lineRenderer.GetPosition(i + 1));
		}
		bool flag = AqueductLine.LineValidAngleNormal(position, position2);
		bool flag2 = AqueductLine.LineValidAngleHighPressure(position, position2);
		bool flag3 = flag | flag2;
		LineRenderer lineRenderer = this.lineRenderer;
		Color startColor = (this.lineRenderer.endColor = ((!flag3) ? invalidColor : (flag ? normalValidColor : highPressureValidColor)));
		lineRenderer.startColor = startColor;
		statusColor = (flag3 ? Color.green : Color.red);
		guideArcMat.SetColor("_Color", statusColor);
		float num2 = AqueductLine.LineAngle(position, position2);
		if (float.IsNaN(num2))
		{
			num2 = 0f;
		}
		string empty = string.Empty;
		string empty2 = string.Empty;
		if (flag || (flag2 && GameUI.inst != null))
		{
			Color successColor = GameUI.inst.successColor;
			successColor.a = 1f;
			empty = "<color=#" + ColorUtility.ToHtmlStringRGBA(successColor) + ">";
			empty2 = "</color>";
		}
		else
		{
			Color failColor = GameUI.inst.failColor;
			failColor.a = 1f;
			empty = "<color=#" + ColorUtility.ToHtmlStringRGBA(failColor) + ">";
			empty2 = "</color>";
		}
		textMesh.text = string.Format("<size=4>{0}{1:+0.0;-0.0;0.0}<size=2> {2}{3}", empty, num2, LocalizationManager.GetTranslation("aqueductui_degrees"), empty2);
		Vector3 position3 = arcTopPoint + Vector3.up * 0.25f;
		Vector3 forward = Cam.inst.cam.transform.forward;
		forward.y = 0f;
		forward.Normalize();
		float num3 = Mathf.InverseLerp(0.6f, 0.9f, Mathf.Abs(Vector3.Dot(lineDirXZ, forward)));
		if (num3 > 0f)
		{
			textMesh.ForceMeshUpdate();
			float num4 = textMesh.GetRenderedValues(onlyVisibleCharacters: false).x * 0.5f;
			position3 += Cam.inst.cam.transform.right * (num3 * (num4 + 0.3f));
		}
		textMesh.transform.rotation = Quaternion.LookRotation(Cam.inst.transform.forward, Vector3.up);
		textMesh.transform.position = position3;
		this.lineRenderer.material.SetFloat("_LineLength", num * 3f);
		this.lineRenderer.material.SetFloat("_Speed", (!flag2) ? 1 : 2);
	}
}
