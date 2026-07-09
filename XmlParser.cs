// XmlParser.cs
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;
using System.Xml.Linq;
using Newtonsoft.Json;

class XmlParser
{
    static void Main(string[] args)
    {
        string inputFile = null;
        string tag = null;
        string attr = null;
        bool toJson = false;

        for (int i = 0; i < args.Length; i++)
        {
            switch (args[i])
            {
                case "-i": case "--input": inputFile = args[++i]; break;
                case "-t": case "--tag": tag = args[++i]; break;
                case "-a": case "--attr": attr = args[++i]; break;
                case "--json": toJson = true; break;
                case "-h": case "--help": ShowHelp(); return;
            }
        }

        string xmlContent;
        if (inputFile != null)
        {
            xmlContent = File.ReadAllText(inputFile);
        }
        else
        {
            using (var reader = new StreamReader(Console.OpenStandardInput()))
            {
                xmlContent = reader.ReadToEnd();
            }
        }

        XDocument doc;
        try
        {
            doc = XDocument.Parse(xmlContent);
        }
        catch (XmlException e)
        {
            Console.Error.WriteLine($"XML Parse Error: {e.Message}");
            return;
        }

        if (tag != null)
        {
            var elements = doc.Descendants().Where(e => e.Name.LocalName == tag).ToList();
            if (elements.Count == 0)
                Console.WriteLine($"No elements with tag '{tag}' found.");
            else
                elements.ForEach(e => DisplayElement(e, 0));
        }
        else if (attr != null)
        {
            var parts = attr.Split('=');
            if (parts.Length != 2)
            {
                Console.Error.WriteLine("Invalid attribute format. Use key=value");
                return;
            }
            var key = parts[0];
            var value = parts[1];
            var elements = doc.Descendants().Where(e => e.Attribute(key)?.Value == value).ToList();
            if (elements.Count == 0)
                Console.WriteLine($"No elements with attr '{key}={value}' found.");
            else
                elements.ForEach(e => DisplayElement(e, 0));
        }
        else if (toJson)
        {
            var json = JsonConvert.SerializeXNode(doc, Formatting.Indented);
            Console.WriteLine(json);
        }
        else
        {
            DisplayElement(doc.Root, 0);
        }
    }

    static void DisplayElement(XElement el, int indent)
    {
        string prefix = new string(' ', indent * 2);
        string attrs = string.Join(" ", el.Attributes().Select(a => $"{a.Name}=\"{a.Value}\""));
        if (!el.HasElements && string.IsNullOrEmpty(el.Value.Trim()))
        {
            Console.WriteLine($"{prefix}<{el.Name}{(!string.IsNullOrEmpty(attrs) ? " " + attrs : "")}/>");
        }
        else if (!el.HasElements)
        {
            Console.WriteLine($"{prefix}<{el.Name}{(!string.IsNullOrEmpty(attrs) ? " " + attrs : "")}>{el.Value.Trim()}</{el.Name}>");
        }
        else
        {
            Console.WriteLine($"{prefix}<{el.Name}{(!string.IsNullOrEmpty(attrs) ? " " + attrs : "")}>");
            foreach (var child in el.Elements())
                DisplayElement(child, indent + 1);
            Console.WriteLine($"{prefix}</{el.Name}>");
        }
    }

    static void ShowHelp()
    {
        Console.WriteLine("Usage: dotnet run -- -i input.xml [-t tag] [-a key=value] [--json]");
    }
}
