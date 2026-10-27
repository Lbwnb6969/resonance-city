using UnityEngine;
using UnityEngine.Rendering;

public class MapSelectionGizmo
{
	public const float ScaleGripSize = 0.22f;

	public const float ScaleAxisLength = 5.9f;

	public const float ScaleArrowLength = 1.2f;

	public const float JoystickLength = 4f;

	public const float RotationRingSize = 3f;

	private static readonly Color TranslationColor = new Color32(242, 244, 247, byte.MaxValue);

	private static readonly Color RotationColor = new Color32(byte.MaxValue, 120, 102, byte.MaxValue);

	private static readonly Color ScaleColor = new Color32(96, 181, byte.MaxValue, byte.MaxValue);

	private static readonly Color HotColor = new Color(1f, 0.85f, 0.2f);

	private readonly Transform[] quads = new Transform[14];

	private readonly Material[] materials = new Material[14];

	private static readonly int[] GuideDrawOrder = new int[3] { 10, 0, 1 };

	private readonly int[] handleDrawOrder = new int[7] { 11, 12, 13, 4, 3, 5, 2 };

	private CommandBuffer drawCommands;

	private Camera renderCamera;

	private GameObject root;

	private Mesh mesh;

	public void Hide()
	{
		drawCommands?.Clear();
		if (root != null)
		{
			root.SetActive(value: false);
		}
	}

	public void Destroy()
	{
		if (renderCamera != null && drawCommands != null)
		{
			renderCamera.RemoveCommandBuffer(CameraEvent.AfterImageEffects, drawCommands);
		}
		drawCommands?.Release();
		drawCommands = null;
		renderCamera = null;
		if (!(root == null))
		{
			Object.Destroy(root);
			Object.Destroy(mesh);
			Material[] array = materials;
			for (int i = 0; i < array.Length; i++)
			{
				Object.Destroy(array[i]);
			}
			root = null;
		}
	}

	private void Ensure()
	{
		if (!(root != null))
		{
			root = new GameObject("MapSelectionGizmo");
			mesh = new Mesh
			{
				vertices = new Vector3[4]
				{
					new Vector3(-0.5f, -0.5f, 0f),
					new Vector3(0.5f, -0.5f, 0f),
					new Vector3(0.5f, 0.5f, 0f),
					new Vector3(-0.5f, 0.5f, 0f)
				},
				uv = new Vector2[4]
				{
					Vector2.zero,
					Vector2.right,
					Vector2.one,
					Vector2.up
				},
				triangles = new int[6] { 0, 1, 2, 0, 2, 3 }
			};
			mesh.RecalculateBounds();
			Shader shader = Resources.Load<Shader>("MapGizmoShape");
			for (int i = 0; i < quads.Length; i++)
			{
				GameObject gameObject = new GameObject("Handle" + i);
				gameObject.transform.SetParent(root.transform, worldPositionStays: false);
				gameObject.AddComponent<MeshFilter>().sharedMesh = mesh;
				MeshRenderer meshRenderer = gameObject.AddComponent<MeshRenderer>();
				meshRenderer.enabled = false;
				materials[i] = new Material(shader);
				meshRenderer.sharedMaterial = materials[i];
				meshRenderer.shadowCastingMode = ShadowCastingMode.Off;
				meshRenderer.receiveShadows = false;
				quads[i] = gameObject.transform;
			}
		}
	}

	public void Render(Camera cam)
	{
		if (drawCommands == null)
		{
			drawCommands = new CommandBuffer
			{
				name = "Map transform handles"
			};
		}
		if (renderCamera != cam)
		{
			if (renderCamera != null)
			{
				renderCamera.RemoveCommandBuffer(CameraEvent.AfterImageEffects, drawCommands);
			}
			renderCamera = cam;
			renderCamera.AddCommandBuffer(CameraEvent.AfterImageEffects, drawCommands);
		}
		drawCommands.Clear();
		int[] guideDrawOrder = GuideDrawOrder;
		foreach (int index in guideDrawOrder)
		{
			DrawQuad(index);
		}
		for (int j = 1; j < handleDrawOrder.Length; j++)
		{
			int num = handleDrawOrder[j];
			float num2 = HandleDepth(cam, quads[num].position);
			int num3 = j - 1;
			while (num3 >= 0 && HandleDepth(cam, quads[handleDrawOrder[num3]].position) < num2)
			{
				handleDrawOrder[num3 + 1] = handleDrawOrder[num3];
				num3--;
			}
			handleDrawOrder[num3 + 1] = num;
		}
		guideDrawOrder = handleDrawOrder;
		foreach (int index2 in guideDrawOrder)
		{
			DrawQuad(index2);
		}
	}

