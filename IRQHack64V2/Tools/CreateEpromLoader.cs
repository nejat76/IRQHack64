using System;
using System.Collections.Generic;
using System.IO;

public class MyClass
{
	public static void RunSnippet(string inputFile, string outputFile, int[] positionArray)
	{		
		Console.Out.WriteLine("Processing " + inputFile);
		byte[] epromFile = new byte[65536];
		byte[] file = File.ReadAllBytes(inputFile);
		
		for (int i = 0;i<256;i++) {
			for (int j = 0;j<positionArray.Length;j++) {
				file[positionArray[j]] = (byte) i;	
			}
			
			Array.Copy(file, 0, epromFile, i * 256, 256);
		}
		
		Console.Out.WriteLine("Writing result : " + outputFile);
		File.WriteAllBytes(outputFile, epromFile);
		Console.Out.WriteLine("Done!");
	}
	
	#region Helper methods
	
	public static void Main(string[] args)
	{
		string usage = "Örn. Kullanım şekli : CreateEpromLoader.exe infile outfile 160 191";
		try
		{
			int argLength = args.Length;
			if (argLength<3) throw new Exception(usage);
			int[] positionArray = new int[argLength-2];
			for (int i=0;i<argLength-2;i++) {
				if (!Int32.TryParse(args[2+i], out positionArray[i])) {
					throw new Exception(usage);
				}
			}
			
			for (int i=0;i<positionArray.Length;i++) {
				Console.Out.WriteLine(String.Format("Will change position {0}", positionArray[i]));
			}
			
			RunSnippet(args[0], args[1], positionArray);
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