using System.Collections;
using System.Collections.Generic;
using Assets.Code.UI;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SeedButtonUI : MonoBehaviour
{
	public TMP_InputField inputField;

	public Button previousSeed;

	public Button nextSeed;

	public static SeedButtonUI inst;

	public int currentSeed;

	public List<int> seeds = new List<int>(10);

	public ConsoleUIItem mapContainerItem;

	public ConsoleUIItem confirmWindowItem;

	private string lastSeedTxt = "";

	private int confirmedSeed;

	public Confirmation confirm;

	public Localize confirmTerm;

	private string[] combinations = new string[6] { "ISN", "IMS", "ILN", "LSS", "LMN", "LLS" };

	private Coroutine testCo;

	private bool testing;

	private int testSeed = 1;

	private void OnEnable()
	{
		if (inst == null)
		{
			inst = this;
			inputField.onSubmit.AddListener(OnNewSeedEntered);
			inputField.onSelect.AddListener((string val) =>
			{
				StartEdit();
			});
			inputField.onEndEdit.AddListener((string val) =>
			{
				EndEdit();
			});
			nextSeed.onClick.AddListener(OnNextSeed);
		}
		SetSeed(World.inst.seed);
		seeds.Clear();
		seeds.Add(World.inst.seed);
		currentSeed = 0;
	}

	private void StartEdit()
	{
		DisableHotkeys();
		lastSeedTxt = inputField.text;
	}

	private void EndEdit()
	{
		EnableHotkeys();
		if (!GamepadControl.inst.isControllerActive && lastSeedTxt != inputField.text)
		{
			OnNewSeedEntered(inputField.text);
		}
	}

	private void ShowConfirm(int next)
	{
		confirmedSeed = next;
		confirmTerm.Term = "Creative Mode Edit Changes Lost";
		mapContainerItem.Reset();
		confirm.ShowConfirmation(() =>
		{
			MoveToSeed(confirmedSeed);
			mapContainerItem.Hover();
		}, () =>
		{
			inputField.text = lastSeedTxt;
			mapContainerItem.Hover();
		});
	}

	private void ShowConfirmCustom(int next)
	{
		confirmedSeed = next;
		confirmTerm.Term = "Creative Mode Edit Changes Lost";
		mapContainerItem.Reset();
		confirm.ShowConfirmation(() =>
		{
			MoveToSeed(confirmedSeed);
			mapContainerItem.Hover();
		}, () =>
		{
			seeds.RemoveAt(next);
			inputField.text = lastSeedTxt;
			mapContainerItem.Hover();
		});
	}

	private void OnNextSeed()
	{
		if (Creative.inst.IsEnabled() && GameState.inst.mainMenuMode.mapEditUI.GetComponent<MapEdit>().dirty)
		{
			ShowConfirm(currentSeed + 1);
		}
		else
		{
			MoveToSeed(++currentSeed);
		}
	}

	private void MoveToSeed(int index)
	{
		if (index == -1)
		{
			int item = SRand.Range(1, int.MaxValue);
			seeds.Insert(0, item);
			currentSeed = 0;
		}
		else if (index >= seeds.Count)
		{
			int item2 = SRand.Range(1, int.MaxValue);
			seeds.Add(item2);
			currentSeed = seeds.Count - 1;
		}
		else
		{
			currentSeed = index;
		}
		GameState.inst.mainMenuMode.OnClickedRegenSeed(seeds[currentSeed]);
	}

	private void EnableHotkeys()
	{
		GameState.inst.AlphaNumericHotkeysEnabled = true;
	}

	private void DisableHotkeys()
	{
		GameState.inst.AlphaNumericHotkeysEnabled = false;
	}

	public void SetSeed(int seed)
	{
		inputField.onSubmit.RemoveListener(OnNewSeedEntered);
		inputField.text = World.inst.GetTextSeed();
		inputField.onSubmit.AddListener(OnNewSeedEntered);
	}

	private void OnNewSeedEntered(string seed)
	{
		bool flag = false;
		if (int.TryParse(seed, out var result))
		{
			flag = true;
		}
		else
		{
			if (seed.Length < 3)
			{
				return;
			}
			string text = seed.Substring(0, 1);
			string text2 = seed.Substring(1, 1);
			string text3 = seed.Substring(2, 1);
			if (!(text == "I"))
			{
				if (text == "L")
				{
					MapSettingsUI.inst.SetMapBias(World.MapBias.Land);
				}
			}
			else
			{
				MapSettingsUI.inst.SetMapBias(World.MapBias.Island);
			}
			switch (text2)
			{
			case "S":
				MapSettingsUI.inst.SetSizeBias(World.MapSize.Small);
				break;
			case "M":
				MapSettingsUI.inst.SetSizeBias(World.MapSize.Medium);
				break;
			case "L":
				MapSettingsUI.inst.SetSizeBias(World.MapSize.Large);
				break;
			}
			switch (text3)
			{
			case "N":
				MapSettingsUI.inst.SetRiverBias(World.MapRiverAmount.Normal);
				break;
			case "S":
			case "H":
				MapSettingsUI.inst.SetRiverBias(World.MapRiverAmount.High);
				break;
			case "V":
				MapSettingsUI.inst.SetRiverBias(World.MapRiverAmount.VeryHigh);
				break;
			}
			World.MapResourceAmount amount = World.MapResourceAmount.Normal;
			int startIndex = ((seed.Length > 3 && World.TryParseResourceAmountSeedChar(seed[3], out amount)) ? 4 : 3);
			MapSettingsUI.inst.SetResourceAmount(amount);
			flag = int.TryParse(seed.Substring(startIndex), out result);
		}
		if (flag)
		{
			seeds.Insert(currentSeed + 1, result);
			if (Creative.inst.IsEnabled() && GameState.inst.mainMenuMode.mapEditUI.GetComponent<MapEdit>().dirty)
			{
				ShowConfirmCustom(currentSeed + 1);
				return;
			}
			MoveToSeed(++currentSeed);
			lastSeedTxt = inputField.text;
		}
	}

	private IEnumerator SeedTest()
	{
		while (true)
		{
			string[] array = combinations;
			for (int i = 0; i < array.Length; i++)
			{
				string text = array[i] + testSeed;
				Debug.Log(text);
				OnNewSeedEntered(text);
				yield return null;
			}
			testSeed++;
		}
	}
}
