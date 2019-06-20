using System;
using System.Collections.Generic;
using System.IO;

public class MyClass
{
	public static void RunSnippet(string inputFile)
	{		
		Console.Out.WriteLine("Processing " + inputFile);

		byte[] file = File.ReadAllBytes(inputFile);
		
		int val = 0;
		for (int i = 0;i<file.Length;i++) {
			val = (val + file[i]) % 256;
		}
		
		Console.Out.WriteLine("Sum : " + val);
	}
	
	#region Helper methods
	
	public static void Main(string[] args)
	{
		string usage = "Örn. Kullanım şekli : CheckSum.exe infile";
		try
		{
			int argLength = args.Length;
			if (argLength<1) throw new Exception(usage);
		
			RunSnippet(args[0]);
		}
		catch (Exception e)
		{
			string error = string.Format("---\nThe following error occurred while executing the snippet:\n{0}\n---", e.ToString());
			Console.WriteLine(error);
		}
		finally
		{
			Console.Write("Press any key to continue...");
			Console.ReadKey();
		}
	}

	private static void WL(object text, params object[] args)
	{
		Console.WriteLine(text.ToString(), args);	
	}
	
	private static void RL()
	{
		Console.ReadLine();	
	}
	
	private static void Break() 
	{
		System.Diagnostics.Debugger.Break();
	}

	#endregion
}