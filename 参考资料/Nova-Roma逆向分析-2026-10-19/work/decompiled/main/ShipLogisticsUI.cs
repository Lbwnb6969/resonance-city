using System;
using System.Collections.Generic;
using Assets.Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

public class ShipLogisticsUI : UIWindowBase
{
	public static int poolCount = 0;

	public static ArrayExt<LogisticsDestUI> destPool = new ArrayExt<LogisticsDestUI>(50);

	public static ArrayExt<LogisticsDestUI> destActive = new ArrayExt<LogisticsDestUI>(25);

	public static ShipLogisticsUI inst;

	public DockRouteCursorMode cursorMode;

	public Mesh straightMesh;

	public Mesh cornerMesh;

	public Mesh arrowMesh;

	public Mesh crossMesh;

	public Material pathMaterial;

	public Material crossMat;

	public TextMeshProUGUI logsiticsErrorText;

	public GameObject logsiticsError;

	public Transform windowDesc;

	public Color[] shipRouteColors;

	public Color[] cartRouteColors;

	private bool deferTitleTextInteractibleFalse;

	public GameObject holdLineItem;

	public Button viewHold;

	public Button closeHold;

	public Button editTitleButton;

	public Transform destinationPrefab;

	public Transform destinationsContainer;

	public Transform resourceEntryPrefab;

	private LogisticsDestUI deferredDelete;

	public Transform strongerSails;

	public TMP_InputField shipName;

	public ILogisticTransport transport;

	public Toggle play;

	public Toggle pause;

	public Transform holdContainer;

	public Toggle repeatToggle;

	public Toggle stopToggle;

	public Transform error;

	public TextMeshProUGUI helperText;

	public TextMeshProUGUI behaviorText;

	public TextMeshProUGUI statusText;

	public Slider routeCycleSlider;

	public TextMeshProUGUI routeEveryYearsText;

	public Transform pauseHighlight;

	public TextMeshProUGUI holdCurrTxt;

	public TextMeshProUGUI holdMaxTxt;

	public Localize deleteLoc;

	public Scrollbar verticalScrollbar;

	public Button addStartNodeBtn;

	public Button addEndNodeBtn;

	public GameObject editRouteContainer;

	public ConsoleUIItem editRouteBtnItem;

	public ConsoleUIItem entryItem;

	public GameObject consoleClose;

	public GameObject pcClose;

	public GameObject consoleEditName;

	public GameObject pcEditName;

	public GameObject borderHighlight;

	public GameObject overlay;

	internal bool inEditRouteMode;

	internal bool overTrash;

	public GameObject trashButton;

	private ArrayExt<Renderer> normal = new ArrayExt<Renderer>(1000);

	private ArrayExt<Renderer> highlight = new ArrayExt<Renderer>(1000);

	private static List<Cell> visited = new List<Cell>();

	private static List<Cell> openSet = new List<Cell>();

	public void OnClickedEditRoute()
	{
		inEditRouteMode = true;
		if (GamepadControl.inst.isControllerActive)
		{
			borderHighlight.SetActive(value: false);
			overlay.SetActive(value: true);
		}
	}

	public void OnFocusedEditRoute()
	{
		inEditRouteMode = false;
		if (GamepadControl.inst.isControllerActive)
		{
			borderHighlight.SetActive(value: true);
			overlay.SetActive(value: false);
		}
	}

	public void PointerEnter()
	{
		trashButton.transform.GetChild(0).gameObject.SetActive(value: false);
		trashButton.transform.GetChild(1).gameObject.SetActive(value: true);
		overTrash = true;
	}

	public void PointerExit()
	{
		trashButton.transform.GetChild(0).gameObject.SetActive(value: true);
		trashButton.transform.GetChild(1).gameObject.SetActive(value: false);
		overTrash = false;
	}

	public void ConsoleUIUpdate(bool isControllerActive)
	{
		consoleClose.SetActive(isControllerActive);
		pcClose.SetActive(!isControllerActive);
		editRouteContainer.SetActive(isControllerActive);
		consoleEditName.SetActive(isControllerActive);
		pcEditName.SetActive(!isControllerActive);
		trashButton.SetActive(!isControllerActive);
		overlay.SetActive(value: false);
		borderHighlight.SetActive(isControllerActive);
		if (!isControllerActive)
		{
			inEditRouteMode = false;
		}
	}