	private void DrawQuad(int index)
	{
		Transform transform = quads[index];
		if (transform.gameObject.activeInHierarchy)
		{
			drawCommands.DrawMesh(mesh, transform.localToWorldMatrix, materials[index], 0, 0);
		}
	}

	public static float HandleDepth(Camera cam, Vector3 position)
	{
		return Vector3.Dot(position - cam.transform.position, cam.transform.forward);
	}

	public static Vector3 Axis(int index)
	{
		return index switch
		{
			1 => Vector3.up, 
			0 => Vector3.right, 
			_ => Vector3.forward, 
		};
	}

	public static float ScaleHandleDistance(int axis)
	{
		if (axis != 1)
		{
			return 4.3f;
		}
		return 5.3f;
	}

	public static Vector3 ScaleHandleAxis(Camera cam, Vector3 center, Quaternion orientation, int axis, float s)
	{
		Vector3 vector = orientation * Axis(axis);
		if (axis != 1 && cam.WorldToScreenPoint(center + vector * s).y > cam.WorldToScreenPoint(center).y)
		{
			vector = -vector;
		}
		return vector;
	}

	public static Quaternion RingRotation(int index)
	{
		return Quaternion.LookRotation(Axis(index), Axis((index + 1) % 3));
	}

	public static Vector3 BeadPosition(Vector3 center, float length)
	{
		return center + Vector3.up * length * 0.5f;
	}

	public static Quaternion BeadRotation(Camera cam, Vector3 position)
	{
		return BillboardRotation(cam, position, Vector3.up);
	}

	public static Quaternion BillboardRotation(Camera cam, Vector3 position, Vector3 axis)
	{
		Vector2 vector = cam.WorldToScreenPoint(position + axis * ScreenScale(cam, position)) - cam.WorldToScreenPoint(position);
		float angle = ((vector.sqrMagnitude > 0.001f) ? (Mathf.Atan2(0f - vector.x, vector.y) * 57.29578f) : 0f);
		return cam.transform.rotation * Quaternion.AngleAxis(angle, Vector3.forward);
	}

	public static float ScreenScale(Camera cam, Vector3 center)
	{
		Vector3 vector = cam.WorldToScreenPoint(center);
		return Vector3.Distance(cam.ScreenToWorldPoint(vector), cam.ScreenToWorldPoint(vector + Vector3.right * 36f));
	}

	private void Draw(int index, Vector3 position, Quaternion rotation, Vector2 size, float shape, Color color, float s)
	{
		Transform obj = quads[index];
		obj.gameObject.SetActive(value: true);
		obj.SetPositionAndRotation(position, rotation);
		obj.localScale = new Vector3(size.x, size.y, 1f);
		Material obj2 = materials[index];
		obj2.SetFloat("_Shape", shape);
		obj2.SetColor("_Color", color);
		obj2.SetColor("_OutlineColor", new Color(0f, 0f, 0f, color.a));
		obj2.SetVector("_QuadSize", new Vector4(size.x, size.y, 0f, 0f));
		obj2.SetFloat("_HalfWidth", 0.055f * s);
		obj2.SetFloat("_Outline", 0.035f * s);
		obj2.SetFloat("_HeadW", 0.23f * s);
		obj2.SetFloat("_HeadL", 0.3f * s);
		obj2.SetFloat("_DiamondHalf", 0.22f * s);
		obj2.SetFloat("_DashLength", 0.4f * s);
	}

