using System;
using System.Collections.Generic;
using Assets;
using UnityEngine;

public class CartSystem : MonoBehaviour
{
	[Serializable]
	public class CartSystemSaveData : SaveClass<CartSystem, CartSystemSaveData>
	{
		public List<TransportCart.CartData> cartData = new List<TransportCart.CartData>();

		public override CartSystemSaveData Pack(CartSystem obj)
		{
			cartData.Clear();
			for (int i = 0; i < obj.carts.Count; i++)
			{
				cartData.Add(obj.carts[i].GetCartData());
			}
			return this;
		}

		public override CartSystem Unpack(CartSystem obj)
		{
			for (int i = 0; i < cartData.Count; i++)
			{
				TransportCart component = UnityEngine.Object.Instantiate(obj.transportCartPrefab).GetComponent<TransportCart>();
				component.Init(-1);
				component.SetFromCartData(cartData[i]);
			}
			return obj;
		}
	}

	public static CartSystem inst;

	[NonSerialized]
	public List<TransportCart> carts = new List<TransportCart>();

	[NonSerialized]
	public List<TransportCart> toDestroy = new List<TransportCart>();

	public Transform transportCartPrefab;

	private void Awake()
	{
		inst = this;
	}

	public void Update()
	{
		_ = Time.deltaTime;
		MarkerDrawer.inst.Clear();
		for (int i = 0; i < carts.Count; i++)
		{
			if (carts[i].Equals(GameUI.inst.shipLogisticsUI.transport))
			{
				Vector3 pos = carts[i].GetPos();
				pos.y += 0.75f;
				MarkerDrawer.inst.AddPoint(pos);
				break;
			}
		}
		MarkerDrawer.inst.Draw();
	}

	public void Reset()
	{
		toDestroy.Clear();
		for (int i = 0; i < carts.Count; i++)
		{
			toDestroy.Add(carts[i]);
		}
		for (int j = 0; j < toDestroy.Count; j++)
		{
			UnityEngine.Object.Destroy(toDestroy[j].gameObject);
		}
		toDestroy.Clear();
		carts.Clear();
	}
}