	public void LandCartMasking(CommandBuffer buffer, Material maskingMaterial, RenderTexture rTexture)
	{
		buffer.Clear();
		buffer.SetRenderTarget(rTexture);
		buffer.ClearRenderTarget(clearDepth: true, clearColor: true, Color.clear);
		int landMassIdx = World.inst.GetCellDataClamped((transport as MonoBehaviour).transform.position).landMassIdx;
		if (normal.Count == 0 && highlight.Count == 0)
		{
			normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>((transport as MonoBehaviour).gameObject));
			WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.dockHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(normal, World.roadHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(normal, World.stoneRoadHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(normal, World.woodBridgeHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(normal, World.stoneBridgeHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(normal, World.gardenHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(normal, World.townsquareHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.largeStockpileHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.smallstockpileHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.smallGranaryHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.granaryHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.marketHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.smallMarketHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.produceStandHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.butcherHash, landMassIdx);
			WorldMask.AddBuildingsOfTypeOnLandmass(highlight, World.fishMongerHash, landMassIdx);
			normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(GameUI.inst.CellHighlighter.gameObject));
		}
		for (int i = 0; i < normal.Count; i++)
		{
			if (normal.data[i].gameObject.activeInHierarchy)
			{
				buffer.DrawRenderer(normal.data[i], maskingMaterial, 0, 1);
			}
		}
		for (int j = 0; j < highlight.Count; j++)
		{
			if (highlight.data[j].gameObject.activeInHierarchy)
			{
				buffer.DrawRenderer(highlight.data[j], maskingMaterial, 0, 2);
			}
		}
		cursorMode.DrawWithCommandBufer(buffer, maskingMaterial, 1);
	}

	public void ShipMasking(CommandBuffer buffer, Material maskingMaterial, RenderTexture rTexture)
	{
		buffer.Clear();
		buffer.SetRenderTarget(rTexture);
		buffer.ClearRenderTarget(clearDepth: true, clearColor: true, Color.clear);
		if (normal.Count == 0 && highlight.Count == 0)
		{
			WorldMask.AddBuildingsOfType(highlight, World.dockHash);
			normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>((transport as MonoBehaviour).gameObject));
			normal.AddRange(Util.ComponentsInNodeAndAllDescendants<Renderer>(GameUI.inst.CellHighlighter.gameObject));
		}
		for (int i = 0; i < normal.Count; i++)
		{
			if (normal.data[i].gameObject.activeInHierarchy)
			{
				buffer.DrawRenderer(normal.data[i], maskingMaterial, 0, 1);
			}
		}
		for (int j = 0; j < highlight.Count; j++)
		{
			if (highlight.data[j].gameObject.activeInHierarchy)
			{
				buffer.DrawRenderer(highlight.data[j], maskingMaterial, 0, 2);
			}
		}
		cursorMode.DrawWithCommandBufer(buffer, maskingMaterial, 1);
	}

	public void Awake()
	{
		inst = this;
		TryInitCursorMode();
		viewHold.onClick.AddListener(() =>
		{
			holdContainer.gameObject.SetActive(!holdContainer.gameObject.activeSelf);
			if (holdContainer.gameObject.activeSelf)
			{
				SfxSystem.PlayUiSelect();
			}
			else
			{
				SfxSystem.PlayUiCancel();
			}
		});
		closeHold.onClick.AddListener(() =>
		{
			holdContainer.gameObject.SetActive(value: false);
			SfxSystem.PlayUiCancel();
		});
		for (int num = 0; num < FreeResourceSystem.inst.resourceDefs.Count; num++)
		{
			GameObject gameObject = UnityEngine.Object.Instantiate(holdLineItem);
			gameObject.transform.SetParent(holdContainer, worldPositionStays: false);
			gameObject.GetComponent<RectTransform>().anchoredPosition3D = new Vector3(0f, 0f, 0f);
			gameObject.gameObject.SetActive(value: false);
			gameObject.transform.SetSiblingIndex(holdContainer.transform.childCount - 2);
		}
		shipName.onSelect.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = false;
		});
		shipName.onEndEdit.AddListener((string val) =>
		{
			transport.SetTransportName(val);
			GameState.inst.AlphaNumericHotkeysEnabled = true;
			deferTitleTextInteractibleFalse = true;
		});
		editTitleButton.onClick.AddListener(() =>
		{
			shipName.interactable = !shipName.interactable;
			if (shipName.interactable)
			{
				shipName.ActivateInputField();
			}
			else
			{
				shipName.DeactivateInputField();
			}
			SfxSystem.inst.PlayFromBank("ui_edit", Camera.main.transform.position);
		});
		ConsoleUIUpdate(GamepadControl.inst.isControllerActive);
		GamepadControl gamepadControl = GamepadControl.inst;
		gamepadControl.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(gamepadControl.controllerUpdate, new GamepadControl.ControllerActivity(ConsoleUIUpdate));
	}

