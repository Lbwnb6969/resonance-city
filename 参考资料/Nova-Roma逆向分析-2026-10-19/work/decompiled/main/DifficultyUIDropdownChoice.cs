using System;
using System.Collections.Generic;
using UnityEngine;

public class DifficultyUIDropdownChoice : MonoBehaviour
{
	[SerializeField]
	private BetterDropdown dropdown;

	private readonly List<int> indexByOption = new List<int>();

	private Action<int> onOptionSelected;

	private bool listenerRegistered;

	private void Awake()
	{
		EnsureDropdownReference();
	}

	private void OnDestroy()
	{
		UnregisterListener();
		indexByOption.Clear();
		onOptionSelected = null;
	}

	public void Init((int, string)[] indexAndTerms, Action<int> onSelected)
	{
		EnsureDropdownReference();
		if (dropdown == null)
		{
			return;
		}
		UnregisterListener();
		dropdown.ClearOptions();
		indexByOption.Clear();
		onOptionSelected = onSelected;
		if (indexAndTerms != null)
		{
			for (int i = 0; i < indexAndTerms.Length; i++)
			{
				(int, string) tuple = indexAndTerms[i];
				BetterDropdown.OptionData item = new BetterDropdown.OptionData
				{
					term = tuple.Item2,
					text = tuple.Item2
				};
				dropdown.options.Add(item);
				indexByOption.Add(tuple.Item1);
			}
		}
		dropdown.SetValueWithoutNotify((indexByOption.Count <= 0) ? (-1) : 0);
		dropdown.RefreshShownValue();
		if (indexByOption.Count > 0)
		{
			dropdown.onValueSelected.AddListener(OnDropdownValueSelected);
			listenerRegistered = true;
		}
	}

	public bool TryGetIndexForSelection(out int index)
	{
		int optionIndex = ((dropdown != null) ? dropdown.value : (-1));
		return TryGetIndexForOption(optionIndex, out index);
	}

	public bool TryGetIndexForOption(int optionIndex, out int index)
	{
		if (optionIndex >= 0 && optionIndex < indexByOption.Count)
		{
			index = indexByOption[optionIndex];
			return true;
		}
		index = -1;
		return false;
	}

	private void OnDropdownValueSelected(int optionIndex)
	{
		if (TryGetIndexForOption(optionIndex, out var index))
		{
			onOptionSelected?.Invoke(index);
		}
	}

	public void SetOptionWithoutNotify(int arbitraryId)
	{
		int num = -1;
		for (int i = 0; i < indexByOption.Count; i++)
		{
			if (indexByOption[i] == arbitraryId)
			{
				num = i;
			}
		}
		if (num == -1)
		{
			num = 0;
		}
		dropdown.SetValueWithoutNotify(num);
	}

	private void EnsureDropdownReference()
	{
		if (!(dropdown != null))
		{
			dropdown = GetComponent<BetterDropdown>();
			if (dropdown == null)
			{
				dropdown = GetComponentInChildren<BetterDropdown>(includeInactive: true);
			}
			if (dropdown == null)
			{
				Debug.LogError("DifficultyUIDropdownChoice requires a BetterDropdown reference.", this);
			}
		}
	}

	private void UnregisterListener()
	{
		if (dropdown != null && listenerRegistered)
		{
			dropdown.onValueSelected.RemoveListener(OnDropdownValueSelected);
			listenerRegistered = false;
		}
	}
}
