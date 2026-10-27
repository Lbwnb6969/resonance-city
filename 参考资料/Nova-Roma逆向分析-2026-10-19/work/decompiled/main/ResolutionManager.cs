using System.Collections.Generic;
using System.Linq;
using I2.Loc;
using TMPro;
using UnityEngine;

public class ResolutionManager : MonoBehaviour
{
	public class ResolutionComparerWithHz : IEqualityComparer<Resolution>
	{
		private float GetSortKey(Resolution res)
		{
			return (float)res.width * 10f + (float)res.height + (float)Mathf.RoundToInt((float)res.refreshRateRatio.value);
		}

		public bool Equals(Resolution x, Resolution y)
		{
			return Mathf.Approximately(GetSortKey(x), GetSortKey(y));
		}

		public int GetHashCode(Resolution obj)
		{
			return GetSortKey(obj).GetHashCode();
		}
	}

	public class ResolutionComparerDimensionsOnly : IEqualityComparer<Resolution>
	{
		private int GetSortKey(Resolution res)
		{
			return res.width * 10000 + res.height;
		}

		public bool Equals(Resolution x, Resolution y)
		{
			if (x.width == y.width)
			{
				return x.height == y.height;
			}
			return false;
		}

		public int GetHashCode(Resolution obj)
		{
			return GetSortKey(obj).GetHashCode();
		}
	}

	public TMP_Dropdown ResolutionDropdown;

	public TMP_Dropdown WindowTypeDropdown;

	private List<Resolution> resolutionsSorted;

	private FullScreenMode currentFullScreenMode;

	private int w;

	private int h;

	private bool fullscreen;

	private FullScreenMode fullscreenMode;

	private RefreshRate refresh;

	private void Start()
	{
		ResolutionDropdown.onValueChanged.AddListener(ResolutionSelected);
		WindowTypeDropdown.onValueChanged.AddListener(WindowTypeSelected);
		LocalizationManager.OnLocalizeEvent += OnLocalize;
	}

	private void OnDestroy()
	{
		LocalizationManager.OnLocalizeEvent -= OnLocalize;
	}

	private void OnLocalize()
	{
		if (enabled && gameObject.activeInHierarchy)
		{
			RefreshWindowTypeDropdownLocalization();
		}
	}

	private void RefreshWindowTypeDropdownLocalization()
	{
		_ = WindowTypeDropdown.value;
		WindowTypeDropdown.options[0].text = LocalizationManager.GetTranslation("settingsui_windowtype_window");
		WindowTypeDropdown.options[1].text = LocalizationManager.GetTranslation("settingsui_windowtype_fullscreen");
		WindowTypeDropdown.options[2].text = LocalizationManager.GetTranslation("settingsui_windowtype_fullscreenwindow");
		WindowTypeDropdown.RefreshShownValue();
	}

	private static int gcd(int a, int b)
	{
		if (b != 0)
		{
			return gcd(b, a % b);
		}
		return a;
	}

	public string BuildResolutionString(int width, int height, int refreshRate, bool custom = false)
	{
		int num = gcd(width, height);
		int num2 = width / num;
		int num3 = height / num;
		if (num2 == 8 && num3 == 5)
		{
			num2 *= 2;
			num3 *= 2;
		}
		if (custom)
		{
			return $"<color=#bbb>{width}<color=#666> x <color=#bbb>{height} <color=#666>, <color=#bbb>{refreshRate:0.##}Hz";
		}
		return $"<color=#bbb>{width}<color=#666> x <color=#bbb>{height} <color=#666>({num2}:{num3}), <color=#bbb>{refreshRate:0.##}Hz";
	}

	public string BuildResolutionStringNoHz(int width, int height)
	{
		int num = gcd(width, height);
		int num2 = width / num;
		int num3 = height / num;
		if (num2 == 8 && num3 == 5)
		{
			num2 *= 2;
			num3 *= 2;
		}
		return $"<color=#bbb>{width}<color=#666> x <color=#bbb>{height} <color=#666>({num2}:{num3})";
	}

	private void OnEnable()
	{
		TMP_Dropdown.OptionDataList optionDataList = new TMP_Dropdown.OptionDataList();
		optionDataList.options.Add(new TMP_Dropdown.OptionData
		{
			image = null,
			text = LocalizationManager.GetTranslation("settingsui_windowtype_window")
		});
		optionDataList.options.Add(new TMP_Dropdown.OptionData
		{
			image = null,
			text = LocalizationManager.GetTranslation("settingsui_windowtype_fullscreen")
		});
		optionDataList.options.Add(new TMP_Dropdown.OptionData
		{
			image = null,
			text = LocalizationManager.GetTranslation("settingsui_windowtype_fullscreenwindow")
		});
		WindowTypeDropdown.ClearOptions();
		WindowTypeDropdown.AddOptions(optionDataList.options);
		currentFullScreenMode = Screen.fullScreenMode;
		int fullScreenModeIndex = GetFullScreenModeIndex(currentFullScreenMode);
		WindowTypeDropdown.SetValueWithoutNotify(fullScreenModeIndex);
		RebuildResolutionDropdown();
	}

	private int GetFullScreenModeIndex(FullScreenMode mode)
	{
		return mode switch
		{
			FullScreenMode.Windowed => 0, 
			FullScreenMode.ExclusiveFullScreen => 1, 
			FullScreenMode.FullScreenWindow => 2, 
			_ => 0, 
		};
	}