	public void OnDestroy()
	{
		GamepadControl gamepadControl = GamepadControl.inst;
		gamepadControl.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Remove(gamepadControl.controllerUpdate, new GamepadControl.ControllerActivity(ConsoleUIUpdate));
	}

	public void OnClickedClose()
	{
		transport = null;
		SetVisible(v: false);
		SfxSystem.PlayUiCancel();
	}

	public LogisticsDestUI OnClickedAddDestination(bool silent = false)
	{
		if (!silent)
		{
			SfxSystem.PlayUiSelect();
		}
		LogisticsDestUI logisticsDestUI = null;
		if (poolCount == destActive.Count)
		{
			logisticsDestUI = UnityEngine.Object.Instantiate(destinationPrefab, destinationsContainer).GetComponent<LogisticsDestUI>();
			logisticsDestUI.GetComponent<RectTransform>().anchoredPosition = Vector3.zero;
			logisticsDestUI.transform.localScale = Vector3.one;
			destPool.Add(logisticsDestUI);
			logisticsDestUI.idxIntoPool = destPool.Count - 1;
			poolCount++;
		}
		else
		{
			logisticsDestUI = destPool.GetNew();
			logisticsDestUI.idxIntoPool = destPool.Count - 1;
		}
		logisticsDestUI.transform.SetSiblingIndex(destinationsContainer.childCount - 2);
		logisticsDestUI.Init();
		return logisticsDestUI;
	}

	public void FocusShip()
	{
		if (transport != null)
		{
			Cam.inst.Track((transport as MonoBehaviour).GetComponent<ICamTrackable>());
		}
	}

	public void DeleteDestination(LogisticsDestUI ui)
	{
		if (transport == null || transport.GetOrders().Count <= 2)
		{
			return;
		}
		for (int i = 0; i < destActive.Count; i++)
		{
			LogisticsDestUI logisticsDestUI = destActive.data[i];
			if (logisticsDestUI == ui)
			{
				logisticsDestUI.Shutdown();
				break;
			}
		}
	}

	private void ClearUI()
	{
		while (destActive.Count > 0)
		{
			destActive.data[0].Shutdown();
		}
	}

	private void TryInitCursorMode()
	{
		if (cursorMode == null)
		{
			cursorMode = new DockRouteCursorMode();
		}
		cursorMode.pathMat = pathMaterial;
		cursorMode.straightMesh = straightMesh;
		cursorMode.cornerMesh = cornerMesh;
		cursorMode.arrowMesh = arrowMesh;
		cursorMode.crossMesh = crossMesh;
		cursorMode.routeColors = ((transport is TransportCart) ? cartRouteColors : shipRouteColors);
		cursorMode.crossMat = crossMat;
	}

	public bool ValidForDockingCargo(Building b)
	{
		return World.GetLandmassOwner(b.LandMass()) == Player.inst.PlayerLandmassOwner;
	}

	public bool ValidForDockingMerchant(Building b)
	{
		LandmassOwner landmassOwner = World.GetLandmassOwner(b.LandMass());
		bool flag = Player.inst.DocksOpen(Player.inst.PlayerLandmassOwner, landmassOwner);
		return (landmassOwner == Player.inst.PlayerLandmassOwner) | flag;
	}

