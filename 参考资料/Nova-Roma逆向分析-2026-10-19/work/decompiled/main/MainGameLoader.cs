using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class MainGameLoader : MonoBehaviour
{
	public bool showDummyBranchWarning;

	public GameObject dummyBranchWarning;

	private static AsyncOperation asyncOperation;

	private static float showLogosForAtLeast;

	private static float blinkDuration;

	private static float stateTimer;

	public CanvasGroup splashScreenGroup;

	public Image[] splashScreenLogos;

	public TextMeshProUGUI[] splashScreenTexts;

	public TextMeshProUGUI convertingText;

	private static SaveMigrationProcess migration;

	private static World world;

	private void Start()
	{
		if (showDummyBranchWarning)
		{
			dummyBranchWarning.SetActive(value: true);
			return;
		}
		Object.DontDestroyOnLoad(splashScreenGroup.gameObject);
		Object.DontDestroyOnLoad(gameObject);
		migration = new SaveMigrationProcess();
		migration.Start(Application.persistentDataPath);
	}

	private void Update()
	{
		if (migration.IsDone)
		{
			convertingText.text = LocalizationManager.GetTranslation("startup_loading");
		}
		else if (migration.LegacyCount > 0)
		{
			string arg = migration.Converted + migration.Failed + 1 + "/" + migration.LegacyCount;
			convertingText.text = string.Format(LocalizationManager.GetTranslation("startup_converting_save"), arg);
		}
		else if (!migration.ScanComplete)
		{
			convertingText.text = LocalizationManager.GetTranslation("startup_scanning_saves");
		}
		else
		{
			convertingText.text = LocalizationManager.GetTranslation("startup_loading");
		}
		if (!IsSceneReadyToLoad())
		{
			return;
		}
		float num = Time.unscaledDeltaTime;
		if (num > 0.5f)
		{
			num = 0f;
		}
		if (splashScreenLogos[0].color.a > 0f)
		{
			float a = splashScreenLogos[0].color.a;
			a -= num;
			for (int i = 0; i < splashScreenLogos.Length; i++)
			{
				Color color = splashScreenLogos[i].color;
				color.a = a;
				splashScreenLogos[i].color = color;
			}
			for (int j = 0; j < splashScreenTexts.Length; j++)
			{
				Color color2 = splashScreenTexts[j].color;
				color2.a = a;
				splashScreenTexts[j].color = color2;
			}
		}
		else
		{
			splashScreenGroup.alpha -= num;
			if (splashScreenGroup.alpha <= 0f)
			{
				Object.Destroy(splashScreenGroup.gameObject);
				Object.Destroy(gameObject);
			}
		}
	}

	public static bool IsSceneReadyToLoad()
	{
		if (!migration.IsDone)
		{
			return false;
		}
		if (asyncOperation == null)
		{
			asyncOperation = SceneManager.LoadSceneAsync("simulation", LoadSceneMode.Single);
		}
		if (SceneManager.GetSceneByName("simulation").isLoaded)
		{
			if (!(world == null))
			{
				return world.ReadyToBeSeen();
			}
			GameObject gameObject = GameObject.Find("WorldLogic");
			if ((bool)gameObject)
			{
				world = gameObject.GetComponent<World>();
			}
		}
		return false;
	}
}