	private FullScreenMode GetFullScreenModeFromIndex(int idx)
	{
		return idx switch
		{
			0 => FullScreenMode.Windowed, 
			1 => FullScreenMode.ExclusiveFullScreen, 
			2 => FullScreenMode.FullScreenWindow, 
			_ => FullScreenMode.Windowed, 
		};
	}

	private bool IsWindowedMode(FullScreenMode mode)
	{
		if (mode != FullScreenMode.Windowed)
		{
			return mode == FullScreenMode.FullScreenWindow;
		}
		return true;
	}

	private void RebuildResolutionDropdown()
	{
		int currentWidth = Screen.width;
		int currentHeight = Screen.height;
		int currentHzRounded = Mathf.RoundToInt((float)Screen.currentResolution.refreshRateRatio.value);
		if (IsWindowedMode(currentFullScreenMode))
		{
			resolutionsSorted = Screen.resolutions.OrderBy((Resolution x) => x.width * 10000 + x.height).Distinct(new ResolutionComparerDimensionsOnly()).ToList();
			int num = resolutionsSorted.FindIndex((Resolution x) => x.width == currentWidth && x.height == currentHeight);
			if (num < 0)
			{
				num = FindClosestResolutionIndex(currentWidth, currentHeight);
			}
			num = Mathf.Clamp(num, 0, resolutionsSorted.Count - 1);
			List<string> options = resolutionsSorted.Select((Resolution x) => BuildResolutionStringNoHz(x.width, x.height)).ToList();
			PopulateResolutionDropdown(options, num);
			return;
		}
		resolutionsSorted = Screen.resolutions.OrderBy((Resolution x) => (float)x.width * 10f + (float)x.height + (float)Mathf.RoundToInt((float)x.refreshRateRatio.value)).Distinct(new ResolutionComparerWithHz()).ToList();
		int num2 = resolutionsSorted.FindIndex((Resolution x) => x.width == currentWidth && x.height == currentHeight && Mathf.RoundToInt((float)x.refreshRateRatio.value) == currentHzRounded);
		if (num2 < 0)
		{
			num2 = resolutionsSorted.FindIndex((Resolution x) => x.width == currentWidth && x.height == currentHeight);
		}
		if (num2 < 0)
		{
			num2 = FindClosestResolutionIndex(currentWidth, currentHeight);
		}
		num2 = Mathf.Clamp(num2, 0, resolutionsSorted.Count - 1);
		List<string> options2 = resolutionsSorted.Select((Resolution x) => BuildResolutionString(x.width, x.height, Mathf.RoundToInt((float)x.refreshRateRatio.value))).ToList();
		PopulateResolutionDropdown(options2, num2);
	}

	private int FindClosestResolutionIndex(int targetWidth, int targetHeight)
	{
		int result = 0;
		int num = int.MaxValue;
		for (int i = 0; i < resolutionsSorted.Count; i++)
		{
			Resolution resolution = resolutionsSorted[i];
			int num2 = Mathf.Abs(resolution.width - targetWidth) + Mathf.Abs(resolution.height - targetHeight);
			if (num2 < num)
			{
				num = num2;
				result = i;
			}
		}
		return result;
	}

	private void PopulateResolutionDropdown(List<string> options, int selectedIndex)
	{
		TMP_Dropdown.OptionDataList optionDataList = new TMP_Dropdown.OptionDataList();
		for (int i = 0; i < options.Count; i++)
		{
			optionDataList.options.Add(new TMP_Dropdown.OptionData
			{
				image = null,
				text = options[i]
			});
		}
		ResolutionDropdown.ClearOptions();
		ResolutionDropdown.AddOptions(optionDataList.options);
		ResolutionDropdown.SetValueWithoutNotify(selectedIndex);
	}

	public void ResolutionSelected(int idx)
	{
		Resolution resolution = resolutionsSorted[idx];
		SetResolution(resolution.width, resolution.height, currentFullScreenMode, resolution.refreshRateRatio);
		SfxSystem.PlayUiSelect();
	}

	public void WindowTypeSelected(int idx)
	{
		FullScreenMode fullScreenModeFromIndex = GetFullScreenModeFromIndex(idx);
		bool flag = IsWindowedMode(currentFullScreenMode) != IsWindowedMode(fullScreenModeFromIndex);
		currentFullScreenMode = fullScreenModeFromIndex;
		SetResolution(Screen.width, Screen.height, fullScreenModeFromIndex, Screen.currentResolution.refreshRateRatio);
		if (flag)
		{
			RebuildResolutionDropdown();
		}
		SfxSystem.PlayUiSelect();
	}

	public void StoreResolutionInfo()
	{
		w = Screen.width;
		h = Screen.height;
		fullscreen = Screen.fullScreen;
		fullscreenMode = Screen.fullScreenMode;
		refresh = Screen.currentResolution.refreshRateRatio;
	}

	private void SetResolution(int width, int height, FullScreenMode mode, RefreshRate refreshRate)
	{
		width = Mathff.Max(width, 640);
		height = Mathff.Max(height, 480);
		Screen.SetResolution(width, height, mode, refreshRate);
		Screen.fullScreenMode = mode;
		GameUI.inst.UpdateCanvasScalers();
		Cursor.lockState = ((mode == FullScreenMode.ExclusiveFullScreen) ? CursorLockMode.Confined : CursorLockMode.None);
	}

	public void RestoreResolutionInfo()
	{
		SetResolution(w, h, fullscreenMode, refresh);
	}
}
