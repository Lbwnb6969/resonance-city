using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using I2.Loc;
using Sirenix.OdinInspector;
using UnityEngine;

public class ConfigurableControls : MonoBehaviour
{
	[Serializable]
	public struct KeyChord
	{
		public KeyCode key;

		public bool ctrl;

		public bool alt;

		public bool shift;

		public static KeyChord None = new KeyChord
		{
			key = KeyCode.None
		};

		private static readonly Dictionary<KeyCode, string> _keyTranslations = new Dictionary<KeyCode, string>
		{
			{
				KeyCode.Backspace,
				"backspace"
			},
			{
				KeyCode.Delete,
				"delete"
			},
			{
				KeyCode.Tab,
				"tab"
			},
			{
				KeyCode.Clear,
				"clear"
			},
			{
				KeyCode.Return,
				"return"
			},
			{
				KeyCode.Pause,
				"pause"
			},
			{
				KeyCode.Escape,
				"escape"
			},
			{
				KeyCode.Space,
				"space"
			},
			{
				KeyCode.UpArrow,
				"up"
			},
			{
				KeyCode.DownArrow,
				"down"
			},
			{
				KeyCode.RightArrow,
				"right"
			},
			{
				KeyCode.LeftArrow,
				"left"
			},
			{
				KeyCode.Insert,
				"insert"
			},
			{
				KeyCode.Home,
				"home"
			},
			{
				KeyCode.End,
				"end"
			},
			{
				KeyCode.PageUp,
				"page up"
			},
			{
				KeyCode.PageDown,
				"page down"
			},
			{
				KeyCode.Numlock,
				"numlock"
			},
			{
				KeyCode.CapsLock,
				"caps lock"
			},
			{
				KeyCode.ScrollLock,
				"scroll lock"
			},
			{
				KeyCode.RightShift,
				"right shift"
			},
			{
				KeyCode.LeftShift,
				"left shift"
			},
			{
				KeyCode.RightControl,
				"right ctrl"
			},
			{
				KeyCode.LeftControl,
				"left ctrl"
			},
			{
				KeyCode.RightAlt,
				"right alt"
			},
			{
				KeyCode.LeftAlt,
				"left alt"
			}
		};

		public static bool operator ==(KeyChord leftK, KeyChord rightK)
		{
			if (leftK.key == rightK.key && leftK.ctrl == rightK.ctrl && leftK.alt == rightK.alt)
			{
				return leftK.shift == rightK.shift;
			}
			return false;
		}

		public static bool operator !=(KeyChord leftK, KeyChord rightK)
		{
			return !(leftK == rightK);
		}

		public override bool Equals(object obj)
		{
			if (obj is KeyChord keyChord)
			{
				return this == keyChord;
			}
			return false;
		}

		public override int GetHashCode()
		{
			return HashCode.Combine(key, ctrl, alt, shift);
		}

		public override string ToString()
		{
			if (key == KeyCode.None)
			{
				return string.Empty;
			}
			List<string> list = new List<string>(4);
			if (ctrl)
			{
				list.Add(TranslateModifier("ctrl"));
			}
			if (alt)
			{
				list.Add(TranslateModifier("alt"));
			}
			if (shift)
			{
				list.Add(TranslateModifier("shift"));
			}
			list.Add(GetLocalizedKeyName(key));
			return string.Join(" + ", list);
		}

		private static string TranslateModifier(string modifier)
		{
			return TranslateKeyTerm(modifier);
		}

		public static string GetLocalizedKeyName(KeyCode keyCode)
		{
			if (_keyTranslations.TryGetValue(keyCode, out var value))
			{
				return TranslateKeyTerm(value);
			}
			return TranslateKeyTerm(keyCode.ToString().ToLower());
		}

		private static string TranslateKeyTerm(string term)
		{
			string translation = LocalizationManager.GetTranslation("keyboard/" + term);
			if (!string.IsNullOrEmpty(translation))
			{
				return translation;
			}
			return term;
		}
	}

	[Serializable]
	public class Keybind
	{
		public int id;

		public string groupName;

		public string name;

		[OptionalField(VersionAdded = 2)]
		public KeyChord keychord;

		[NonSerialized]
		public KeybindGroupUI groupUI;

		[NonSerialized]
		public KeybindItemUI itemUI;

		[NonSerialized]
		public bool isConsumed;

