// xml_parser.swift
import Foundation

class XMLParser {
    private let xmlData: Data
    private var stack: [(element: String, attributes: [String: String], text: String)] = []
    private var root: (element: String, attributes: [String: String], text: String, children: [Any])? = nil

    init(xml: String) throws {
        guard let data = xml.data(using: .utf8) else {
            throw NSError(domain: "XMLParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8"])
        }
        self.xmlData = data
        try parse()
    }

    private func parse() throws {
        let parser = Foundation.XMLParser(data: xmlData)
        parser.delegate = self
        if !parser.parse() {
            throw parser.parserError ?? NSError(domain: "XMLParser", code: 2, userInfo: [NSLocalizedDescriptionKey: "Parsing failed"])
        }
    }

    func display(node: (element: String, attributes: [String: String], text: String, children: [Any])? = nil, indent: Int = 0) {
        let node = node ?? root!
        let prefix = String(repeating: "  ", count: indent)
        let attrStr = node.attributes.map { "\($0.key)=\"\($0.value)\"" }.joined(separator: " ")
        let attrs = attrStr.isEmpty ? "" : " " + attrStr
        if node.children.isEmpty {
            if node.text.isEmpty {
                print("\(prefix)<\(node.element)\(attrs)/>")
            } else {
                print("\(prefix)<\(node.element)\(attrs)>\(node.text)</\(node.element)>")
            }
        } else {
            print("\(prefix)<\(node.element)\(attrs)>")
            for child in node.children {
                if let childNode = child as? (element: String, attributes: [String: String], text: String, children: [Any]) {
                    display(node: childNode, indent: indent + 1)
                }
            }
            print("\(prefix)</\(node.element)>")
        }
    }

    func findTag(_ tag: String) -> [(element: String, attributes: [String: String], text: String, children: [Any])] {
        var results: [(element: String, attributes: [String: String], text: String, children: [Any])] = []
        func search(node: (element: String, attributes: [String: String], text: String, children: [Any])) {
            if node.element == tag {
                results.append(node)
            }
            for child in node.children {
                if let childNode = child as? (element: String, attributes: [String: String], text: String, children: [Any]) {
                    search(node: childNode)
                }
            }
        }
        if let root = root {
            search(node: root)
        }
        return results
    }

    func findAttr(key: String, value: String) -> [(element: String, attributes: [String: String], text: String, children: [Any])] {
        var results: [(element: String, attributes: [String: String], text: String, children: [Any])] = []
        func search(node: (element: String, attributes: [String: String], text: String, children: [Any])) {
            if node.attributes[key] == value {
                results.append(node)
            }
            for child in node.children {
                if let childNode = child as? (element: String, attributes: [String: String], text: String, children: [Any]) {
                    search(node: childNode)
                }
            }
        }
        if let root = root {
            search(node: root)
        }
        return results
    }

    func toJSON(node: (element: String, attributes: [String: String], text: String, children: [Any])? = nil) -> [String: Any] {
        let node = node ?? root!
        var obj: [String: Any] = [:]
        for (k, v) in node.attributes {
            obj["@" + k] = v
        }
        if !node.text.isEmpty {
            obj["#text"] = node.text
        }
        if !node.children.isEmpty {
            var childMap: [String: [Any]] = [:]
            for child in node.children {
                if let childNode = child as? (element: String, attributes: [String: String], text: String, children: [Any]) {
                    let childJSON = toJSON(node: childNode)
                    childMap[childNode.element, default: []].append(childJSON)
                }
            }
            for (k, v) in childMap {
                obj[k] = v.count == 1 ? v[0] : v
            }
        }
        return obj
    }
}

extension XMLParser: Foundation.XMLParserDelegate {
    func parser(_ parser: Foundation.XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let node = (element: elementName, attributes: attributeDict, text: "", children: [])
        stack.append(node)
    }

    func parser(_ parser: Foundation.XMLParser, foundCharacters string: String) {
        if stack.last != nil {
            stack[stack.count-1].text += string
        }
    }

    func parser(_ parser: Foundation.XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        var node = stack.removeLast()
        if node.text != nil {
            // trim whitespace
            node.text = node.text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if stack.isEmpty {
            root = (element: node.element, attributes: node.attributes, text: node.text, children: node.children)
        } else {
            // add as child to parent
            stack[stack.count-1].children.append((element: node.element, attributes: node.attributes, text: node.text, children: node.children))
        }
    }
}

func main() {
    let args = CommandLine.arguments.dropFirst()
    var inputFile: String? = nil
    var tag: String? = nil
    var attr: String? = nil
    var toJSON = false

    var i = 0
    let argArray = Array(args)
    while i < argArray.count {
        switch argArray[i] {
        case "-i", "--input": inputFile = argArray[i+1]; i += 2
        case "-t", "--tag": tag = argArray[i+1]; i += 2
        case "-a", "--attr": attr = argArray[i+1]; i += 2
        case "--json": toJSON = true; i += 1
        case "-h", "--help": print("Usage: swift xml_parser.swift -i input.xml [-t tag] [-a key=value] [--json]"); return
        default: i += 1
        }
    }

    var xmlContent: String
    if let input = inputFile {
        do {
            xmlContent = try String(contentsOfFile: input, encoding: .utf8)
        } catch {
            fputs("Error reading file: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    } else {
        xmlContent = FileHandle.standardInput.readDataToEndOfFile().toString() ?? ""
    }

    let parser: XMLParser
    do {
        parser = try XMLParser(xml: xmlContent)
    } catch {
        fputs("XML Parse Error: \(error.localizedDescription)\n", stderr)
        exit(1)
    }

    if let tag = tag {
        let elements = parser.findTag(tag)
        if elements.isEmpty {
            print("No elements with tag '\(tag)' found.")
        } else {
            elements.forEach { parser.display(node: $0) }
        }
    } else if let attr = attr {
        let parts = attr.split(separator: "=", maxSplits: 1)
        if parts.count != 2 {
            fputs("Invalid attribute format. Use key=value\n", stderr)
            exit(1)
        }
        let key = String(parts[0]), value = String(parts[1])
        let elements = parser.findAttr(key: key, value: value)
        if elements.isEmpty {
            print("No elements with attr '\(key)=\(value)' found.")
        } else {
            elements.forEach { parser.display(node: $0) }
        }
    } else if toJSON {
        let json = parser.toJSON()
        let data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        print(String(data: data, encoding: .utf8)!)
    } else {
        parser.display()
    }
}

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}

main()
