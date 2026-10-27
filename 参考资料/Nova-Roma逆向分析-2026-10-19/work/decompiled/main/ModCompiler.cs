using System;
using System.IO;
using RoslynCSharp;
using RoslynCSharp.Compiler;
using Trivial.CodeSecurity;
using UnityEngine;

public static class ModCompiler
{
	public delegate void Log(string log);

	private static ScriptDomain domain;

	public static ScriptAssembly LoadMod(string path, Log log, out bool validAndLoadable)
	{
		validAndLoadable = false;
		if (domain == null)
		{
			domain = ScriptDomain.CreateDomain("ModDomain");
			log("Loading assemblies");
			string path2 = "";
			string text = "Managed";
			string text2 = "Managed";
			string text3 = "Resources/Data/Managed";
			if (Application.platform == RuntimePlatform.WindowsPlayer)
			{
				path2 = text;
			}
			if (Application.platform == RuntimePlatform.OSXPlayer)
			{
				path2 = text3;
			}
			if (Application.platform == RuntimePlatform.LinuxPlayer)
			{
				path2 = text2;
			}
			string text4 = Path.Combine(Application.dataPath, path2);
			Debug.Log(text4);
			string[] files = Directory.GetFiles(text4, "*dll");
			foreach (string text5 in files)
			{
				Debug.Log(text5);
				domain.RoslynCompilerService.References.Add(text5);
			}
		}
		log("Loading mod at path: " + path);
		string[] files2 = Directory.GetFiles(path, "*.cs", SearchOption.AllDirectories);
		if (files2.Length == 0)
		{
			log("Error: No source files");
			validAndLoadable = false;
			return null;
		}
		ScriptAssembly scriptAssembly;
		try
		{
			scriptAssembly = domain.CompileAndLoadFiles(files2);
		}
		catch (Exception ex)
		{
			log("Error: " + ex.Message);
			validAndLoadable = false;
			return null;
		}
		bool flag = false;
		bool flag2 = false;
		CompilationResult compileResult = domain.CompileResult;
		if (compileResult != null)
		{
			flag = compileResult.Success;
			CompilationError[] errors = compileResult.Errors;
			foreach (CompilationError compilationError in errors)
			{
				string text6 = "<color=white>";
				if (compilationError.IsError)
				{
					text6 = "<color=red>";
				}
				if (compilationError.IsWarning)
				{
					text6 = "<color=yellow>";
				}
				log($"{text6}{compilationError.SourceFile}:{compilationError.SourceLine}::{compilationError.SourceLine}\n{compilationError.Message}</color>");
			}
		}
		CodeSecurityReport securityResult = domain.SecurityResult;
		if (securityResult != null)
		{
			flag2 = securityResult.IsSecurityVerified;
			foreach (IllegalAssemblyReference illegalAssemblyReference in securityResult.IllegalAssemblyReferences)
			{
				log(illegalAssemblyReference.IllegalUsage.GetFullUsageString());
			}
			foreach (IllegalMemberReference illegalMemberReference in securityResult.IllegalMemberReferences)
			{
				log($"{illegalMemberReference.ReferenceUsageCount} illegal reference(s) to member '{illegalMemberReference.ReferencedMember}' of type [{illegalMemberReference.ReferencedType}]");
				foreach (IllegalReferenceUsage referenceUsage in illegalMemberReference.ReferenceUsages)
				{
					log(referenceUsage.GetFullUsageString());
				}
			}
			foreach (IllegalNamespaceReference illegalNamespaceReference in securityResult.IllegalNamespaceReferences)
			{
				log($"{illegalNamespaceReference.ReferenceUsages.Count} illegal namespace reference(s) to '{illegalNamespaceReference.ReferencedNamespace}']");
				foreach (IllegalReferenceUsage referenceUsage2 in illegalNamespaceReference.ReferenceUsages)
				{
					log(referenceUsage2.GetFullUsageString());
				}
				foreach (IllegalTypeReference indirectIllegalTypeReference in illegalNamespaceReference.IndirectIllegalTypeReferences)
				{
					log($"{indirectIllegalTypeReference.ReferenceUsageCount} illegal indirect type reference to type [{indirectIllegalTypeReference.ReferencedType}]");
					foreach (IllegalReferenceUsage referenceUsage3 in illegalNamespaceReference.ReferenceUsages)
					{
						log(referenceUsage3.GetFullUsageString() ?? "");
					}
				}
			}
			foreach (IllegalTypeReference illegalTypeReference in securityResult.IllegalTypeReferences)
			{
				log($"{illegalTypeReference.ReferenceUsageCount} illegal indirect type reference to type [{illegalTypeReference.ReferencedType}]");
				foreach (IllegalReferenceUsage referenceUsage4 in illegalTypeReference.ReferenceUsages)
				{
					log(referenceUsage4.GetFullUsageString() ?? "");
				}
			}
		}
		if ((scriptAssembly != null) & flag & flag2)
		{
			log("Compilation success");
		}
		else
		{
			log("Compilation failed" + (flag2 ? " with security exceptions." : "."));
		}
		if ((scriptAssembly != null) & flag & flag2)
		{
			int num = 0;
			int num2 = 0;
			ScriptType[] array = scriptAssembly.FindAllTypes();
			foreach (ScriptType obj in array)
			{
				if (obj.FindCachedMethod("OnScriptLoad", isStatic: false) != null)
				{
					num++;
				}
				if (obj.FindCachedMethod("SceneLoaded", isStatic: false) != null)
				{
					num++;
				}
				if (obj.FindCachedMethod("PreScriptLoad", isStatic: false) != null)
				{
					num2++;
				}
				if (obj.FindCachedMethod("Preload", isStatic: false) != null)
				{
					num2++;
				}
			}
			validAndLoadable = num > 0 || num2 > 0;
			if (num > 0 || num2 > 0)
			{
				if (num > 0)
				{
					log($"Found {num} SceneLoaded entry point(s).");
				}
				if (num2 > 0)
				{
					log($"Found {num2} Preload entry point(s).");
				}
			}
			else
			{
				log("Assembly was missing an SceneLoaded or Preload entry point.");
			}
		}
		return scriptAssembly;
	}

	public static void ClearDomain()
	{
		if (domain != null)
		{
			domain.Dispose();
			domain = null;
		}
	}
}
