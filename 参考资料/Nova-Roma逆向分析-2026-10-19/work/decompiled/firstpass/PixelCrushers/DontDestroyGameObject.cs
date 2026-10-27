using UnityEngine;

namespace PixelCrushers;

[AddComponentMenu("")]
public class DontDestroyGameObject : MonoBehaviour
{
	private void Awake()
	{
		transform.SetParent(null);
		Object.DontDestroyOnLoad(gameObject);
	}
}
