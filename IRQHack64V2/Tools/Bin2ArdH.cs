using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

public class MyClass
{
	
	public static void RunSnippet(string inputFile, string outputFile, string sizeDeclaration, string variableDeclaration)
	{		
		Console.Out.WriteLine("Processing " + inputFile);
		StreamWriter writer = new StreamWriter(outputFile, false, Encoding.ASCII);
		byte[] file = File.ReadAllBytes(inputFile);
		string header = "int {0} = {1};\r\nstatic const unsigned char PROGMEM {2}[{3}]=";
		
		Console.Out.WriteLine("Writing result : " + outputFile);		
		writer.Write(String.Format(header, sizeDeclaration, file.Length, variableDeclaration, file.Length));
		writer.Write("\r\n{\r\n");
		
		int i = 0;
		while (i<file.Length) {
			for (int j=0;(j<16)&&(i<file.Length);j++) {
				if (i!=file.Length-1) {					
					writer.Write(String.Format("0x{0},", file[i].ToString("X2")));
				} else {
					writer.Write(String.Format("0x{0}", file[i].ToString("X2")));
				}
				i++;
			}
			writer.WriteLine();
		}
		writer.Write("\r\n};");
		writer.Close();
		Console.Out.WriteLine("Done!");
	}
	
	#region Helper methods
	
	public static void Main(string[] args)
	{
		try
		{
			//RunSnippet(args[0], args[1], args[2], args[3]);
			RunSnippet("C:\\6502\\New\\menu.prg", "c:\\6502\\New\\output.h", "data_len", "cartridgeData");
		}
		catch (Exception e)
		{
			string error = string.Format("---\nThe following error occurred while executing the snippet:\n{0}\n---", e.ToString());
			Console.WriteLine(error);
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