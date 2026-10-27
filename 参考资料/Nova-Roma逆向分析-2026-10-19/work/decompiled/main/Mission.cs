using System;
using Assets.Code;

public class Mission
{
	public enum Status
	{
		NotStarted,
		InProgress,
		Failed,
		Complete
	}

	[Serializable]
	public class MissionSaveData<T, S> : SaveClass<T, S> where T : Mission where S : MissionSaveData<T, S>
	{
		public Status status;

		public override S Pack(T obj)
		{
			status = obj.status;
			return (S)this;
		}

		public override T Unpack(T obj)
		{
			obj.status = status;
			return obj;
		}
	}

	protected AIKingdom ownerKingdom;

	public string convo;

	public Status status;

	public Mission(AIKingdom owner)
	{
		ownerKingdom = owner;
	}

	public virtual string GetDescription()
	{
		return "";
	}

	public virtual string GetCondition()
	{
		return "";
	}

	public virtual void OnNewYear()
	{
	}

	public virtual void Update()
	{
	}

	public virtual void Dispose()
	{
	}

	public virtual bool TryCompleteWithGift(ResourceAmount giftAmount)
	{
		return false;
	}
}
