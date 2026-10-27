using UnityEngine;
using UnityEngine.Rendering;

public class TextOutline : MonoBehaviour
{
	public float pixelSize = 1f;

	public Color outlineColor = Color.black;

	public bool resolutionDependant;

	public int doubleResolution = 1024;

	private TextMesh textMesh;

	private MeshRenderer meshRenderer;

	private void Start()
	{
		textMesh = GetComponent<TextMesh>();
		meshRenderer = GetComponent<MeshRenderer>();
		for (int i = 0; i < 8; i++)
		{
			GameObject gameObject = new GameObject("outline", typeof(TextMesh));
			gameObject.transform.parent = transform;
			gameObject.transform.localScale = new Vector3(1f, 1f, 1f);
			MeshRenderer component = gameObject.GetComponent<MeshRenderer>();
			component.material = new Material(meshRenderer.material);
			component.shadowCastingMode = ShadowCastingMode.Off;
			component.receiveShadows = false;
			component.sortingLayerID = meshRenderer.sortingLayerID;
			component.sortingLayerName = meshRenderer.sortingLayerName;
		}
	}

	private void LateUpdate()
	{
		Vector3 vector = Camera.main.WorldToScreenPoint(transform.position);
		outlineColor.a = textMesh.color.a * textMesh.color.a;
		for (int i = 0; i < transform.childCount; i++)
		{
			TextMesh component = transform.GetChild(i).GetComponent<TextMesh>();
			component.color = outlineColor;
			component.text = textMesh.text;
			component.alignment = textMesh.alignment;
			component.anchor = textMesh.anchor;
			component.characterSize = textMesh.characterSize;
			component.font = textMesh.font;
			component.fontSize = textMesh.fontSize;
			component.fontStyle = textMesh.fontStyle;
			component.richText = textMesh.richText;
			component.tabSize = textMesh.tabSize;
			component.lineSpacing = textMesh.lineSpacing;
			component.offsetZ = textMesh.offsetZ + 0.3f;
			bool flag = resolutionDependant && (Screen.width > doubleResolution || Screen.height > doubleResolution);
			Vector3 vector2 = GetOffset(i) * (flag ? (2f * pixelSize) : pixelSize);
			Vector3 position = Camera.main.ScreenToWorldPoint(vector + vector2);
			component.transform.position = position;
			component.transform.rotation = transform.rotation;
			MeshRenderer component2 = transform.GetChild(i).GetComponent<MeshRenderer>();
			component2.sortingLayerID = meshRenderer.sortingLayerID;
			component2.sortingLayerName = meshRenderer.sortingLayerName;
		}
	}

	private Vector3 GetOffset(int i)
	{
		return (i % 8) switch
		{
			0 => new Vector3(0f, 1f, 0f), 
			1 => new Vector3(1f, 1f, 0f), 
			2 => new Vector3(1f, 0f, 0f), 
			3 => new Vector3(1f, -1f, 0f), 
			4 => new Vector3(0f, -1f, 0f), 
			5 => new Vector3(-1f, -1f, 0f), 
			6 => new Vector3(-1f, 0f, 0f), 
			7 => new Vector3(-1f, 1f, 0f), 
			_ => Vector3.zero, 
		};
	}
}
