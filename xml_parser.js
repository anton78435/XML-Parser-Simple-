// xml_parser.js
const fs = require('fs');
const util = require('util');

// Simple XML parser using regex (for demo) — in a real app, use a library like xml2js.
// But we'll implement a minimal parser to avoid dependencies.
function parseXML(xml) {
    // Remove comments and processing instructions
    xml = xml.replace(/<!--[\s\S]*?-->/g, '');
    xml = xml.replace(/<\?[\s\S]*?\?>/g, '');
    // Use a simple stack-based parser (not fully robust, but works for basic cases)
    let i = 0;
    let root = null;
    let stack = [];
    let current = null;
    while (i < xml.length) {
        if (xml[i] === '<') {
            if (xml[i+1] === '/') {
                // closing tag
                let closeIndex = xml.indexOf('>', i);
                let tagName = xml.substring(i+2, closeIndex).trim();
                if (stack.length > 0) {
                    let parent = stack.pop();
                    // If text accumulated in current, assign it before closing
                    if (current && current !== parent && current.text !== undefined) {
                        // assign text to current
                    }
                    current = parent;
                }
                i = closeIndex + 1;
            } else if (xml[i+1] === '!') {
                // CDATA or comment (already removed)
                let closeIndex = xml.indexOf('>', i);
                i = closeIndex + 1;
            } else {
                // opening tag
                let closeIndex = xml.indexOf('>', i);
                let tagContent = xml.substring(i+1, closeIndex);
                let tagMatch = tagContent.match(/^(\w+)(?:\s+(.*))?/);
                if (tagMatch) {
                    let tagName = tagMatch[1];
                    let attrStr = tagMatch[2] || '';
                    let attrs = {};
                    // parse attributes (simple regex)
                    let attrRegex = /(\w+)\s*=\s*"([^"]*)"/g;
                    let match;
                    while ((match = attrRegex.exec(attrStr)) !== null) {
                        attrs[match[1]] = match[2];
                    }
                    let node = { tag: tagName, attrs, children: [], text: '' };
                    if (tagContent.endsWith('/')) {
                        // self-closing
                        // add to parent
                        if (stack.length > 0) {
                            stack[stack.length-1].children.push(node);
                        } else {
                            root = node;
                        }
                    } else {
                        if (stack.length > 0) {
                            stack[stack.length-1].children.push(node);
                        } else {
                            root = node;
                        }
                        stack.push(node);
                        current = node;
                    }
                }
                i = closeIndex + 1;
            }
        } else {
            // text node
            let nextOpen = xml.indexOf('<', i);
            let text = xml.substring(i, nextOpen).trim();
            if (text && current) {
                // If current has no children and no text yet, assign
                if (current.children.length === 0 && current.text === '') {
                    current.text = text;
                } else {
                    // If there are children, text might be whitespace; we ignore or add as text node?
                    // For simplicity, if children exist, we ignore whitespace text.
                }
            }
            i = nextOpen === -1 ? xml.length : nextOpen;
        }
    }
    return root;
}

function displayNode(node, indent = 0) {
    const prefix = '  '.repeat(indent);
    let attrStr = Object.entries(node.attrs).map(([k,v]) => `${k}="${v}"`).join(' ');
    attrStr = attrStr ? ' ' + attrStr : '';
    if (node.children.length === 0) {
        if (node.text) {
            console.log(`${prefix}<${node.tag}${attrStr}>${node.text}</${node.tag}>`);
        } else {
            console.log(`${prefix}<${node.tag}${attrStr}/>`);
        }
    } else {
        console.log(`${prefix}<${node.tag}${attrStr}>`);
        node.children.forEach(child => displayNode(child, indent+1));
        console.log(`${prefix}</${node.tag}>`);
    }
}

function toJSON(node) {
    let obj = {};
    if (node.text) obj['#text'] = node.text;
    Object.keys(node.attrs).forEach(k => obj['@'+k] = node.attrs[k]);
    if (node.children.length > 0) {
        let childMap = {};
        node.children.forEach(child => {
            let tag = child.tag;
            let childObj = toJSON(child);
            if (childMap[tag]) {
                if (!Array.isArray(childMap[tag])) {
                    childMap[tag] = [childMap[tag]];
                }
                childMap[tag].push(childObj);
            } else {
                childMap[tag] = childObj;
            }
        });
        Object.keys(childMap).forEach(tag => {
            obj[tag] = childMap[tag];
        });
    }
    return obj;
}

function main() {
    const args = process.argv.slice(2);
    let inputFile = null;
    let tag = null;
    let attr = null;
    let toJSONFlag = false;

    for (let i = 0; i < args.length; i++) {
        if (args[i] === '-i' || args[i] === '--input') {
            inputFile = args[++i];
        } else if (args[i] === '-t' || args[i] === '--tag') {
            tag = args[++i];
        } else if (args[i] === '-a' || args[i] === '--attr') {
            attr = args[++i];
        } else if (args[i] === '--json') {
            toJSONFlag = true;
        } else if (args[i] === '-h' || args[i] === '--help') {
            console.log('Usage: node xml_parser.js [-i input.xml] [-t tag] [-a key=value] [--json]');
            process.exit(0);
        }
    }

    let xmlContent;
    if (inputFile) {
        try {
            xmlContent = fs.readFileSync(inputFile, 'utf8');
        } catch (e) {
            console.error('Error reading file:', e.message);
            process.exit(1);
        }
    } else {
        xmlContent = fs.readFileSync(0, 'utf8');
    }

    let root;
    try {
        root = parseXML(xmlContent);
        if (!root) throw new Error('Parsing failed');
    } catch (e) {
        console.error('XML Parse Error:', e.message);
        process.exit(1);
    }

    if (tag) {
        let found = false;
        const searchTag = (node) => {
            if (node.tag === tag) {
                displayNode(node);
                found = true;
            }
            node.children.forEach(searchTag);
        };
        searchTag(root);
        if (!found) console.log(`No elements with tag '${tag}' found.`);
    } else if (attr) {
        const [key, value] = attr.split('=');
        if (!key || !value) {
            console.error('Invalid attribute format. Use key=value');
            process.exit(1);
        }
        let found = false;
        const searchAttr = (node) => {
            if (node.attrs[key] === value) {
                displayNode(node);
                found = true;
            }
            node.children.forEach(searchAttr);
        };
        searchAttr(root);
        if (!found) console.log(`No elements with attr '${key}=${value}' found.`);
    } else if (toJSONFlag) {
        console.log(JSON.stringify(toJSON(root), null, 2));
    } else {
        displayNode(root);
    }
}

main();
