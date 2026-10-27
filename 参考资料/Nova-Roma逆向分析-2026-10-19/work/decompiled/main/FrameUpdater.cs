public struct FrameUpdater
{
	private int updateFrame;

	private int frameSpread;

	private int frameCount;

	public FrameUpdater(ref int frameID, int spread)
	{
		frameSpread = spread;
		updateFrame = frameID++;
		updateFrame %= frameSpread;
		frameCount = 0;
	}

	public void SetFrameSpread(int newFrameSpread)
	{
		float num = (float)updateFrame / (float)frameSpread;
		frameSpread = newFrameSpread;
		updateFrame = (int)((float)frameSpread * num);
	}

	public void Update()
	{
		frameCount++;
	}

	public bool Trigger()
	{
		return frameCount % frameSpread == updateFrame;
	}
}
