using I2.Loc;
using Steamworks;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class WorkshopItem : MonoBehaviour, IPointerDownHandler, IEventSystemHandler
{
	public delegate void ClickReturn(WorkshopItem me);

	public TextMeshProUGUI title;

	public TextMeshProUGUI description;

	public RawImage image;

	public GameObject highlightEffect;

	public PublishedFileId_t fileId;

	public string workshopItemUrl;

	public WWW loadImageRequest;

	public int version;

	public ClickReturn clickReturn;

	public ClickReturn unsub;

	public ClickReturn goToItem;

	public Button unsubButton;

	public Button goToItemButton;

	public GameObject loaded;

	public GameObject restart;

	public GameObject invalidVersion;

	public TextMeshProUGUI modVersion;

	public ERemoteStoragePublishedFileVisibility visibility;

	public string[] tags = new string[0];

	public void SetClickReturn(ClickReturn ret, ClickReturn unsub, ClickReturn goToItem)
	{
		clickReturn = ret;
		this.unsub = unsub;
		this.goToItem = goToItem;
	}

	public void SetTags(string[] tags)
	{
		this.tags = tags;
	}

	public void SetVisibility(ERemoteStoragePublishedFileVisibility visibility)
	{
		this.visibility = visibility;
	}

	public void OnPointerDown(PointerEventData eventData)
	{
		clickReturn(this);
	}

	public void SetLoaded(GameWorkshopUI.LoadedMod loadState)
	{
		if (loadState == null)
		{
			loaded.SetActive(value: false);
			restart.SetActive(value: true);
			modVersion.gameObject.SetActive(value: true);
			modVersion.SetText(LocalizationManager.GetTranslation("ModVersion") ?? "", 1f);
		}
		else if (!loadState.validVersion)
		{
			invalidVersion.SetActive(value: true);
			modVersion.gameObject.SetActive(value: true);
			modVersion.SetText("<color=orange>" + LocalizationManager.GetTranslation("ModVersion"), loadState.version);
		}
		else
		{
			loaded.SetActive(loadState.loaded);
			restart.SetActive(!loadState.loaded);
			modVersion.gameObject.SetActive(value: true);
			modVersion.SetText(LocalizationManager.GetTranslation("ModVersion") ?? "", loadState.version);
		}
	}

	public void SetHighlighted(bool highlighted)
	{
		highlightEffect.SetActive(highlighted);
	}

	private void Start()
	{
		if (unsubButton != null)
		{
			unsubButton.onClick.AddListener(OnUnsub);
			if (goToItemButton != null)
			{
				goToItemButton.onClick.AddListener(OnGoToItem);
			}
		}
	}

	private void OnUnsub()
	{
		unsub(this);
	}

	private void OnGoToItem()
	{
		goToItem(this);
	}

	private void Update()
	{
		if (loadImageRequest != null && loadImageRequest.isDone)
		{
			if (loadImageRequest.texture != null)
			{
				image.texture = loadImageRequest.texture;
				image.GetComponent<AspectRatioFitter>().aspectRatio = (float)image.texture.width / (float)image.texture.height;
			}
			loadImageRequest = null;
		}
	}
}
