using UnityEngine;

namespace PixelCrushers.DialogueSystem.Demo;

[AddComponentMenu("")]
public class DieOnTakeDamage : MonoBehaviour
{
	public GameObject deadPrefab;

	private void TakeDamage(float damage)
	{
		if (deadPrefab != null)
		{
			GameObject gameObject = Object.Instantiate(deadPrefab, transform.position, transform.rotation);
			if (gameObject != null)
			{
				gameObject.transform.parent = transform.parent;
			}
		}
		Object.Destroy(base.gameObject);
	}

	private void Damage(float damage)
	{
		TakeDamage(damage);
	}
}
