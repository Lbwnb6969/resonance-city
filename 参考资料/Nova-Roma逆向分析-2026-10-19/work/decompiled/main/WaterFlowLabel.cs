using TMPro;
using UnityEngine;

public class WaterFlowLabel : MonoBehaviour
{
	[Tooltip("The number text rendered inside the bubble.")]
	public TextMeshPro text;

	[Tooltip("Background bubble sprite that sits behind the text.")]
	public SpriteRenderer background;

	[Tooltip("Child that gets the constant-screen-size scaling (text + bubble live under here). Anything parented to the ROOT instead (e.g. a fixed-size pointer sphere) keeps its authored world size. If unset, the whole root is scaled (old behaviour).")]
	public Transform scaledContent;

	[Header("Priority badges (corner)")]
	[Tooltip("Authored badge object shown only while this hub is High priority; hidden otherwise. Optional.")]
	public GameObject highPriorityBadge;

	[Tooltip("Authored badge object shown only while this hub is Low priority; hidden otherwise. Optional.")]
	public GameObject lowPriorityBadge;

	public void Place(Vector3 worldPos, Camera cam, float scale, Vector3 alongDirection = default(Vector3))
	{
		Transform transform = base.transform;
		transform.position = worldPos;
		Transform transform2 = ((scaledContent != null) ? scaledContent : transform);
		transform2.rotation = Quaternion.LookRotation(transform2.position - cam.transform.position, Vector3.up);
		transform2.localScale = new Vector3(scale, scale, scale);
		if (background != null)
		{
			background.transform.localRotation = BackgroundRotation(transform2, alongDirection);
		}
	}

	private Quaternion BackgroundRotation(Transform content, Vector3 alongDirection)
	{
		if (alongDirection.sqrMagnitude < 1E-06f)
		{
			return Quaternion.identity;
		}
		float num = Vector3.Dot(alongDirection, content.right);
		float num2 = Vector3.Dot(alongDirection, content.up);
		if (num * num + num2 * num2 < 1E-06f)
		{
			return Quaternion.identity;
		}
		float z = Mathf.Atan2(num2, num) * 57.29578f;
		return Quaternion.Euler(0f, 0f, z);
	}

	public void SetText(string value)
	{
		if (text != null)
		{
			text.text = value;
		}
	}

	public void SetPriority(WaterPriority priority)
	{
		Show(highPriorityBadge, priority == WaterPriority.High);
		Show(lowPriorityBadge, priority == WaterPriority.Low);
	}

	private static void Show(GameObject go, bool active)
	{
		if (go != null && go.activeSelf != active)
		{
			go.SetActive(active);
		}
	}
}