	private void PopulateUI()
	{
		TryInitCursorMode();
		cursorMode.isCart = transport as TransportCart != null;
		if (transport != null)
		{
			deleteLoc.Term = (cursorMode.isCart ? "TransportCartDestroy" : "TransportShipDestroy");
			strongerSails.gameObject.SetActive(World.GetLandmassOwnerByTeamId(transport.TeamID()).HasUpgrade(Player.UpgradeType.StrongerSails));
			windowDesc.GetComponent<Localize>().Term = transport.GetDescription();
			cursorMode.ValidForDocking = transport.ValidForDocking;
			transport.ValidateOrders();
			UpdateDestinationUI(transport.GetOrders());
			cursorMode.SetCurrOrders(transport.GetOrders());
			SetupRouteColors();
			UpdateYearlyRouteVisuals(transport.GetMaxCycle());
			SetPausedStateVisuals(transport.isPaused());
			shipName.text = transport.GetTransportName();
		}
		holdContainer.gameObject.SetActive(value: false);
	}

	public void AddStartNode()
	{
		List<Ship.LogisticsOrder> orders = transport.GetOrders();
		Ship.LogisticsOrder logisticsOrder = new Ship.LogisticsOrder();
		logisticsOrder.endType = Ship.LogisticsOrderType.Position;
		Vector3 vector = orders[0].endPosition;
		if (transport is Ship)
		{
			vector = FindOptimialShipNodePosition(vector, orders);
		}
		else if (transport is TransportCart)
		{
			vector = FindOptimalCartNodePosition(vector, orders);
		}
		logisticsOrder.endPosition = vector;
		orders.Insert(0, logisticsOrder);
		Cam.inst.SetDesiredTrackingPos(vector);
		Cam.inst.desiredDist = 35f;
		PopulateUI();
	}

	public void AddEndNode()
	{
		List<Ship.LogisticsOrder> orders = transport.GetOrders();
		Ship.LogisticsOrder logisticsOrder = new Ship.LogisticsOrder();
		logisticsOrder.endType = Ship.LogisticsOrderType.Position;
		Vector3 vector = orders[orders.Count - 1].endPosition;
		if (transport is Ship)
		{
			vector = FindOptimialShipNodePosition(vector, orders);
		}
		else if (transport is TransportCart)
		{
			vector = FindOptimalCartNodePosition(vector, orders);
		}
		logisticsOrder.endPosition = vector;
		orders.Add(logisticsOrder);
		Cam.inst.SetDesiredTrackingPos(vector);
		Cam.inst.desiredDist = 35f;
		PopulateUI();
	}

	private Vector3 FindOptimialShipNodePosition(Vector3 startPos, List<Ship.LogisticsOrder> orders)
	{
		Vector3 result = startPos;
		float num = 0f;
		visited.Clear();
		openSet.Clear();
		openSet.Add(World.inst.GetCellDataClamped(startPos));
		while (openSet.Count > 0)
		{
			Cell cell = openSet[0];
			openSet.RemoveAt(0);
			if (transport.ValidForOrder(cell) && !visited.Contains(cell))
			{
				float num2 = Mathff.DistSqrdXZ(cell.Center2D, startPos);
				bool flag = false;
				for (int i = 0; i < orders.Count; i++)
				{
					if (orders[i].endType != Ship.LogisticsOrderType.Building && orders[i].endPosition == cell.Center2D)
					{
						flag = true;
						break;
					}
				}
				if (flag || ShipSystem.inst.GetShipsAt(cell.x, cell.z).Count > 0)
				{
					num2 *= 0.5f;
				}
				if (num2 <= 16f)
				{
					if (num2 > num)
					{
						num = num2;
						result = cell.Center2D;
					}
					openSet.Add(World.inst.GetCellDataClamped(cell.x + 1, cell.z));
					openSet.Add(World.inst.GetCellDataClamped(cell.x - 1, cell.z));
					openSet.Add(World.inst.GetCellDataClamped(cell.x, cell.z + 1));
					openSet.Add(World.inst.GetCellDataClamped(cell.x, cell.z - 1));
				}
			}
			visited.Add(cell);
		}
		return result;
	}

