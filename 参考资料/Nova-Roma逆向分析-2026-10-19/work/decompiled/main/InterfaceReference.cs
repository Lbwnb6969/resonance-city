using System;
using UnityEngine;

[Serializable]
public class InterfaceReference<TInterface, TObject> where TInterface : class where TObject : UnityEngine.Object
{
	[SerializeField]
	[HideInInspector]
	private TObject underlyingValue;

	public TInterface Value
	{
		get
		{
			TObject val = underlyingValue;
			if ((object)val != null)
			{
				if (val is TInterface result)
				{
					return result;
				}
				throw new InvalidOperationException(string.Format("{0} needs to implement interface {1}.", underlyingValue, "TInterface"));
			}
			return null;
		}
		set
		{
			TObject val2;
			if (value != null)
			{
				if (!(value is TObject val))
				{
					throw new ArgumentException($"{value} needs to be of type {typeof(TObject)}.", string.Empty);
				}
				val2 = val;
			}
			else
			{
				val2 = null;
			}
			underlyingValue = val2;
		}
	}

	public TObject UnderlyingValue
	{
		get
		{
			return underlyingValue;
		}
		set
		{
			underlyingValue = value;
		}
	}

	public InterfaceReference()
	{
	}

	public InterfaceReference(TObject target)
	{
		underlyingValue = target;
	}

	public InterfaceReference(TInterface @interface)
	{
		underlyingValue = @interface as TObject;
	}

	public static implicit operator TInterface(InterfaceReference<TInterface, TObject> obj)
	{
		return obj.Value;
	}
}
[Serializable]
public class InterfaceReference<TInterface> : InterfaceReference<TInterface, UnityEngine.Object> where TInterface : class
{
}