	private static Color HandleColor(int index, int hot, bool dragging)
	{
		Color result;
		if (index == hot)
		{
			result = HotColor;
		}
		else if (index >= 6)
		{
			result = ScaleColor;
		}
		else
		{
			result = ((index == 1 || index == 3) ? RotationColor : TranslationColor);
		}
		result.a = ((dragging && index != hot) ? 0.2f : 0.95f);
		return result;
	}

	public void UpdateLayout(Camera cam, Vector3 center, Vector3 knobDirection, float length, float s, Quaternion orientation, int hot, bool dragging)
	{
		Ensure();
		root.SetActive(value: true);
		Transform[] array = quads;
		for (int i = 0; i < array.Length; i++)
		{
			array[i].gameObject.SetActive(value: false);
		}
		Color color = HandleColor(1, hot, dragging);
		float num = 3f * s;
		Vector3 vector = orientation * Vector3.up;
		Vector3 lhs = (cam.orthographic ? cam.transform.forward : (center - cam.transform.position).normalized);
		float num2 = 0.2f * s / Mathf.Max(0.05f, Mathf.Abs(Vector3.Dot(lhs, vector)));
		Draw(0, center, orientation * RingRotation(1), Vector2.one * (num + num2) * 2f, 3f, color, s);
		materials[0].SetFloat("_ArcRadius", num);
		Color color2 = HandleColor(3, hot, dragging);
		if (!dragging && hot != 3)
		{
			color2.a = 0.45f;
		}
		DrawLine(1, cam, center, center + vector * length, color2, s, dashed: false);
		Draw(2, center + vector * length, cam.transform.rotation, Vector2.one * 0.85f * s, 6f, HandleColor(3, hot, dragging), s);
		materials[2].SetFloat("_DiamondHalf", 0.32f * s);
		Vector3 position = BeadPosition(center, length);
		Draw(3, position, BeadRotation(cam, position), new Vector2(0.65f, 1.4000001f) * s, 0f, HandleColor(4, hot, dragging), s);
		materials[3].SetFloat("_ArrowLen", 1.2f * s);
		Draw(4, center, cam.transform.rotation, Vector2.one * 0.8f * s, 5f, HandleColor(9, hot, dragging), s);
		materials[4].SetFloat("_DiamondHalf", 0.3f * s);
		if (dragging && hot == 1)
		{
			Draw(5, center + knobDirection * num, cam.transform.rotation, Vector2.one * 0.8f * s, 6f, HandleColor(1, hot, dragging), s);
			materials[5].SetFloat("_DiamondHalf", 0.28f * s);
		}
		for (int j = 0; j < 3; j++)
		{
			Color color3 = HandleColor(j + 6, hot, dragging);
			Vector3 vector2 = ScaleHandleAxis(cam, center, orientation, j, s);
			Vector3 vector3 = center + vector2 * (ScaleHandleDistance(j) * s);
			Quaternion rotation = BillboardRotation(cam, vector3, vector2);
			float num3 = ScreenScale(cam, vector3);
			Draw(11 + j, vector3, rotation, new Vector2(0.65f, 1.4000001f) * num3, 12f, color3, num3);
			materials[11 + j].SetFloat("_ArrowLen", 1.2f * num3);
		}
	}

	private void DrawLine(int index, Camera cam, Vector3 from, Vector3 to, Color color, float s, bool dashed)
	{
		Vector3 vector = to - from;
		float magnitude = vector.magnitude;
		if (!(magnitude < 0.001f))
		{
			Vector3 vector2 = vector / magnitude;
			Vector3 lhs = Vector3.Cross(vector2, cam.transform.position - (from + to) * 0.5f);
			if (lhs.sqrMagnitude < 0.0001f)
			{
				lhs = Vector3.Cross(vector2, cam.transform.up);
			}
			Quaternion rotation = Quaternion.LookRotation(Vector3.Cross(lhs, vector2), vector2);
			Draw(index, (from + to) * 0.5f, rotation, new Vector2(0.2f * s, magnitude), dashed ? 8f : 4f, color, s);
		}
	}

	public void DrawDragGuide(Camera cam, Vector3 center, Vector3 ground, float s, int active)
	{
		if (active == 4 || active == 5)
		{
			DrawLine(10, cam, ground, center, Color.white, s, dashed: true);
		}
	}
}
