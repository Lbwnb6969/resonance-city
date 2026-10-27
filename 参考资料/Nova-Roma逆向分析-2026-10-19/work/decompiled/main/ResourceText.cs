using TMPro;
using UnityEngine;

public class ResourceText : PooledObject
{
	private GameObject text;

	private Transform container;

	public void Awake()
	{
		text = Object.Instantiate(Resources.Load("Resource")) as GameObject;
		text.transform.SetParent(transform);
		text.transform.localPosition = Vector3.zero;
	}

	public ResourceText Create(string txt)
	{
		ResourceText resourceText = Alloc(Vector3.zero) as ResourceText;
		resourceText.text.GetComponent<TextMeshPro>().text = txt;
		LookAtCamera(resourceText.text.transform);
		resourceText.SetAlpha(1f);
		return resourceText;
	}

	public void SetAlpha(float a)
	{
		Color color = text.GetComponent<TextMeshPro>().color;
		color.a = a;
		text.GetComponent<TextMeshPro>().color = color;
	}

	public void SetText(string str)
	{
		text.GetComponent<TextMeshPro>().text = str;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		LookAtCamera(text.transform);
	}

	public void LookAtCamera(Transform trans)
	{
		trans.rotation = Quaternion.LookRotation(trans.position - Cam.inst.transform.position, Vector3.up);
	}
}