	private Vector3 FindOptimalCartNodePosition(Vector3 startPos, List<Ship.LogisticsOrder> orders)
	{
		Vector3 vector = startPos;
		float num = float.MinValue;
		visited.Clear();
		openSet.Clear();
		openSet.Add(World.inst.GetCellDataClamped(vector));
		while (openSet.Count > 0)
		{
			Cell cell = openSet[0];
			openSet.RemoveAt(0);
			if (transport.ValidForOrder(cell) && !visited.Contains(cell))
			{
				float num2 = Mathff.DistSqrdXZ(cell.Center2D, vector);
				if (num2 <= 9f)
				{
					float num3 = Mathff.DistSqrdXZ(cell.Center2D, startPos);
					bool flag = false;
					for (int i = 0; i < orders.Count; i++)
					{
						if (orders[i].endType != Ship.LogisticsOrderType.Building && orders[i].endPosition == cell.Center2D)
						{
							flag = true;
							break;
						}
					}
					if (flag)
					{
						num3 *= 0.5f;
					}
					float num4 = num2 * 2f + (0f - num3);
					if (num4 > num)
					{
						num = num4;
						vector = cell.Center2D;
					}
					openSet.Add(World.inst.GetCellDataClamped(cell.x + 1, cell.z));
					openSet.Add(World.inst.GetCellDataClamped(cell.x - 1, cell.z));
					openSet.Add(World.inst.GetCellDataClamped(cell.x, cell.z + 1));
					openSet.Add(World.inst.GetCellDataClamped(cell.x, cell.z - 1));
				}
			}
			visited.Add(cell);
		}
		return vector;
	}

	private void UpdateYearlyRouteVisuals(int max)
	{
		routeCycleSlider.value = max;
		if (max == 0)
		{
			routeEveryYearsText.text = ScriptLocalization.transportWithoutConstraints;
		}
		else
		{
			routeEveryYearsText.text = string.Format(ScriptLocalization.transportEveryXYears, max);
		}
	}

	private void SetPausedStateVisuals(bool paused)
	{
		play.isOn = !paused;
		play.transform.GetChild(0).gameObject.SetActive(!paused);
		pause.isOn = paused;
		pause.transform.GetChild(0).gameObject.SetActive(paused);
		if (paused)
		{
			statusText.text = ScriptLocalization.TransportShipPaused;
		}
		else
		{
			statusText.text = ScriptLocalization.TransportShipSailing;
		}
		pauseHighlight.gameObject.SetActive(paused);
	}

	public void RefreshMerchantStatusForOrder(Ship.LogisticsOrder order)
	{
		for (int i = 0; i < destActive.Count; i++)
		{
			if (destActive.data[i].logisticOrder == order)
			{
				destActive.data[i].RefreshMerchantSaleStatus();
			}
		}
	}

	public void UpdateDestinationUI(List<Ship.LogisticsOrder> logisticsOrders)
	{
		int num = 0;
		for (int i = 0; i < logisticsOrders.Count; i++)
		{
			if (logisticsOrders[i].endType != Ship.LogisticsOrderType.Position)
			{
				if (num == destActive.Count)
				{
					OnClickedAddDestination(silent: true);
				}
				LogisticsDestUI obj = destActive.data[num];
				obj.SetTransport(transport);
				obj.SetOrder(logisticsOrders[i]);
				num++;
			}
		}
		while (num < destActive.Count)
		{
			destActive.data[destActive.Count - 1].Shutdown();
		}
	}

	private void SetupRouteColors()
	{
		List<Ship.LogisticsOrder> orders = transport.GetOrders();
		Color[] array = ((transport is TransportCart) ? cartRouteColors : shipRouteColors);
		int num = 0;
		for (int i = 0; i < orders.Count; i++)
		{
			if (orders[i].endType != Ship.LogisticsOrderType.Position)
			{
				destActive.data[num].RouteColor.color = array[i % array.Length];
				num++;
			}
		}
	}

