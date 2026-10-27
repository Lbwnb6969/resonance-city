using System.Threading;
using UnityEngine;

public class ThreadedPathing
{
	private Pathfinder[] pather;

	private volatile bool shutdown;

	private ArrayExt<GamePath> requestedPaths = new ArrayExt<GamePath>(1000);

	private ArrayExt<GamePath>[] pathsToCalculate;

	private Thread[] workerThreads;

	private static int numWorkerThreads = 6;

	private AutoResetEvent[] workerWaitHandle;

	private Countdown mainWaitHandle = new Countdown();

	public bool RequestPath(GamePath newPath)
	{
		if (newPath.status != GamePath.Status.Finding)
		{
			bool flag = false;
			if (newPath.lastEndX == (int)newPath.end.x && newPath.lastEndZ == (int)newPath.end.z && newPath.lastGridID == World.inst.pathGridId)
			{
				int num = (int)newPath.start.x;
				int num2 = (int)newPath.start.z;
				int num3 = (int)newPath.end.x;
				int num4 = (int)newPath.end.z;
				if (num == num3 && num2 == num4)
				{
					newPath.result.ClearFast();
					newPath.result.Add(newPath.end);
					flag = true;
				}
				else
				{
					for (int i = 0; i < newPath.result.Count; i++)
					{
						int num5 = (int)newPath.result.data[i].x;
						int num6 = (int)newPath.result.data[i].z;
						if (num5 == num && num6 == num2)
						{
							newPath.result.RemoveRange(0, i + 1);
							flag = true;
							break;
						}
					}
				}
			}
			if (!flag)
			{
				newPath.status = GamePath.Status.Finding;
				requestedPaths.Add(newPath);
				newPath.lastStartX = (int)newPath.start.x;
				newPath.lastStartZ = (int)newPath.start.z;
				newPath.lastEndX = (int)newPath.end.x;
				newPath.lastEndZ = (int)newPath.end.z;
				newPath.lastGridID = World.inst.pathGridId;
			}
			else
			{
				newPath.status = GamePath.Status.Complete;
			}
			return true;
		}
		return false;
	}

