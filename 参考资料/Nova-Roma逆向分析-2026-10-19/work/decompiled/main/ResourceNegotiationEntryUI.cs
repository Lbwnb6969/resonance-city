using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class ResourceNegotiationEntryUI : MonoBehaviour, IPointerEnterHandler, IEventSystemHandler, IPointerExitHandler
{
	private Slider slider;

	public GameObject veryhappyFace;

	public GameObject happyFace;

	public GameObject neutralFace;

	public GameObject angryFace;

	public GameObject veryAngryFace;

	private void Start()
	{
		slider = GetComponentInChildren<Slider>();
		SetFaceColor(new Color(1f, 1f, 1f, 0.5f));
	}

	private void Update()
	{
		veryhappyFace.SetActive(value: false);
		happyFace.SetActive(value: false);
		neutralFace.SetActive(value: false);
		angryFace.SetActive(value: false);
		veryAngryFace.SetActive(value: false);
		if (slider.value == 1f)
		{
			veryhappyFace.SetActive(value: true);
		}
		if (slider.value > 1f && slider.value <= 2f)
		{
			happyFace.SetActive(value: true);
		}
		else if (slider.value > 2f && slider.value <= 5f)
		{
			neutralFace.SetActive(value: true);
		}
		else if (slider.value > 5f && slider.value <= 8f)
		{
			angryFace.SetActive(value: true);
		}
		else
		{
			veryAngryFace.SetActive(value: true);
		}
	}

	public void OnPointerEnter(PointerEventData eventData)
	{
		GetComponent<Image>().enabled = true;
		SetFaceColor(new Color(1f, 1f, 1f, 1f));
	}

	private void SetFaceColor(Color col)
	{
		veryAngryFace.GetComponent<Image>().color = col;
		angryFace.GetComponent<Image>().color = col;
		neutralFace.GetComponent<Image>().color = col;
		happyFace.GetComponent<Image>().color = col;
		veryhappyFace.GetComponent<Image>().color = col;
	}

	public void OnPointerExit(PointerEventData eventData)
	{
		GetComponent<Image>().enabled = false;
		SetFaceColor(new Color(1f, 1f, 1f, 0.5f));
	}
}