	public void SetSelectedTransport(ILogisticTransport v)
	{
		if (v != null)
		{
			transport = v;
			ClearUI();
			PopulateUI();
		}
	}

	private void OnDisable()
	{
		inEditRouteMode = false;
	}

	public override void UpdateInternal(float dt)
	{
		base.UpdateInternal(dt);
		if (deferTitleTextInteractibleFalse)
		{
			shipName.interactable = false;
			deferTitleTextInteractibleFalse = false;
		}
		if (cursorMode.ConsumeUIDirty())
		{
			PopulateUI();
		}
		if (transport != null)
		{
			transport.SetOutlineImmediate(1);
			bool flag = transport.isErrorVisible();
			logsiticsError.SetActive(flag);
			if (flag)
			{
				logsiticsErrorText.text = transport.GetErrorText();
			}
			UpdateHoldVisuals(transport.GetHold(), transport.GetMaxHold());
			SetPausedStateVisuals(transport.isPaused());
			UpdateYearlyRouteVisuals(transport.GetMaxCycle());
			List<Ship.LogisticsOrder> orders = transport.GetOrders();
			helperText.gameObject.SetActive(destActive.Count == 0);
			error.gameObject.SetActive(transport.isErrorVisible() && !helperText.gameObject.activeSelf);
			if (GameUI.inst.currCursorMode is DockRouteCursorMode && transport.GetOrders().Count > 2)
			{
				bool flag2 = (GameUI.inst.currCursorMode as DockRouteCursorMode).SelectingEndpoint();
				trashButton.SetActive(flag2);
				if ((PointingSystem.GetPointer().GetPrimaryUp() && overTrash) & flag2)
				{
					(GameUI.inst.currCursorMode as DockRouteCursorMode).DeleteSelectedEndpoint();
					PointerExit();
				}
			}
			addStartNodeBtn.gameObject.SetActive(orders[0].endType == Ship.LogisticsOrderType.Building);
			addEndNodeBtn.gameObject.SetActive(orders[orders.Count - 1].endType == Ship.LogisticsOrderType.Building);
		}
		if (!GamepadControl.inst.isControllerActive && GameUI.inst.currCursorMode != cursorMode && gameObject.activeSelf)
		{
			SetVisible(v: false);
		}
		if (pauseHighlight.gameObject.activeSelf)
		{
			pauseHighlight.GetComponent<Image>().color = Color.Lerp(new Color(1f, 1f, 0f, 0.75f), new Color(0.5f, 0.5f, 0f, 0.5f), (Mathf.Sin(Time.unscaledTime * 3f) + 1f) * 0.5f);
		}
		if (GamepadControl.inst.isControllerActive)
		{
			if (GamepadControl.inst.player.GetButtonUp("X"))
			{
				ActivateConsoleEditRouteMode();
			}
			if (inEditRouteMode && GamepadControl.inst.player.GetButtonUp("Y") && transport != null)
			{
				List<Ship.LogisticsOrder> orders2 = transport.GetOrders();
				cursorMode.DeleteHighlightEndPoint(ref orders2);
			}
		}
	}

	private void ActivateConsoleEditRouteMode()
	{
		if (GamepadControl.inst.isControllerActive)
		{
			if (!inEditRouteMode)
			{
				entryItem.Reset();
				entryItem.Hover();
				editRouteBtnItem.Submit();
			}
			else
			{
				editRouteBtnItem.GetComponent<ConsoleUIAwaitSelection>().SelectItem();
				OnFocusedEditRoute();
			}
		}
	}

	private void LateUpdate()
	{
		if (WorldMask.inst.activated)
		{
			WorldMask.inst.ForceUpdate();
		}
	}

