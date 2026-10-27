using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class BetterDropdownItem : MonoBehaviour, IPointerEnterHandler, IEventSystemHandler, ICancelHandler
{
	[SerializeField]
	private TMP_Text m_Text;

	[SerializeField]
	private Localize m_Localize;

	[SerializeField]
	private Image m_Image;

	[SerializeField]
	private RectTransform m_RectTransform;

	[SerializeField]
	private Toggle m_Toggle;

	public TMP_Text text
	{
		get
		{
			return m_Text;
		}
		set
		{
			m_Text = value;
		}
	}

	public Localize localize
	{
		get
		{
			return m_Localize;
		}
		set
		{
			m_Localize = value;
		}
	}

	public Image image
	{
		get
		{
			return m_Image;
		}
		set
		{
			m_Image = value;
		}
	}

	public RectTransform rectTransform
	{
		get
		{
			return m_RectTransform;
		}
		set
		{
			m_RectTransform = value;
		}
	}

	public Toggle toggle
	{
		get
		{
			return m_Toggle;
		}
		set
		{
			m_Toggle = value;
		}
	}

	public virtual void OnPointerEnter(PointerEventData eventData)
	{
		EventSystem.current.SetSelectedGameObject(gameObject);
	}

	public virtual void OnCancel(BaseEventData eventData)
	{
		TMP_Dropdown componentInParent = GetComponentInParent<TMP_Dropdown>();
		if ((bool)componentInParent)
		{
			componentInParent.Hide();
		}
	}
}
