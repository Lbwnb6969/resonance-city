using UnityEngine;

public class OneOffEffect : PooledObject
{
	private bool useRealtime;

	private Color color;

	public bool AllowRelease = true;

	private ParticleSystem[] systems;

	public bool UseRealtime
	{
		get
		{
			return useRealtime;
		}
		set
		{
			if (value != useRealtime)
			{
				if (systems == null)
				{
					systems = GetComponentsInChildren<ParticleSystem>();
				}
				for (int i = 0; i < systems.Length; i++)
				{
					ParticleSystem.MainModule main = systems[i].main;
					main.useUnscaledTime = value;
				}
			}
		}
	}

	public Color Color
	{
		get
		{
			return color;
		}
		set
		{
			color = value;
			ParticleSystem[] componentsInChildren = GetComponentsInChildren<ParticleSystem>();
			for (int i = 0; i < componentsInChildren.Length; i++)
			{
				ParticleSystem.MainModule main = componentsInChildren[i].main;
				main.startColor = color;
			}
		}
	}

	public OneOffEffect Create(Vector3 pos)
	{
		OneOffEffect obj = Alloc(pos) as OneOffEffect;
		obj.Init();
		obj.Stop();
		return obj;
	}

	public OneOffEffect Create(Vector3 pos, Quaternion rot)
	{
		OneOffEffect obj = Alloc(pos, rot) as OneOffEffect;
		obj.Init();
		obj.Stop();
		return obj;
	}

	public OneOffEffect CreateAndPlay(Vector3 pos)
	{
		OneOffEffect oneOffEffect = Create(pos);
		oneOffEffect.Play();
		return oneOffEffect;
	}

	public void CreateAndPlayVisibilityCheck(Vector3 pos, float maxDist = 60f)
	{
		if (!(Mathff.DistSqrd(pos, Cam.inst.CamPos) > maxDist * maxDist) && Cam.inst.IsInFrustum(pos))
		{
			Create(pos).Play();
		}
	}

	public void CreateAndPlayVisibilityCheck(Vector3 pos, Quaternion rot, float maxDist = 60f)
	{
		if (!(Mathff.DistSqrd(pos, Cam.inst.CamPos) > maxDist * maxDist) && Cam.inst.IsInFrustum(pos))
		{
			Create(pos, rot).Play();
		}
	}

	public OneOffEffect CreateAndPlay(Vector3 pos, Quaternion rot)
	{
		OneOffEffect oneOffEffect = Create(pos, rot);
		oneOffEffect.Play();
		return oneOffEffect;
	}

	private void Update()
	{
		if (!IsAlive() && AllowRelease)
		{
			Release();
		}
	}

	public virtual bool IsAlive()
	{
		bool flag = false;
		for (int i = 0; i < systems.Length; i++)
		{
			_ = systems[i].main;
			flag |= systems[i].IsAlive();
		}
		return flag;
	}

	public override void Init()
	{
		systems = GetComponentsInChildren<ParticleSystem>();
		base.Init();
	}

	public override void Shutdown()
	{
		base.Shutdown();
		UseRealtime = false;
	}

	public void DoRelease()
	{
		Stop();
		AllowRelease = true;
	}

	public void Play()
	{
		ParticleSystem[] componentsInChildren = GetComponentsInChildren<ParticleSystem>();
		for (int i = 0; i < componentsInChildren.Length; i++)
		{
			componentsInChildren[i].Play();
		}
	}

	public void Stop()
	{
		ParticleSystem[] componentsInChildren = GetComponentsInChildren<ParticleSystem>();
		for (int i = 0; i < componentsInChildren.Length; i++)
		{
			componentsInChildren[i].Stop();
		}
	}

	public void StopImmediately()
	{
		ParticleSystem[] componentsInChildren = GetComponentsInChildren<ParticleSystem>();
		for (int i = 0; i < componentsInChildren.Length; i++)
		{
			componentsInChildren[i].Stop(withChildren: true, ParticleSystemStopBehavior.StopEmittingAndClear);
		}
	}
}