	private void UpdateHoldVisuals(ResourceAmount hold, int max)
	{
		if (!holdContainer.gameObject.activeSelf)
		{
			return;
		}
		int num = 1;
		for (int i = 0; i < hold.resources.Count; i++)
		{
			int amount = hold.resources[i].Amount;
			if (amount > 0)
			{
				Transform child = holdContainer.transform.GetChild(num);
				child.gameObject.SetActive(value: true);
				child.GetComponentInChildren<Image>().sprite = FreeResourceSystem.inst.resourceDefs[hold.resources[i].resourceID].texture;
				child.GetComponentInChildren<TextMeshProUGUI>().SetText("{0}", amount);
				num++;
			}
		}
		for (int j = num; j < holdContainer.transform.childCount - 1; j++)
		{
			holdContainer.transform.GetChild(j).gameObject.SetActive(value: false);
		}
		int num2 = 0;
		for (int k = 0; k < hold.resources.Count; k++)
		{
			num2 += hold.resources[k].Amount;
		}
		holdCurrTxt.SetText("{0}", num2);
		holdMaxTxt.SetText("{0}", max);
	}

	public void OnSliderValueChanged()
	{
		int num = (int)routeCycleSlider.value;
		if (transport != null && num != transport.GetMaxCycle())
		{
			SfxSystem.PlayUiSelect();
			transport.SetMaxYear(num);
			UpdateYearlyRouteVisuals(transport.GetMaxCycle());
		}
	}

	public void OnTogglePlayPause()
	{
		SfxSystem.PlayUiSelect();
		bool flag = !play.isOn;
		if (transport != null)
		{
			transport.SetPaused(flag);
		}
		SetPausedStateVisuals(flag);
	}

	public override void SetVisible(bool v)
	{
		if (Visible && !v)
		{
			transport = null;
			WorldMask.inst.Deactivate();
			if (GameUI.inst.currCursorMode == cursorMode)
			{
				GameUI.inst.ReturnToDefaultCursorMode();
			}
			World.inst.HideResourceTooltipUIs();
			if (GamepadControl.inst.isControllerActive)
			{
				borderHighlight.SetActive(value: false);
				overlay.SetActive(value: false);
			}
		}
		base.SetVisible(v);
		if (v)
		{
			GameUI.inst.SetCursorMode(cursorMode);
			CreativeUI.inst.SetWindowVisibility(v: false);
			if (transport as Ship != null)
			{
				PlaceDockWorldNotes();
			}
			normal.Clear();
			highlight.Clear();
			if (transport is TransportCart)
			{
				WorldMask.inst.Activate(LandCartMasking);
			}
			else
			{
				WorldMask.inst.Activate(ShipMasking);
			}
		}
	}

	private void OnEnable()
	{
		if (GamepadControl.inst.isControllerActive)
		{
			borderHighlight.SetActive(value: true);
			overlay.SetActive(value: false);
			ConsoleTileUI.inst.SetVisible(v: false);
			entryItem.Hover();
		}
	}

	public void PlaceDockWorldNotes()
	{
		int hashCode = "dock".GetHashCode();
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList(hashCode);
		for (int i = 0; i < buildingList.Count; i++)
		{
			Building building = buildingList.data[i];
			Vector3 position = building.GetPos() + new Vector3(0f, 1.5f, 0f);
			GameObject gameObject = UnityEngine.Object.Instantiate(World.inst.resourceTooltipPrefab);
			ResourceTooltipUI component = gameObject.GetComponent<ResourceTooltipUI>();
			component.SetText(building.customName);
			component.EnableTextAutoSizing();
			gameObject.transform.position = position;
			gameObject.transform.SetParent(World.inst.resourceTooltipContainer.transform);
		}
	}

	public void OnDestroyShip()
	{
		Transform transform = (transport as MonoBehaviour).transform;
		EffectsMan.inst.BuildPuff.CreateAndPlay(transform.position);
		if (!World.inst.GetCellData(transform.position).deepWater)
		{
			ResourceAmount hold = transport.GetHold();
			for (int i = 0; i < hold.resources.Count; i++)
			{
				int amount = hold.resources[i].Amount;
				if (amount > 0)
				{
					FreeResourceManager.inst.GetAutoStackFor(hold.resources[i].resourceID, amount, transform.position);
				}
			}
		}
		UnityEngine.Object.Destroy(transform.gameObject);
		SetVisible(v: false);
		SfxSystem.inst.PlayFromBank("DestroyTransportShip", transform.position);
	}
}
