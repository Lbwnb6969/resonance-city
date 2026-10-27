using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net.Sockets;
using System.Threading;
using UnityEngine;
using UnityEngine.Events;

public class TwitchIRC : MonoBehaviour
{
	public class MsgEvent : UnityEvent<TwitchChatMessage>
	{
	}

	public string oauth;

	public string nickName;

	private string channelName = string.Empty;

	private string server = "irc.twitch.tv";

	private int port = 6667;

	private bool allowRoomJoin;

	public MsgEvent messageRecievedEvent = new MsgEvent();

	private string buffer = string.Empty;

	private bool stopThreads;

	private Queue<string> commandQueue = new Queue<string>();

	private List<string> recievedMsgs = new List<string>();

	public string lastChannelJoined = "";

	private Thread inProc;

	private Thread outProc;

	private TcpClient sock;

	public bool joined;

	public bool pendingJoin;

	private void StartIRC()
	{
		sock = new TcpClient();
		sock.Connect(server, port);
		if (!sock.Connected)
		{
			UnityEngine.Debug.Log("Failed to connect!");
			return;
		}
		NetworkStream networkStream = sock.GetStream();
		StreamReader input = new StreamReader(networkStream);
		StreamWriter output = new StreamWriter(networkStream);
		output.WriteLine("PASS " + oauth);
		output.WriteLine("NICK " + nickName.ToLower());
		output.Flush();
		outProc = new Thread(() =>
		{
			IRCOutputProcedure(output);
		});
		outProc.Start();
		inProc = new Thread(() =>
		{
			IRCInputProcedure(input, networkStream);
		});
		inProc.Start();
	}

	private void IRCInputProcedure(TextReader input, NetworkStream networkStream)
	{
		while (!stopThreads)
		{
			if (!networkStream.DataAvailable)
			{
				continue;
			}
			buffer = input.ReadLine();
			UnityEngine.Debug.Log(buffer);
			if (buffer.Contains("PRIVMSG #"))
			{
				lock (recievedMsgs)
				{
					recievedMsgs.Add(buffer);
				}
			}
			if (buffer.Contains("JOIN #"))
			{
				lock (lastChannelJoined)
				{
					lastChannelJoined = buffer.Substring(buffer.LastIndexOf("JOIN #") + 6);
					pendingJoin = false;
					joined = lastChannelJoined == channelName;
				}
			}
			if (buffer.StartsWith("PING "))
			{
				SendCommand(buffer.Replace("PING", "PONG"));
			}
			if (buffer.Split(' ')[1] == "001")
			{
				allowRoomJoin = true;
			}
		}
	}

	private void IRCOutputProcedure(TextWriter output)
	{
		Stopwatch stopwatch = new Stopwatch();
		stopwatch.Start();
		while (!stopThreads)
		{
			lock (commandQueue)
			{
				if (commandQueue.Count > 0 && stopwatch.ElapsedMilliseconds > 1750)
				{
					output.WriteLine(commandQueue.Peek());
					output.Flush();
					commandQueue.Dequeue();
					stopwatch.Reset();
					stopwatch.Start();
				}
			}
		}
	}

	public void SwitchUsername(string newUsername)
	{
		if (allowRoomJoin)
		{
			if (!string.IsNullOrEmpty(channelName))
			{
				SendCommand("PART #" + channelName);
			}
			SendCommand("JOIN #" + newUsername);
			pendingJoin = true;
			joined = false;
			channelName = newUsername;
		}
	}

	public void SendCommand(string cmd)
	{
		UnityEngine.Debug.Log("Queuing> " + cmd);
		lock (commandQueue)
		{
			commandQueue.Enqueue(cmd);
		}
	}

	public void SendMsg(string msg)
	{
		lock (commandQueue)
		{
			commandQueue.Enqueue("PRIVMSG #" + channelName + " :" + msg);
		}
	}

	private void Start()
	{
	}

	private void OnEnable()
	{
		stopThreads = false;
		StartIRC();
	}

	private void OnDisable()
	{
		stopThreads = true;
	}

	private void OnDestroy()
	{
		stopThreads = true;
	}

	private void Update()
	{
		lock (recievedMsgs)
		{
			if (recievedMsgs.Count > 0)
			{
				for (int i = 0; i < recievedMsgs.Count; i++)
				{
					if (recievedMsgs[i].Length > 0)
					{
						messageRecievedEvent.Invoke(CreateChatObject(recievedMsgs[i]));
					}
				}
				recievedMsgs.Clear();
			}
		}
		if (!sock.Connected)
		{
			UnityEngine.Debug.LogError("NOT CONNECTED");
		}
	}

	private TwitchChatMessage CreateChatObject(string msg)
	{
		string username = msg.Substring(1, msg.IndexOf("!", StringComparison.InvariantCulture) - 1);
		string text = msg.Substring(msg.IndexOf("PRIVMSG") + 8);
		string text2 = text.Substring(text.IndexOf(' ') + 1);
		return new TwitchChatMessage
		{
			username = username,
			message = text2.Substring(1)
		};
	}
}
