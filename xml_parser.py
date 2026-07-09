
---

# 💻 Code Implementations

## 1. Python (`xml_parser.py`)

```python
# xml_parser.py
import sys
import xml.etree.ElementTree as ET
import json
import argparse
from collections import defaultdict

class XMLParser:
    def __init__(self, xml_content):
        self.root = ET.fromstring(xml_content)

    def find_by_tag(self, tag):
        return self.root.findall(f'.//{tag}')

    def find_by_attr(self, key, value):
        return self.root.findall(f'.//*[@{{}}]'.format(key)) if key else []
        # Actually we need to filter manually because XPath with attributes in ET is limited
        result = []
        for elem in self.root.iter():
            if elem.attrib.get(key) == value:
                result.append(elem)
        return result

    def to_json(self, elem=None):
        if elem is None:
            elem = self.root
        node = {}
        if elem.attrib:
            node.update({f'@{k}': v for k, v in elem.attrib.items()})
        if elem.text and elem.text.strip():
            node['#text'] = elem.text.strip()
        children = list(elem)
        if children:
            child_dict = defaultdict(list)
            for child in children:
                child_dict[child.tag].append(self.to_json(child))
            for tag, values in child_dict.items():
                if len(values) == 1:
                    node[tag] = values[0]
                else:
                    node[tag] = values
        return node

    def display(self, elem=None, indent=0):
        if elem is None:
            elem = self.root
        prefix = '  ' * indent
        attrs = ' '.join(f'{k}="{v}"' for k, v in elem.attrib.items())
        tag_open = f'<{elem.tag}{" " + attrs if attrs else ""}>'
        if len(elem) == 0:
            text = elem.text.strip() if elem.text else ''
            print(f'{prefix}{tag_open}{text}</{elem.tag}>')
        else:
            print(f'{prefix}{tag_open}')
            for child in elem:
                self.display(child, indent + 1)
            print(f'{prefix}</{elem.tag}>')

def main():
    parser = argparse.ArgumentParser(description='Simple XML Parser')
    parser.add_argument('-i', '--input', help='Input XML file')
    parser.add_argument('-t', '--tag', help='Search for elements by tag name')
    parser.add_argument('-a', '--attr', help='Search by attribute (key=value)')
    parser.add_argument('--to-json', action='store_true', help='Output JSON')
    args = parser.parse_args()

    if args.input:
        with open(args.input, 'r', encoding='utf-8') as f:
            xml_content = f.read()
    else:
        xml_content = sys.stdin.read()

    try:
        xp = XMLParser(xml_content)
    except ET.ParseError as e:
        print(f'XML Parse Error: {e}', file=sys.stderr)
        sys.exit(1)

    if args.tag:
        elements = xp.find_by_tag(args.tag)
        if not elements:
            print(f'No elements with tag "{args.tag}" found.')
        else:
            for elem in elements:
                xp.display(elem)
    elif args.attr:
        if '=' not in args.attr:
            print('Invalid attribute format. Use key=value', file=sys.stderr)
            sys.exit(1)
        key, value = args.attr.split('=', 1)
        elements = xp.find_by_attr(key, value)
        if not elements:
            print(f'No elements with attr "{key}={value}" found.')
        else:
            for elem in elements:
                xp.display(elem)
    elif args.to_json:
        json_obj = xp.to_json()
        print(json.dumps(json_obj, indent=2, ensure_ascii=False))
    else:
        xp.display()

if __name__ == '__main__':
    main()
