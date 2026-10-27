using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using TMPro;
using UnityEngine;

public class StoreInfo : MonoBehaviour
{
	[Serializable]
	private class InventoryObject
	{
		public InventoryLevels[] inventory_levels;
	}

	[Serializable]
	private class InventoryLevels
	{
		public string inventory_item_id;

		public string available;
	}

	public TextMeshProUGUI remainingText;

	public GameObject visibilityLayer;

	private WWW www;

	public void OnClickedStore()
	{
		Process.Start("https://shop.lionshieldstudios.com/collections/frontpage/products/dragon-plushie-w-imaginary-firebreath-%F0%9F%94%A5-limited-run");
		SfxSystem.PlayUiSelect();
	}

	private void OnEnable()
	{
		Dictionary<string, string> dictionary = new Dictionary<string, string>();
		dictionary.Add("Authorization", "Basic MTQwMWNmZmFhMWViZWE5MGMxZjRmYzdlYjYwYjRlNWY6ZjJlNzYxOTI0ZTFkNGUyYjE5NzJhYTBkNTNkYTJlNzA =");
		www = new WWW("https://kingdoms-and-castles-merch.myshopify.com/admin/api/2019-10/locations/18519621687/inventory_levels.json", null, dictionary);
	}

	private void OnDisable()
	{
		visibilityLayer.SetActive(value: false);
	}

	private void Update()
	{
		if (www == null || !www.isDone)
		{
			return;
		}
		InventoryObject inventoryObject = JsonUtility.FromJson<InventoryObject>(www.text);
		if (inventoryObject != null && inventoryObject.inventory_levels != null)
		{
			InventoryLevels inventoryLevels = inventoryObject.inventory_levels.FirstOrDefault((InventoryLevels x) => x.inventory_item_id == "32577240170611");
			if (inventoryLevels != null)
			{
				remainingText.text = "Only " + inventoryLevels.available + " remain!";
				visibilityLayer.SetActive(int.Parse(inventoryLevels.available) > 0);
			}
		}
		www = null;
	}
}
