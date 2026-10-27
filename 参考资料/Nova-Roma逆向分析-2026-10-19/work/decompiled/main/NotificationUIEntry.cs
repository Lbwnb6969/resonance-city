using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class NotificationUIEntry : MonoBehaviour, ICamTrackable
{
	public GameObject titleContainer;

	public TextMeshProUGUI titleTMP;

	public GameObject messageContainer;

	public TextMeshProUGUI messageTMP;

	public Button btn;

	[NonSerialized]
	public GameObject focusedObj;

	[NonSerialized]
	public Vector3 focusedPos;

	[NonSerialized]
	public ICamTrackable focusedTrackable;

	[NonSerialized]
	public int groupID;

	[NonSerialized]
	public string id;

	[NonSerialized]
	public NotificationStatus status;

	public RawImage flashImage;

	[NonSerialized]
	public float flashDuration;

	[NonSerialized]
	public Color flashColor;

	private void Awake()
	{
		btn.onClick.AddListener(SetFocusTarget);
	}

	public Vector3 GetDesiredTrackingPos()
	{
		if ((bool)focusedObj)
		{
			focusedPos = focusedObj.transform.position;
		}
		return focusedPos;
	}

	private void SetFocusTarget()
	{
		if (!focusedTrackable.IsNull())
		{
			Cam.inst.Track(focusedTrackable);
		}
		else
		{
			Cam.inst.Track(this);
		}
	}
}
