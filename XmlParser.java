// XmlParser.java
import java.io.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;
import org.json.*;

public class XmlParser {
    public static void main(String[] args) throws Exception {
        String inputFile = null;
        String tag = null;
        String attr = null;
        boolean toJson = false;

        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "-i": case "--input": inputFile = args[++i]; break;
                case "-t": case "--tag": tag = args[++i]; break;
                case "-a": case "--attr": attr = args[++i]; break;
                case "--json": toJson = true; break;
                case "-h": case "--help": showHelp(); return;
            }
        }

        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setIgnoringComments(true);
        factory.setIgnoringElementContentWhitespace(true);
        DocumentBuilder builder = factory.newDocumentBuilder();
        Document doc;
        if (inputFile != null) {
            doc = builder.parse(new File(inputFile));
        } else {
            doc = builder.parse(System.in);
        }
        doc.getDocumentElement().normalize();

        if (tag != null) {
            NodeList elements = doc.getElementsByTagName(tag);
            if (elements.getLength() == 0) {
                System.out.println("No elements with tag '" + tag + "' found.");
            } else {
                for (int i = 0; i < elements.getLength(); i++) {
                    displayNode(elements.item(i), 0);
                }
            }
        } else if (attr != null) {
            String[] parts = attr.split("=");
            if (parts.length != 2) {
                System.err.println("Invalid attribute format. Use key=value");
                return;
            }
            String key = parts[0];
            String value = parts[1];
            NodeList all = doc.getElementsByTagName("*");
            boolean found = false;
            for (int i = 0; i < all.getLength(); i++) {
                Element el = (Element) all.item(i);
                if (el.hasAttribute(key) && el.getAttribute(key).equals(value)) {
                    displayNode(el, 0);
                    found = true;
                }
            }
            if (!found) {
                System.out.println("No elements with attr '" + key + "=" + value + "' found.");
            }
        } else if (toJson) {
            JSONObject json = nodeToJson(doc.getDocumentElement());
            System.out.println(json.toString(2));
        } else {
            displayNode(doc.getDocumentElement(), 0);
        }
    }

    static void displayNode(Node node, int indent) {
        if (node.getNodeType() == Node.ELEMENT_NODE) {
            Element el = (Element) node;
            String prefix = "  ".repeat(indent);
            String attrs = "";
            NamedNodeMap attrMap = el.getAttributes();
            if (attrMap.getLength() > 0) {
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < attrMap.getLength(); i++) {
                    Attr a = (Attr) attrMap.item(i);
                    sb.append(" ").append(a.getName()).append("=\"").append(a.getValue()).append("\"");
                }
                attrs = sb.toString();
            }
            if (el.getChildNodes().getLength() == 1 && el.getFirstChild().getNodeType() == Node.TEXT_NODE) {
                String text = el.getTextContent().trim();
                if (text.isEmpty()) {
                    System.out.println(prefix + "<" + el.getTagName() + attrs + "/>");
                } else {
                    System.out.println(prefix + "<" + el.getTagName() + attrs + ">" + text + "</" + el.getTagName() + ">");
                }
            } else {
                System.out.println(prefix + "<" + el.getTagName() + attrs + ">");
                NodeList children = el.getChildNodes();
                for (int i = 0; i < children.getLength(); i++) {
                    Node child = children.item(i);
                    if (child.getNodeType() == Node.ELEMENT_NODE) {
                        displayNode(child, indent + 1);
                    }
                }
                System.out.println(prefix + "</" + el.getTagName() + ">");
            }
        }
    }

    static JSONObject nodeToJson(Element el) {
        JSONObject obj = new JSONObject();
        NamedNodeMap attrs = el.getAttributes();
        for (int i = 0; i < attrs.getLength(); i++) {
            Attr a = (Attr) attrs.item(i);
            obj.put("@" + a.getName(), a.getValue());
        }
        String text = el.getTextContent().trim();
        if (!text.isEmpty() && el.getChildNodes().getLength() == 1) {
            obj.put("#text", text);
        }
        Map<String, List<JSONObject>> childMap = new HashMap<>();
        NodeList children = el.getChildNodes();
        for (int i = 0; i < children.getLength(); i++) {
            Node child = children.item(i);
            if (child.getNodeType() == Node.ELEMENT_NODE) {
                Element childEl = (Element) child;
                String tag = childEl.getTagName();
                JSONObject childObj = nodeToJson(childEl);
                childMap.computeIfAbsent(tag, k -> new ArrayList<>()).add(childObj);
            }
        }
        for (Map.Entry<String, List<JSONObject>> entry : childMap.entrySet()) {
            List<JSONObject> list = entry.getValue();
            if (list.size() == 1) {
                obj.put(entry.getKey(), list.get(0));
            } else {
                obj.put(entry.getKey(), list);
            }
        }
        return obj;
    }

    static void showHelp() {
        System.out.println("Usage: java XmlParser -i input.xml [-t tag] [-a key=value] [--json]");
    }
}