		public bool GetKey(bool ignoreCtrl, bool ignoreAlt, bool ignoreShift)
		{
			bool flag = Input.GetKey(keychord.key);
			if (keychord.key != KeyCode.RightControl && keychord.key != KeyCode.LeftControl && !ignoreCtrl)
			{
				flag &= (Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl)) == keychord.ctrl;
			}
			if (keychord.key != KeyCode.LeftAlt && keychord.key != KeyCode.RightAlt && !ignoreAlt)
			{
				flag &= (Input.GetKey(KeyCode.LeftAlt) || Input.GetKey(KeyCode.RightAlt)) == keychord.alt;
			}
			if (keychord.key != KeyCode.LeftShift && keychord.key != KeyCode.RightShift && !ignoreShift)
			{
				flag &= (Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift)) == keychord.shift;
			}
			return flag;
		}

		public bool GetKeyDown()
		{
			bool flag = Input.GetKeyDown(keychord.key);
			if (keychord.key != KeyCode.RightControl && keychord.key != KeyCode.LeftControl)
			{
				flag &= (Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl)) == keychord.ctrl;
			}
			if (keychord.key != KeyCode.LeftAlt && keychord.key != KeyCode.RightAlt)
			{
				flag &= (Input.GetKey(KeyCode.LeftAlt) || Input.GetKey(KeyCode.RightAlt)) == keychord.alt;
			}
			if (keychord.key != KeyCode.LeftShift && keychord.key != KeyCode.RightShift)
			{
				flag &= (Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift)) == keychord.shift;
			}
			return flag;
		}

		public bool GetKeyUp()
		{
			bool flag = Input.GetKeyUp(keychord.key);
			if (keychord.key != KeyCode.RightControl && keychord.key != KeyCode.LeftControl)
			{
				flag &= (Input.GetKeyUp(KeyCode.LeftControl) || Input.GetKeyUp(KeyCode.RightControl)) == keychord.ctrl;
			}
			if (keychord.key != KeyCode.LeftAlt && keychord.key != KeyCode.RightAlt)
			{
				flag &= (Input.GetKeyUp(KeyCode.LeftAlt) || Input.GetKeyUp(KeyCode.RightAlt)) == keychord.alt;
			}
			if (keychord.key != KeyCode.LeftShift && keychord.key != KeyCode.RightShift)
			{
				flag &= (Input.GetKeyUp(KeyCode.LeftShift) || Input.GetKeyUp(KeyCode.RightShift)) == keychord.shift;
			}
			return flag;
		}

		public override string ToString()
		{
			return keychord.ToString();
		}
	}

	public static ConfigurableControls inst;

	public static bool isActive = true;

	public const int CameraMoveForward = 100;

	public const int CameraMoveBackward = 101;

	public const int CameraMoveLeft = 102;

	public const int CameraMoveRight = 103;

	public const int CameraMoveFast = 104;

	public const int CameraRotateLeft = 105;

	public const int CameraRotateRight = 106;

	public const int CameraZoomIn = 107;

	public const int CameraZoomOut = 108;

	public const int CameraRotateUp = 109;

	public const int CameraRotateDown = 110;

	public const int SpeedPause = 200;

	public const int SpeedNormal = 201;

	public const int SpeedFast = 202;

	public const int SpeedFastest = 203;

	public const int ModeClearLand = 300;

	public const int ModeCancelClearLand = 301;

	public const int ModeEditTerrain = 302;

	public const int ModeRebuild = 303;

	public const int ModeDemolish = 304;

	public const int ModeSample = 305;

	public const int QuickSave = 804;

	public const int QuickLoad = 805;

	public const int Escape = 900;

	public const int ToggleUI = 901;

	public const int ToggleJobPriorityUI = 902;

	public const int ToggleTechnologyTreeUI = 903;

	public static ValueDropdownList<int> DropdownOptions = new ValueDropdownList<int>
	{
		{ "CameraMoveForward", 100 },
		{ "CameraMoveBackward", 101 },
		{ "CameraMoveLeft", 102 },
		{ "CameraMoveRight", 103 },
		{ "CameraMoveFast", 104 },
		{ "CameraRotateLeft", 105 },
		{ "CameraRotateRight", 106 },
		{ "CameraRotateUp", 109 },
		{ "CameraRotateDown", 110 },
		{ "CameraZoomIn", 107 },
		{ "CameraZoomOut", 108 },
		{ "SpeedPause", 200 },
		{ "SpeedNormal", 201 },
		{ "SpeedFast", 202 },
		{ "SpeedFastest", 203 },
		{ "ModeClearLand", 300 },
		{ "ModeCancelClearLand", 301 },
		{ "ModeEditTerrain", 302 },
		{ "ModeRebuild", 303 },
		{ "ModeDemolish", 304 },
		{ "ModeSample", 305 },
		{ "QuickSave", 804 },
		{ "QuickLoad", 805 },
		{ "Escape", 900 },
		{ "ToggleUI", 901 },
		{ "ToggleJobPriorityUI", 902 },
		{ "ToggleTechnologyTreeUI", 903 }
	};

	public Dictionary<int, Keybind> keybinds = new Dictionary<int, Keybind>();

	private Dictionary<int, KeyChord> original = new Dictionary<int, KeyChord>();

	private void Awake()
	{
		inst = this;
		LocalizationManager.OnLocalizeEvent += RefreshKeybindLabels;
		CustomKeybinds customKeybinds = Resources.Load<CustomKeybinds>("CustomKeybinds");
		if (customKeybinds != null)
		{
			CustomKeybinds customKeybinds2 = UnityEngine.Object.Instantiate(customKeybinds);
			for (int i = 0; i < customKeybinds2.keybinds.Length; i++)
			{
				AddKeybind(customKeybinds2.keybinds[i]);
			}
		}
	}

	private void OnDestroy()
	{
		LocalizationManager.OnLocalizeEvent -= RefreshKeybindLabels;
	}

	private void LateUpdate()
	{
		foreach (KeyValuePair<int, Keybind> keybind in keybinds)
		{
			keybind.Value.isConsumed = false;
		}
	}

	public void AddKeybind(Keybind keybind)
	{
		if (keybinds.ContainsKey(keybind.id))
		{
			Debug.LogError($"Tried adding the same keybind again. ID: {keybind.id}");
			return;
		}
		keybinds.Add(keybind.id, keybind);
		original.Add(keybind.id, keybind.keychord);
	}

	public void ResetKeybinds()
	{
		foreach (KeyValuePair<int, Keybind> keybind in keybinds)
		{
			Keybind value = keybind.Value;
			if (original.TryGetValue(keybind.Key, out var value2))
			{
				value.keychord = value2;
				if (value.itemUI != null)
				{
					value.itemUI.input.SetTextWithoutNotify(value.ToString());
				}
			}
		}
	}

	private void RefreshKeybindLabels()
	{
		foreach (KeyValuePair<int, Keybind> keybind in keybinds)
		{
			Keybind value = keybind.Value;
			if (value.itemUI != null && value.itemUI.input != null)
			{
				value.itemUI.input.SetTextWithoutNotify(value.ToString());
			}
		}
	}

	public KeyChord GetOriginalKeybind(int id)
	{
		if (original.TryGetValue(id, out var value))
		{
			return value;
		}
		return KeyChord.None;
	}

	public Keybind GetKeyAction(int id)
	{
		if (keybinds.TryGetValue(id, out var value))
		{
			return value;
		}
		return null;
	}

	public bool GetInputActionKey(int id, bool ignoreCtrl = false, bool ignoreAlt = false, bool ignoreShift = false)
	{
		if (!isActive)
		{
			return false;
		}
		return GetKeyAction(id).GetKey(ignoreCtrl, ignoreAlt, ignoreShift);
	}

	public bool GetInputActionKeyDown(int id)
	{
		if (!isActive)
		{
			return false;
		}
		return GetKeyAction(id).GetKeyDown();
	}

	public bool GetInputActionKeyDownAndConsume(int id)
	{
		if (!isActive)
		{
			return false;
		}
		Keybind keyAction = GetKeyAction(id);
		if (keyAction.isConsumed)
		{
			return false;
		}
		keyAction.isConsumed = keyAction.GetKeyDown();
		return keyAction.isConsumed;
	}

	public bool GetInputActionKeyUp(int id)
	{
		if (!isActive)
		{
			return false;
		}
		return GetKeyAction(id).GetKeyUp();
	}

	public void SetControlsActive(bool activeIn)
	{
		isActive = activeIn;
	}
}