	private void CalculatePaths(object data)
	{
		int num = (int)data;
		workerWaitHandle[num].Set();
		while (!shutdown)
		{
			workerWaitHandle[num].WaitOne();
			for (int i = 0; i < pathsToCalculate[num].Count; i++)
			{
				try
				{
					GamePath gamePath = pathsToCalculate[num].data[i];
					Vector3 start = gamePath.start;
					Vector3 end = gamePath.end;
					do
					{
						start = gamePath.start;
						end = gamePath.end;
						switch (gamePath.pathType)
						{
						case GamePath.PathType.VillagerPath:
							if (PathCell.GetFootPathCost(World.inst.GetPathCell(end), gamePath.teamId) >= PathCell.footPathObstructionCost)
							{
								pather[num].FindPath(end, startUseUpperGrid: false, start, endUseUpperGrid: false, ref gamePath.result, PathCell.NoBlock, PathCell.NoBlock, PathCell.GetFootPathCost, gamePath.teamId, doDiagonal: true, doTrimming: false, allowUpperGrid: false);
								for (int l = 0; l < gamePath.result.Count / 2; l++)
								{
									Vector3 vector2 = gamePath.result.data[l];
									gamePath.result.data[l] = gamePath.result.data[gamePath.result.Count - 1 - l];
									gamePath.result.data[gamePath.result.Count - 1 - l] = vector2;
								}
								if (gamePath.result.Count < 1)
								{
									break;
								}
								int num4 = (int)start.x;
								int num5 = (int)start.z;
								for (int m = 0; m < gamePath.result.Count; m++)
								{
									if ((int)gamePath.result.data[m].x == num4 && (int)gamePath.result.data[m].z == num5)
									{
										gamePath.result.RemoveAt(m);
										m--;
									}
								}
								gamePath.result.Add(end);
							}
							else
							{
								pather[num].FindPath(start, startUseUpperGrid: false, end, endUseUpperGrid: false, ref gamePath.result, PathCell.NoBlock, PathCell.NoBlock, PathCell.GetFootPathCost, gamePath.teamId, doDiagonal: true, doTrimming: false, allowUpperGrid: false);
							}
							break;
						case GamePath.PathType.MilitaryPathPostBlock:
						case GamePath.PathType.EnvoyPathPostBlock:
						{
							bool flag = false;
							bool flag2 = false;
							if (gamePath.pathType == GamePath.PathType.MilitaryPathPostBlock)
							{
								pather[num].FindPath(start, flag, end, flag2, ref gamePath.result, PathCell.NoBlock, PathCell.GetBlocksFootPathForArmies, PathCell.GetMilitaryFootPathCost, gamePath.teamId, doDiagonal: false, doTrimming: true, allowUpperGrid: true);
							}
							else
							{
								pather[num].FindPath(start, flag, end, flag2, ref gamePath.result, PathCell.NoBlock, PathCell.GetBlocksFootPathForEnvoys, PathCell.GetEnvoyFootPathCost, gamePath.teamId, doDiagonal: false, doTrimming: true, allowUpperGrid: true);
							}
							if (gamePath.result.Count <= 0)
							{
								if (gamePath.pathType == GamePath.PathType.MilitaryPathPostBlock)
								{
									pather[num].FindPath(start, flag, end, !flag2, ref gamePath.result, PathCell.NoBlock, PathCell.GetBlocksFootPathForArmies, PathCell.GetMilitaryFootPathCost, gamePath.teamId, doDiagonal: false, doTrimming: true, allowUpperGrid: true);
								}
								else
								{
									pather[num].FindPath(start, flag, end, !flag2, ref gamePath.result, PathCell.NoBlock, PathCell.GetBlocksFootPathForEnvoys, PathCell.GetEnvoyFootPathCost, gamePath.teamId, doDiagonal: false, doTrimming: true, allowUpperGrid: true);
								}
							}
							if ((gamePath.result.Count <= 0) & flag)
							{
								if (gamePath.pathType == GamePath.PathType.MilitaryPathPostBlock)
								{
									pather[num].FindPath(start, !flag, end, flag2, ref gamePath.result, PathCell.NoBlock, PathCell.GetBlocksFootPathForArmies, PathCell.GetMilitaryFootPathCost, gamePath.teamId, doDiagonal: false, doTrimming: true, allowUpperGrid: true);
								}
								else
								{
									pather[num].FindPath(start, !flag, end, flag2, ref gamePath.result, PathCell.NoBlock, PathCell.GetBlocksFootPathForEnvoys, PathCell.GetEnvoyFootPathCost, gamePath.teamId, doDiagonal: false, doTrimming: true, allowUpperGrid: true);
								}
							}
							break;
						}
						case GamePath.PathType.OgrePathPostBlock:
							pather[num].FindPath(start, startUseUpperGrid: false, end, endUseUpperGrid: false, ref gamePath.result, PathCell.NoBlock, PathCell.GetBlocksFootPathForOgres, PathCell.GetOgreFootPathCost, gamePath.teamId, doDiagonal: false, doTrimming: true, allowUpperGrid: false);
							break;
						case GamePath.PathType.BoatPathPostBlock:
							if (PathCell.GetBoatPathCost(World.inst.GetPathCell(end), gamePath.teamId) >= PathCell.waterBlockedCost - 10)
							{
								pather[num].FindPath(end, startUseUpperGrid: false, start, endUseUpperGrid: false, ref gamePath.result, PathCell.NoBlock, PathCell.GetBlocksWaterPath, PathCell.GetBoatPathCost, gamePath.teamId, doDiagonal: false, doTrimming: true, allowUpperGrid: false);
								for (int j = 0; j < gamePath.result.Count / 2; j++)
								{
									Vector3 vector = gamePath.result.data[j];
									gamePath.result.data[j] = gamePath.result.data[gamePath.result.Count - 1 - j];
									gamePath.result.data[gamePath.result.Count - 1 - j] = vector;
								}
								if (gamePath.result.Count < 1)
								{
									break;
								}
								int num2 = (int)start.x;
								int num3 = (int)start.z;
								for (int k = 0; k < gamePath.result.Count; k++)
								{
									if ((int)gamePath.result.data[k].x == num2 && (int)gamePath.result.data[k].z == num3)
									{
										gamePath.result.RemoveAt(k);
										k--;
									}
								}
								gamePath.result.Add(end);
							}
							else
							{
								pather[num].FindPath(start, startUseUpperGrid: false, end, endUseUpperGrid: false, ref gamePath.result, PathCell.NoBlock, PathCell.GetBlocksWaterPath, PathCell.GetBoatPathCost, gamePath.teamId, doDiagonal: false, doTrimming: true, allowUpperGrid: false);
							}
							break;
						case GamePath.PathType.TransportCartPathPostBlock:
							pather[num].FindPath(start, startUseUpperGrid: false, end, endUseUpperGrid: false, ref gamePath.result, PathCell.NoBlock, PathCell.GetBlocksFootPathForTransportCart, PathCell.GetTransportCartFootPathCost, gamePath.teamId, doDiagonal: false, doTrimming: false, allowUpperGrid: false);
							break;
						case GamePath.PathType.HydraPath:
							pather[num].FindPath(start, startUseUpperGrid: false, end, endUseUpperGrid: false, ref gamePath.result, PathCell.NoBlock, PathCell.GetBlocksFootPathForHydra, PathCell.GetHydraFootPathCost, gamePath.teamId, doDiagonal: false, doTrimming: true, allowUpperGrid: false);
							break;
						}
					}
					while (start != gamePath.start || end != gamePath.end);
					pathsToCalculate[num].data[i].status = GamePath.Status.Complete;
				}
				catch
				{
					_ = 0;
				}
			}
			mainWaitHandle.Signal();
		}
	}

