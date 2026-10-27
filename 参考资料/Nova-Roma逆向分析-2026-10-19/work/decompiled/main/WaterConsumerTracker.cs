using UnityEngine;

public class WaterConsumerTracker : LineTracker
{
	public static WaterConsumerTracker inst;

	public static ArrayExtRef<WaterConsumer> tempConsumers = new ArrayExtRef<WaterConsumer>(32);

	private Color wColor;

	public float yOffset;

	private void Awake()
	{
		inst = this;
		wColor = new Color(0.9f, 0.9f, 0.9f, 1f);
	}

	public void TrackWaterConsumers(WaterSupplier wSupplier)
	{
		if (wSupplier == null || wSupplier.b == null)
		{
			return;
		}
		tempConsumers.ClearFast();
		for (int i = 0; i < wSupplier.consumers.Count; i++)
		{
			WaterConsumer waterConsumer = wSupplier.consumers[i];
			tempConsumers.Add(waterConsumer);
			waterConsumer.b.highlight.SetOutlineImmediate(0);
		}
		for (int j = 0; j < tempConsumers.Count; j++)
		{
			WaterConsumer waterConsumer2 = tempConsumers.data[j];
			Building b = waterConsumer2.b;
			if (!(waterConsumer2 == null) && !(b == null))
			{
				startOffsetRadius = ((b.size.x > b.size.z) ? b.size.x : b.size.z) * 0.5f * 1.4142135f;
				Vector3 endPoint = b.Center();
				endPoint.y += yOffset + b.size.y;
				DisplayLine(wSupplier.b.Center(), endPoint, (waterConsumer2.availableWaterPercentage >= 0.001f) ? Color.white : wColor);
			}
		}
	}
}
