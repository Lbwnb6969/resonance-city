using Unity.Collections;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

public class ScreenshotRequest
{
	public enum State
	{
		NotStarted,
		WaitingOnReadback,
		SavingToFile,
		Done
	}

	public string path;

	public int width;

	public int height;

	public UnityAction<ScreenshotRequest> screenshotFunction;

	public UnityAction onCompleteCallback;

	public State state;

	public RenderTexture renderTexture;

	public NativeArray<Color> pixelsNativeArray;

	public AsyncGPUReadbackRequest readbackRequest;

	public GraphicsFormat graphicsFormat;
}
