using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityStandardAssets.ImageEffects;

public class ScreenshotManager : MonoBehaviour
{
	public static ScreenshotManager inst;

	public List<ScreenshotRequest> requests = new List<ScreenshotRequest>();

	private bool screenshotMode;

	private void Start()
	{
		inst = this;
	}

	private void Update()
	{
		StartCoroutine(EndOfFrameUpdate());
	}

	private IEnumerator EndOfFrameUpdate()
	{
		yield return new WaitForEndOfFrame();
		if (ReadyForScreenshot())
		{
			ProcessRequests();
		}
	}

	private void SetupScreenshotMode()
	{
		TreeSystem.forceVisibleAll = true;
		InWorldExclamation.hideForScreenshots = true;
		screenshotMode = true;
	}

	private void EndScreenshotMode()
	{
		TreeSystem.forceVisibleAll = false;
		InWorldExclamation.hideForScreenshots = false;
		screenshotMode = false;
	}

	public bool ReadyForScreenshot()
	{
		int num = 0;
		for (int i = 0; i < requests.Count; i++)
		{
			if (requests[i].state == ScreenshotRequest.State.NotStarted)
			{
				num++;
			}
		}
		if (num > 0 && !screenshotMode)
		{
			SetupScreenshotMode();
			return false;
		}
		if (num == 0 && screenshotMode)
		{
			EndScreenshotMode();
		}
		return requests.Count > 0;
	}

	public void ProcessRequests()
	{
		for (int i = 0; i < requests.Count; i++)
		{
			ScreenshotRequest screenshotRequest = requests[i];
			if (screenshotRequest.state == ScreenshotRequest.State.NotStarted)
			{
				screenshotRequest.screenshotFunction(screenshotRequest);
				screenshotRequest.pixelsNativeArray = new NativeArray<Color>(requests[i].width * requests[i].height, Allocator.Persistent, NativeArrayOptions.UninitializedMemory);
				screenshotRequest.readbackRequest = AsyncGPUReadback.RequestIntoNativeArray(ref screenshotRequest.pixelsNativeArray, screenshotRequest.renderTexture);
				screenshotRequest.state = ScreenshotRequest.State.WaitingOnReadback;
			}
			else if (screenshotRequest.state == ScreenshotRequest.State.WaitingOnReadback && screenshotRequest.readbackRequest.done)
			{
				GraphicsFormat graphicsFormat = screenshotRequest.renderTexture.graphicsFormat;
				RenderTexture.ReleaseTemporary(screenshotRequest.renderTexture);
				screenshotRequest.graphicsFormat = graphicsFormat;
				new Thread(SaveTextureThreaded).Start(screenshotRequest);
				screenshotRequest.state = ScreenshotRequest.State.SavingToFile;
			}
			else if (screenshotRequest.state == ScreenshotRequest.State.Done)
			{
				requests.RemoveAt(i);
				i--;
				if (screenshotRequest.pixelsNativeArray.IsCreated)
				{
					screenshotRequest.pixelsNativeArray.Dispose();
				}
				screenshotRequest.onCompleteCallback?.Invoke();
			}
		}
	}

	public void MakeScreenshotOfCamera(string path, int width, int height, UnityAction onCompleteCallback)
	{
		requests.Add(new ScreenshotRequest
		{
			path = path,
			width = width,
			height = height,
			screenshotFunction = CaptureView,
			onCompleteCallback = onCompleteCallback
		});
	}

	public void MakeScreenshotOfWorld(string path, int width, int height, UnityAction onCompleteCallback)
	{
		requests.Add(new ScreenshotRequest
		{
			path = path,
			width = width,
			height = height,
			screenshotFunction = CaptureWorld,
			onCompleteCallback = onCompleteCallback
		});
	}

	private void CaptureWorld(ScreenshotRequest request)
	{
		if (!(Camera.main == null))
		{
			bool fog = RenderSettings.fog;
			Vector3 position = Camera.main.transform.position;
			Quaternion rotation = Camera.main.transform.rotation;
			bool useOcclusionCulling = Camera.main.useOcclusionCulling;
			Vector3 landAveragedWorldCenter = TerrainGen.inst.landAveragedWorldCenter;
			Vector3 landWorldMin = TerrainGen.inst.landWorldMin;
			Vector3 landWorldMax = TerrainGen.inst.landWorldMax;
			float num = Mathf.Min(Vector3.Distance(landAveragedWorldCenter, landWorldMin), Vector3.Distance(landAveragedWorldCenter, landWorldMax), Vector3.Distance(landAveragedWorldCenter, new Vector3(landWorldMin.x, 0f, landWorldMax.z)), Vector3.Distance(landAveragedWorldCenter, new Vector3(landWorldMax.x, 0f, landWorldMin.z)));
			float f = MathF.PI / 180f * Camera.main.fieldOfView;
			float num2 = num / Mathf.Atan(f);
			Camera.main.transform.position = landAveragedWorldCenter + (new Vector3(-2f, 1f, 0f).normalized * (num2 + 3f) - Vector3.down * 10f);
			Camera.main.transform.LookAt(landAveragedWorldCenter + Vector3.down * 10f);
			RenderSettings.fog = false;
			if (Camera.main.GetComponent<GlobalFog>() != null)
			{
				Camera.main.GetComponent<GlobalFog>().enabled = false;
			}
			Camera.main.useOcclusionCulling = false;
			float num3 = 100000000f;
			Camera.main.cullingMatrix = Matrix4x4.Ortho(0f - num3, num3, 0f - num3, num3, 0f - num3, num3) * Camera.main.worldToCameraMatrix;
			CaptureView(request);
			if (Camera.main.GetComponent<GlobalFog>() != null)
			{
				Camera.main.GetComponent<GlobalFog>().enabled = true;
			}
			RenderSettings.fog = fog;
			Camera.main.transform.position = position;
			Camera.main.transform.rotation = rotation;
			Camera.main.ResetCullingMatrix();
			Camera.main.useOcclusionCulling = useOcclusionCulling;
		}
	}

	private void CaptureView(ScreenshotRequest request)
	{
		RenderTexture temporary = RenderTexture.GetTemporary(request.width, request.height, 24);
		Camera.main.targetTexture = temporary;
		Camera.main.Render();
		Camera.main.targetTexture = null;
		request.renderTexture = temporary;
	}

	private void SaveTextureThreaded(object data)
	{
		ScreenshotRequest screenshotRequest = (ScreenshotRequest)data;
		NativeArray<byte> nativeArray = ImageConversion.EncodeNativeArrayToJPG(screenshotRequest.pixelsNativeArray, screenshotRequest.graphicsFormat, (uint)screenshotRequest.width, (uint)screenshotRequest.height);
		File.WriteAllBytes(screenshotRequest.path, nativeArray.ToArray());
		screenshotRequest.state = ScreenshotRequest.State.Done;
	}
}
