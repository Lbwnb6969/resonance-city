using System;
using System.IO;
using System.IO.Compression;
using SimpleJSON;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Networking;

public class SaveRepo : MonoBehaviour
{
	private static string url = "http://saverepo.kingdomsandcastles.com";

	public static void ServerIsAlive(UnityAction<bool> callback)
	{
		UnityWebRequest unityWebRequest = new UnityWebRequest(url + "/alive");
		UnityWebRequestAsyncOperation a = unityWebRequest.SendWebRequest();
		a.completed += (AsyncOperation async) =>
		{
			callback(a.webRequest.responseCode == 200);
		};
	}

	public static void CheckStillControlCode(string code, string editauthcode, UnityAction<bool, string, DateTime?> callback)
	{
		if (string.IsNullOrEmpty(editauthcode))
		{
			editauthcode = "invalid";
		}
		WWWForm wWWForm = new WWWForm();
		wWWForm.AddField("code", code);
		wWWForm.AddField("editauthcode", editauthcode);
		byte[] data = wWWForm.data;
		UnityWebRequest unityWebRequest = new UnityWebRequest(url + "/checkcodeownership", "POST");
		unityWebRequest.uploadHandler = new UploadHandlerRaw(data);
		unityWebRequest.downloadHandler = new DownloadHandlerBuffer();
		unityWebRequest.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		UnityWebRequestAsyncOperation a = unityWebRequest.SendWebRequest();
		a.completed += (AsyncOperation async) =>
		{
			JSONNode jSONNode = JSON.Parse(a.webRequest.downloadHandler.text);
			DateTime.TryParse(jSONNode["lastupload"], out var result);
			DateTime? arg = result;
			if (result < new DateTime(2011, 1, 1))
			{
				arg = null;
			}
			callback(a.webRequest.responseCode == 200 && bool.Parse(jSONNode["exists"]), code, arg);
		};
	}

	public static void CheckCodeExistence(string code, UnityAction<bool, string> callback)
	{
		WWWForm wWWForm = new WWWForm();
		wWWForm.AddField("code", code);
		byte[] data = wWWForm.data;
		UnityWebRequest unityWebRequest = new UnityWebRequest(url + "/checkcode", "POST");
		unityWebRequest.uploadHandler = new UploadHandlerRaw(data);
		unityWebRequest.downloadHandler = new DownloadHandlerBuffer();
		unityWebRequest.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		UnityWebRequestAsyncOperation a = unityWebRequest.SendWebRequest();
		a.completed += (AsyncOperation async) =>
		{
			callback(a.webRequest.responseCode == 200 && a.webRequest.downloadHandler.text == "true", code);
		};
	}

	public static void GetUniqueCode(UnityAction<bool, string, string> callback)
	{
		UnityWebRequest uwr = new UnityWebRequest(url + "/getnewcode", "POST");
		uwr.downloadHandler = new DownloadHandlerBuffer();
		UnityWebRequestAsyncOperation a = uwr.SendWebRequest();
		a.completed += (AsyncOperation async) =>
		{
			if (a.webRequest.responseCode == 200)
			{
				string[] array = uwr.downloadHandler.text.Split(':');
				callback(arg0: true, array[0], array[1]);
			}
			else
			{
				callback(arg0: false, null, null);
			}
		};
	}

	public static void UploadSave(string savePath, string screenshotBase64Png, string code, string editAuthCode, UnityAction<bool> callback)
	{
		string value = LoadSave.PackageSave(savePath, LoadSave.GetSaveDir() + "/upload.zip");
		WWWForm wWWForm = new WWWForm();
		wWWForm.AddField("code", code);
		wWWForm.AddField("editAuthCode", editAuthCode);
		wWWForm.AddField("screenshotFileData", screenshotBase64Png);
		wWWForm.AddField("base64FileData", value);
		byte[] data = wWWForm.data;
		UnityWebRequest unityWebRequest = new UnityWebRequest(url + "/upload", "POST");
		unityWebRequest.uploadHandler = new UploadHandlerRaw(data);
		unityWebRequest.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		UnityWebRequestAsyncOperation r = unityWebRequest.SendWebRequest();
		r.completed += (AsyncOperation async) =>
		{
			callback(r.webRequest.responseCode == 200);
		};
	}

	public static void GetSave(string code, UnityAction<bool, byte[]> callback)
	{
		WWWForm wWWForm = new WWWForm();
		wWWForm.AddField("code", code);
		byte[] data = wWWForm.data;
		UnityWebRequest unityWebRequest = new UnityWebRequest(url + "/retrieve", "POST");
		unityWebRequest.uploadHandler = new UploadHandlerRaw(data);
		unityWebRequest.downloadHandler = new DownloadHandlerBuffer();
		unityWebRequest.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		UnityWebRequestAsyncOperation r = unityWebRequest.SendWebRequest();
		r.completed += (AsyncOperation async) =>
		{
			bool arg = r.webRequest.responseCode == 200 && !string.IsNullOrEmpty(r.webRequest.downloadHandler.text);
			callback(arg, Convert.FromBase64String(r.webRequest.downloadHandler.text));
		};
	}

	public static void GetScreenshot(string code, UnityAction<bool, Texture2D> callback)
	{
		WWWForm wWWForm = new WWWForm();
		wWWForm.AddField("code", code);
		_ = wWWForm.data;
		UnityWebRequest texture = UnityWebRequestTexture.GetTexture(url + "/" + code + "/screenshot", nonReadable: false);
		UnityWebRequestAsyncOperation r = texture.SendWebRequest();
		r.completed += (AsyncOperation async) =>
		{
			Texture2D texture2D = null;
			bool flag = r.webRequest.result == UnityWebRequest.Result.Success;
			if (flag)
			{
				texture2D = ((DownloadHandlerTexture)r.webRequest.downloadHandler).texture;
				flag &= texture2D != null;
			}
			callback(flag, texture2D);
		};
	}

	public static string WriteSaveDataToDisk(byte[] binary)
	{
		string text = Path.Combine(LoadSave.GetSaveDir(), "toLoad.zip");
		FileStream fileStream = new FileStream(text, FileMode.Create);
		new BinaryWriter(fileStream).Write(binary);
		fileStream.Close();
		LoadSave.ReturnSave();
		string text2 = Path.Combine(LoadSave.GetSaveDir() + "/fromrepo/");
		if (Directory.Exists(text2))
		{
			Directory.Delete(text2, recursive: true);
		}
		ZipFile.ExtractToDirectory(text, text2);
		File.Delete(text);
		return text2;
	}

	public static bool LoadSaveFile(string path)
	{
		bool result = LoadSave.OpenSaveFromRepo(path);
		Directory.Delete(path, recursive: true);
		return result;
	}
}
