using System;
using UnityEngine;

[Serializable]
public class TrainingAssignment
{
	[Serializable]
	public class TrainingAssignmentSaveData : SaveClass<TrainingAssignment, TrainingAssignmentSaveData>
	{
		public int gladiatorId;

		public string courseId;

		public float startTime;

		public float endTime;

		public int startYear;

		public int startSeasonId;

		public float startSeasonProgress;

		public int endYear;

		public int endSeasonId;

		public float currTime;

		public override TrainingAssignmentSaveData Pack(TrainingAssignment obj)
		{
			gladiatorId = obj.gladiatorId;
			courseId = obj.courseId;
			currTime = obj.currTime;
			return this;
		}

		public override TrainingAssignment Unpack(TrainingAssignment obj)
		{
			obj.gladiatorId = gladiatorId;
			obj.courseId = courseId;
			obj.currTime = currTime;
			return obj;
		}
	}

	public int gladiatorId;

	public string courseId;

	public float currTime;

	public TrainingAssignment()
	{
	}

	public TrainingAssignment(int gladiatorId, TrainingCourse course)
	{
		this.gladiatorId = gladiatorId;
		courseId = course.courseId;
		currTime = 0f;
	}

	public void Tick(float dt)
	{
		currTime += dt;
	}

	public int GetSeasonsRemaining()
	{
		float f = (GladiatorSystem.inst.GetTrainingCourse(courseId).GetDurationInGameTime() - currTime) / 112f;
		return Mathf.Max(1, Mathf.RoundToInt(f));
	}

	public float GetProgress()
	{
		TrainingCourse trainingCourse = GladiatorSystem.inst.GetTrainingCourse(courseId);
		return Mathf.Clamp01(currTime / trainingCourse.GetDurationInGameTime());
	}

	public bool IsComplete()
	{
		return GetProgress() >= 1f;
	}
}
