using UnityEngine;

public class Tickable : MonoBehaviour
{
	private static Tickable[] tickables = new Tickable[25000];

	private static int count = 0;

	private int idx = -1;

	private static ArrayExt<Tickable> deferRemovalList = new ArrayExt<Tickable>(50);

	public static int frame = 0;

	private static bool insideTick = false;

	public virtual void OnEnableInternal()
	{
	}

	public virtual void OnDisableInternal()
	{
	}

	public static void Clear()
	{
		if (count != 0)
		{
			_ = 0;
		}
		for (int i = 0; i < count; i++)
		{
			tickables[i].idx = -1;
			tickables[i] = null;
		}
		count = 0;
	}

	private void OnEnable()
	{
		if (idx != -1)
		{
			_ = 0;
		}
		OnEnableInternal();
		idx = count;
		tickables[idx] = this;
		count++;
	}

	private void RemoveFromTickables()
	{
		if (idx != -1)
		{
			tickables[idx] = tickables[count - 1];
			tickables[idx].idx = idx;
			tickables[count - 1] = null;
			count--;
		}
		idx = -1;
	}

	private void VerifyCount(Tickable c, int d)
	{
		int num = 0;
		int i = 0;
		for (int num2 = count; i < num2; i++)
		{
			if (tickables[i] == c)
			{
				num++;
			}
		}
		if (num != d)
		{
			_ = 0;
		}
	}

	private void OnDisable()
	{
		if (insideTick)
		{
			RemoveFromTickablesDeferred();
			return;
		}
		OnDisableInternal();
		RemoveFromTickables();
	}

	public virtual void Tick(float dt, int currFrame)
	{
	}

	public void RemoveFromTickablesDeferred()
	{
		deferRemovalList.Add(this);
	}

	public static void TickAll(float dt)
	{
		frame++;
		insideTick = true;
		int i = 0;
		for (int num = count; i < num; i++)
		{
			tickables[i].Tick(dt, frame);
		}
		insideTick = false;
		int j = 0;
		for (int num2 = deferRemovalList.Count; j < num2; j++)
		{
			deferRemovalList.data[j].RemoveFromTickables();
			deferRemovalList.data[j].OnDisableInternal();
		}
		deferRemovalList.Clear();
	}
}
