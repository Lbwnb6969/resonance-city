using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class BannerTile : MonoBehaviour, IPointerDownHandler, IEventSystemHandler
{
	public RawImage image;

	public GameObject border;

	private ChooseBannerUI reference;

	public bool isWorkshopReady;

	public bool canUpload;

	public string workshopUrl;

	public GameObject uploadArrow;

	public GameObject uploadCheckmark;

	public void OnEnable()
	{
		uploadArrow.SetActive(value: false);
		uploadCheckmark.SetActive(value: false);
	}

	public void OnPointerDown(PointerEventData eventData)
	{
		SfxSystem.PlayUiSelect();
		reference.HighlightBannerTile(this);
	}

	public void GiveBannerUIRef(ChooseBannerUI reference)
	{
		this.reference = reference;
	}

	public void SetTexture(Texture2D texture)
	{
		image.texture = texture;
	}

	public void SetWorkshopState(bool isWorkshopReady, bool canUpload, bool showIcon = true, string workshopUrl = "")
	{
		this.isWorkshopReady = isWorkshopReady;
		this.canUpload = canUpload;
		this.workshopUrl = workshopUrl;
		if (!this.isWorkshopReady)
		{
			return;
		}
		if (showIcon)
		{
			if (canUpload)
			{
				uploadArrow.SetActive(value: true);
				uploadCheckmark.SetActive(value: false);
			}
			else
			{
				uploadArrow.SetActive(value: false);
				uploadCheckmark.SetActive(value: true);
			}
		}
		else
		{
			uploadArrow.SetActive(value: false);
			uploadCheckmark.SetActive(value: false);
		}
	}

	public void SetHighlight(bool show)
	{
		border.SetActive(show);
	}
}
