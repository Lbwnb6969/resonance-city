using UnityEngine;
using UnityEngine.UI;

public class MiniMapUIPing : MonoBehaviour
{
	public Vector3 mapPos;

	public RectTransform rect;

	public Image image;

	public Color color = Color.white;

	public bool continues;

	public bool animate = true;

	public int maxflashCount = 1;

	public int currFlash;

	public float duration;

	public float pingSpeed = 1f;

	public float pingOpacityStrength = 1f;

	public float pingScaleStrength = 2f;

	public AnimationCurve pingOpacity;

	public AnimationCurve pingScale;
}
