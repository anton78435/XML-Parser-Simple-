# 📂 XML Parser (Simple) – Multi‑Language Edition

A lightweight **XML parser** that reads, validates, and navigates XML documents.  
Supports searching for elements by tag name or attribute, displaying the tree structure, and converting XML to JSON.  
Built in **7 programming languages** – perfect for learning, integration, or quick XML introspection.

## ✨ Features
- **Parse XML** – reads XML from file or standard input.
- **Display tree** – prints the document structure with indentation (element names, attributes, text content).
- **Search by tag** – find all elements with a given tag name.
- **Search by attribute** – find elements with a specific attribute key/value.
- **Extract text** – get the text content of an element (ignores nested markup).
- **Convert to JSON** – transform the parsed XML into a JSON representation (optional).
- **Error handling** – reports syntax errors with line/column numbers.
- **Supports** – attributes, nested elements, CDATA, processing instructions, comments.

## 🗂 Languages & Files
| Language          | File               |
|-------------------|--------------------|
| Python            | `xml_parser.py`    |
| Go                | `xml_parser.go`    |
| JavaScript        | `xml_parser.js`    |
| C#                | `XmlParser.cs`     |
| Java              | `XmlParser.java`   |
| Ruby              | `xml_parser.rb`    |
| Swift             | `xml_parser.swift` |

## 🚀 How to Run
Each file is standalone – run it with the appropriate interpreter/compiler:

| Language | Command |
|----------|---------|
| Python   | `python xml_parser.py [-i input.xml] [-t tag] [-a key=value] [--to-json]` |
| Go       | `go run xml_parser.go -i input.xml -tag name -attr key=value -json` |
| JavaScript | `node xml_parser.js -i input.xml -t tag -a key=value --json` |
| C#       | `dotnet run -- -i input.xml -t tag -a key=value --json` (or compile and run) |
| Java     | `javac XmlParser.java && java XmlParser -i input.xml -tag name -attr key=value -json` |
| Ruby     | `ruby xml_parser.rb -i input.xml -t tag -a key=value --json` |
| Swift    | `swift xml_parser.swift -i input.xml -t tag -a key=value --json` |

If no input file is given, the program reads from stdin.  
Use `-h` or `--help` for usage details.

## 📊 Example
**Input XML:**
```xml
<library>
  <book id="1" lang="en">
    <title>1984</title>
    <author>George Orwell</author>
  </book>
  <book id="2" lang="fr">
    <title>Le Petit Prince</title>
    <author>Antoine de Saint-Exupéry</author>
  </book>
</library>
Search by tag:

text
$ xml_parser.py -i library.xml -t book
<book id="1" lang="en">
  <title>1984</title>
  <author>George Orwell</author>
</book>
<book id="2" lang="fr">
  <title>Le Petit Prince</title>
  <author>Antoine de Saint-Exupéry</author>
</book>
Search by attribute:

text
$ xml_parser.py -i library.xml -a lang=en
<book id="1" lang="en">
  <title>1984</title>
  <author>George Orwell</author>
</book>
Convert to JSON:

text
$ xml_parser.py -i library.xml --to-json
{"library": {"book": [{"_id": "1", "_lang": "en", "title": "1984", "author": "George Orwell"}, ...]}}
🔧 Command‑line Options (Common)
Option	Description
-i, --input	Input XML file (default: stdin)
-t, --tag	Search for elements with this tag name
-a, --attr	Search for elements with attribute key=value
--to-json	Output JSON instead of XML tree
-h, --help	Show help message
🤝 Contributing
Add support for XPath, namespace handling, or streaming parser – PRs welcome!

📜 License
MIT – use freely.