	public void Shutdown()
	{
		if (workerThreads != null)
		{
			for (int i = 0; i < workerThreads.Length; i++)
			{
				if (workerThreads[i] != null)
				{
					workerWaitHandle[i].Set();
					shutdown = true;
					if (!workerThreads[i].Join(1000))
					{
						workerThreads[i].Abort();
					}
					shutdown = false;
				}
				workerThreads[i] = null;
			}
			workerThreads = null;
		}
		if (pather == null)
		{
			return;
		}
		for (int j = 0; j < pather.Length; j++)
		{
			if (pather[j] != null)
			{
				pather[j].Shutdown();
			}
			pather[j] = null;
		}
	}

	public void Reset(int width, int height)
	{
		Shutdown();
		requestedPaths.Clear();
		if (pathsToCalculate == null)
		{
			pathsToCalculate = new ArrayExt<GamePath>[numWorkerThreads];
			for (int i = 0; i < pathsToCalculate.Length; i++)
			{
				pathsToCalculate[i] = new ArrayExt<GamePath>(50);
			}
		}
		else
		{
			for (int j = 0; j < pathsToCalculate.Length; j++)
			{
				pathsToCalculate[j].Clear();
			}
		}
		if (pather == null)
		{
			pather = new Pathfinder[numWorkerThreads];
		}
		for (int k = 0; k < pather.Length; k++)
		{
			if (pather[k] == null)
			{
				pather[k] = new Pathfinder();
			}
			pather[k].InitGrid(width, height);
		}
		if (workerWaitHandle != null)
		{
			for (int l = 0; l < workerWaitHandle.Length; l++)
			{
				workerWaitHandle[l].Close();
			}
		}
		if (workerWaitHandle == null)
		{
			workerWaitHandle = new AutoResetEvent[numWorkerThreads];
		}
		for (int m = 0; m < workerWaitHandle.Length; m++)
		{
			workerWaitHandle[m] = new AutoResetEvent(initialState: false);
		}
		mainWaitHandle = new Countdown(numWorkerThreads);
		workerThreads = new Thread[numWorkerThreads];
		for (int n = 0; n < workerThreads.Length; n++)
		{
			workerThreads[n] = new Thread(CalculatePaths);
			workerThreads[n].Start(n);
		}
	}

	public void WaitForThread()
	{
		if (workerThreads != null)
		{
			mainWaitHandle.Wait();
			mainWaitHandle.AddCount(numWorkerThreads);
			for (int i = 0; i < pathsToCalculate.Length; i++)
			{
				pathsToCalculate[i].Clear();
			}
			int num = 0;
			for (int j = 0; j < requestedPaths.Count; j++)
			{
				pathsToCalculate[num].Add(requestedPaths.data[j]);
				num = (num + 1) % workerThreads.Length;
			}
			requestedPaths.Clear();
			for (int k = 0; k < workerWaitHandle.Length; k++)
			{
				workerWaitHandle[k].Set();
			}
		}
	}
}
