using UnityEngine;
using UnityEngine.UI;

public class HeroIcon : MonoBehaviour
{
	public Image untrainedImage;

	public Image trainedImage;

	public Image addIcon;

	private TooltipHook tipHook;

	private bool trained;

	private void Start()
	{
		tipHook = GetComponent<TooltipHook>();
	}

	public void SetTrained(bool trained)
	{
		if (trained != this.trained)
		{
			if (trained)
			{
				untrainedImage.gameObject.SetActive(value: false);
				addIcon.gameObject.SetActive(value: false);
				trainedImage.gameObject.SetActive(value: true);
			}
			else
			{
				untrainedImage.gameObject.SetActive(value: true);
				addIcon.gameObject.SetActive(value: true);
				tipHook.enabled = true;
				trainedImage.gameObject.SetActive(value: false);
			}
			this.trained = trained;
		}
	}

	public void UpdateIcon(bool trainingInGeneral, bool trainingThisHero)
	{
		if (trainingInGeneral & trainingThisHero)
		{
			addIcon.rectTransform.transform.Rotate(0f, 0f, Time.deltaTime * 90f);
		}
		else
		{
			addIcon.rectTransform.transform.rotation = Quaternion.identity;
		}
		tipHook.enabled = !(trained | trainingInGeneral);
	}

	public void SetTip(string str)
	{
		tipHook.toolTipText = str;
	}
}
