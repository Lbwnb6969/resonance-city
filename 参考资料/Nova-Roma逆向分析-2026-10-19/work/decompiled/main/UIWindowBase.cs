using UnityEngine;

public class UIWindowBase : MonoBehaviour
{
	public bool animateScale = true;

	protected RectTransform rectT;

	protected bool visible;

	protected float time;

	public bool Visible => visible;

	private void Awake()
	{
		rectT = GetComponent<RectTransform>();
		AwakeInternal();
	}

	private void Start()
	{
		StartInternal();
	}

	public virtual void SetVisible(bool v)
	{
		visible = v;
		if (!visible)
		{
			gameObject.SetActive(value: false);
		}
		else
		{
			gameObject.SetActive(value: true);
		}
		if (animateScale)
		{
			time = 0f;
			if (!rectT)
			{
				rectT = GetComponent<RectTransform>();
			}
			rectT.localScale = Vector3.zero;
		}
	}

	public void Close()
	{
		SfxSystem.inst.PlayFromBank("ui_Window_Close", Camera.main.transform.position);
		SetVisible(v: false);
	}

	public virtual void AwakeInternal()
	{
	}

	public virtual void StartInternal()
	{
	}

	public virtual void UpdateInternal(float dt)
	{
	}

	private void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		UpdateInternal(unscaledDeltaTime);
		if (animateScale)
		{
			time += Time.unscaledDeltaTime * 6f;
			if (time > 1f)
			{
				time = 1f;
			}
			float num = GameUI.inst.scaleInCurve.Evaluate(time);
			rectT.localScale = new Vector3(num, num, num);
		}
	}
}
