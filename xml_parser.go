// xml_parser.go
package main

import (
	"encoding/json"
	"encoding/xml"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

type Node struct {
	XMLName  xml.Name
	Attrs    map[string]string `xml:"-"`
	Children []Node            `xml:"-"`
	Text     string            `xml:",chardata"`
}

func (n *Node) UnmarshalXML(d *xml.Decoder, start xml.StartElement) error {
	n.XMLName = start.Name
	n.Attrs = make(map[string]string)
	for _, attr := range start.Attr {
		n.Attrs[attr.Name.Local] = attr.Value
	}
	for {
		token, err := d.Token()
		if err != nil {
			return err
		}
		switch t := token.(type) {
		case xml.StartElement:
			child := Node{}
			if err := child.UnmarshalXML(d, t); err != nil {
				return err
			}
			n.Children = append(n.Children, child)
		case xml.CharData:
			text := strings.TrimSpace(string(t))
			if text != "" {
				n.Text += text
			}
		case xml.EndElement:
			return nil
		}
	}
}

func (n Node) display(indent int) {
	prefix := strings.Repeat("  ", indent)
	attrStr := ""
	if len(n.Attrs) > 0 {
		var parts []string
		for k, v := range n.Attrs {
			parts = append(parts, fmt.Sprintf(`%s="%s"`, k, v))
		}
		attrStr = " " + strings.Join(parts, " ")
	}
	if len(n.Children) == 0 && n.Text == "" {
		fmt.Printf("%s<%s%s/>\n", prefix, n.XMLName.Local, attrStr)
		return
	}
	if len(n.Children) == 0 && n.Text != "" {
		fmt.Printf("%s<%s%s>%s</%s>\n", prefix, n.XMLName.Local, attrStr, n.Text, n.XMLName.Local)
		return
	}
	fmt.Printf("%s<%s%s>\n", prefix, n.XMLName.Local, attrStr)
	for _, child := range n.Children {
		child.display(indent + 1)
	}
	fmt.Printf("%s</%s>\n", prefix, n.XMLName.Local)
}

func (n Node) toJSON() interface{} {
	if len(n.Children) == 0 {
		if n.Text != "" {
			return n.Text
		}
		return nil
	}
	obj := make(map[string]interface{})
	if n.Text != "" {
		obj["#text"] = n.Text
	}
	for k, v := range n.Attrs {
		obj["@"+k] = v
	}
	childMap := make(map[string][]interface{})
	for _, child := range n.Children {
		childMap[child.XMLName.Local] = append(childMap[child.XMLName.Local], child.toJSON())
	}
	for tag, list := range childMap {
		if len(list) == 1 {
			obj[tag] = list[0]
		} else {
			obj[tag] = list
		}
	}
	return obj
}

func main() {
	inputFile := flag.String("i", "", "Input XML file")
	tag := flag.String("t", "", "Search by tag name")
	attr := flag.String("a", "", "Search by attribute (key=value)")
	toJSON := flag.Bool("json", false, "Output JSON")
	flag.Parse()

	var data []byte
	var err error
	if *inputFile != "" {
		data, err = ioutil.ReadFile(*inputFile)
	} else {
		data, err = ioutil.ReadAll(os.Stdin)
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading input: %v\n", err)
		os.Exit(1)
	}

	var root Node
	decoder := xml.NewDecoder(strings.NewReader(string(data)))
	if err := decoder.Decode(&root); err != nil {
		fmt.Fprintf(os.Stderr, "XML Parse Error: %v\n", err)
		os.Exit(1)
	}

	if *tag != "" {
		findByTag(&root, *tag)
		return
	}
	if *attr != "" {
		parts := strings.SplitN(*attr, "=", 2)
		if len(parts) != 2 {
			fmt.Fprintln(os.Stderr, "Invalid attribute format. Use key=value")
			os.Exit(1)
		}
		findByAttr(&root, parts[0], parts[1])
		return
	}
	if *toJSON {
		jsonData := root.toJSON()
		out, _ := json.MarshalIndent(jsonData, "", "  ")
		fmt.Println(string(out))
	} else {
		root.display(0)
	}
}

func findByTag(node *Node, tag string) {
	var found bool
	var search func(n Node)
	search = func(n Node) {
		if n.XMLName.Local == tag {
			n.display(0)
			found = true
		}
		for _, child := range n.Children {
			search(child)
		}
	}
	search(*node)
	if !found {
		fmt.Printf("No elements with tag '%s' found.\n", tag)
	}
}

func findByAttr(node *Node, key, value string) {
	var found bool
	var search func(n Node)
	search = func(n Node) {
		if n.Attrs[key] == value {
			n.display(0)
			found = true
		}
		for _, child := range n.Children {
			search(child)
		}
	}
	search(*node)
	if !found {
		fmt.Printf("No elements with attr '%s=%s' found.\n", key, value)
	}
}
