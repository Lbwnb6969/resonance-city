using System.Collections.Generic;
using Assets.Code.Interface;
using Assets.Interface;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ResourceOrderFormUI : MonoBehaviour, IWorkerUIElement
{
	private class Order
	{
		public Transform parent;

		public TMP_InputField inputField;

		public TextMeshProUGUI currText;

		public Toggle nonSurplusPrivate;
	}

	public Transform orderLinePrefab;

	public Transform orderContainer;

	private List<Order> resourceOrders = new List<Order>();

	public TextMeshProUGUI currTxt;

	public TextMeshProUGUI maxTxt;

	public Transform lockIconTitle;

	private List<IResourceOrderable> orderables = new List<IResourceOrderable>();

	private IResourceOrderable orderable;

	private Timer updater = new Timer(1f);

	private void Awake()
	{
		for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[i];
			Transform transform = Object.Instantiate(orderLinePrefab, orderContainer, worldPositionStays: false);
			transform.GetChild(0).GetComponent<Image>().sprite = resourceDef.texture;
			transform.SetSiblingIndex(orderContainer.childCount - 2);
			Order order = new Order();
			order.parent = transform;
			order.inputField = transform.GetChild(1).GetComponent<TMP_InputField>();
			order.currText = transform.GetChild(2).GetComponent<TextMeshProUGUI>();
			order.nonSurplusPrivate = transform.GetChild(4).GetComponent<Toggle>();
			resourceOrders.Add(order);
			order.inputField.onSelect.AddListener((string val) =>
			{
				GameState.inst.AlphaNumericHotkeysEnabled = false;
			});
			order.inputField.onEndEdit.AddListener((string val) =>
			{
				GameState.inst.AlphaNumericHotkeysEnabled = true;
			});
			ConsoleUIItem component = order.inputField.GetComponent<ConsoleUIItem>();
			(component.right = order.nonSurplusPrivate.GetComponent<ConsoleUIItem>()).left = component;
			transform.gameObject.SetActive(value: true);
		}
	}

	public void UpdateForNewSelection()
	{
		if (resourceOrders.Count == 0)
		{
			return;
		}
		orderables.Clear();
		orderable = null;
		if (!GameUI.inst.GetBuildingSelected())
		{
			return;
		}
		int num = 0;
		GameUI.inst.GetBuildingSelected().GetComponents(orderables);
		int num2 = 0;
		if (num2 < orderables.Count)
		{
			lockIconTitle.gameObject.SetActive(orderables[num2].ShowLockNonSurplus());
			orderable = orderables[num2];
			for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
			{
				FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[i];
				IResourceStorage resourceStorage = orderable as IResourceStorage;
				if (resourceStorage.AcceptsType(resourceDef.ID))
				{
					resourceOrders[num].inputField.text = orderables[num2].DesiredResources.Get(resourceDef.ID).ToString();
					resourceOrders[num].nonSurplusPrivate.gameObject.SetActive(orderables[num2].ShowLockNonSurplus());
					if (resourceStorage != null && !resourceStorage.AcceptsType(resourceDef.ID))
					{
						resourceOrders[num].parent.gameObject.SetActive(value: false);
					}
					else
					{
						resourceOrders[num].parent.gameObject.SetActive(value: true);
					}
					resourceOrders[num].nonSurplusPrivate.isOn = orderables[num2].GetNonSurplusPrivate(resourceDef.ID);
					num++;
				}
			}
		}
		for (int num3 = resourceOrders.Count - 1; num3 >= num; num3--)
		{
			resourceOrders[num3].parent.gameObject.SetActive(value: false);
		}
		updater.ForceExpire();
		ConsoleUIItem consoleUIItem = null;
		ConsoleUIItem consoleUIItem2 = null;
		ConsoleUIItem consoleUIItem3 = null;
		ConsoleUIItem consoleUIItem4 = null;
		for (int j = 0; j < resourceOrders.Count; j++)
		{
			if (resourceOrders[j].parent.gameObject.activeSelf)
			{
				consoleUIItem4 = resourceOrders[j].inputField.GetComponent<ConsoleUIItem>();
				consoleUIItem2 = resourceOrders[j].nonSurplusPrivate.GetComponent<ConsoleUIItem>();
				if (consoleUIItem3 != null)
				{
					consoleUIItem3.bottom = consoleUIItem4;
				}
				consoleUIItem4.top = consoleUIItem3;
				consoleUIItem3 = consoleUIItem4;
				if (consoleUIItem != null)
				{
					consoleUIItem.bottom = consoleUIItem2;
				}
				consoleUIItem2.top = consoleUIItem;
				consoleUIItem = consoleUIItem2;
			}
		}
	}

	void IWorkerUIElement.TryShow()
	{
	}

	public bool CanShow()
	{
		return GameUI.inst.SelectedBuildingIs<IResourceOrderable>();
	}

	public void OnDisable()
	{
		orderable = null;
	}

	public void OnEnable()
	{
		orderable = null;
	}

	private void Update()
	{
	}
}
