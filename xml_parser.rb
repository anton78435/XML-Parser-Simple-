# xml_parser.rb
require 'rexml/document'
require 'json'
require 'optparse'

class XmlParser
  def initialize(xml_content)
    @doc = REXML::Document.new(xml_content)
  end

  def display(node = @doc.root, indent = 0)
    prefix = '  ' * indent
    attrs = node.attributes.map { |k,v| "#{k}=\"#{v}\"" }.join(' ')
    attrs = ' ' + attrs if !attrs.empty?
    if node.has_elements?
      puts "#{prefix}<#{node.name}#{attrs}>"
      node.each_element { |child| display(child, indent + 1) }
      puts "#{prefix}</#{node.name}>"
    else
      text = node.texts.join.strip
      if text.empty?
        puts "#{prefix}<#{node.name}#{attrs}/>"
      else
        puts "#{prefix}<#{node.name}#{attrs}>#{text}</#{node.name}>"
      end
    end
  end

  def find_by_tag(tag)
    @doc.root.elements.to_a("//#{tag}")
  end

  def find_by_attr(key, value)
    result = []
    @doc.root.each_recursive do |elem|
      result << elem if elem.attributes[key] == value
    end
    result
  end

  def to_json(node = @doc.root)
    obj = {}
    node.attributes.each { |k,v| obj["@#{k}"] = v }
    text = node.texts.join.strip
    if node.has_elements?
      child_map = {}
      node.each_element do |child|
        child_json = to_json(child)
        child_map[child.name] ||= []
        child_map[child.name] << child_json
      end
      child_map.each do |k, v|
        obj[k] = v.size == 1 ? v[0] : v
      end
      obj['#text'] = text if !text.empty?
    else
      obj['#text'] = text if !text.empty?
    end
    obj
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby xml_parser.rb [options]"
  opts.on("-iFILE", "--input=FILE", "Input XML file") { |f| options[:input] = f }
  opts.on("-tTAG", "--tag=TAG", "Search by tag") { |t| options[:tag] = t }
  opts.on("-aATTR", "--attr=ATTR", "Search by attribute (key=value)") { |a| options[:attr] = a }
  opts.on("--json", "Output JSON") { options[:json] = true }
  opts.on("-h", "--help", "Show help") { puts opts; exit }
end.parse!

xml_content = if options[:input]
                File.read(options[:input], encoding: 'utf-8')
              else
                STDIN.read
              end

begin
  parser = XmlParser.new(xml_content)
rescue REXML::ParseException => e
  STDERR.puts "XML Parse Error: #{e.message}"
  exit 1
end

if options[:tag]
  elements = parser.find_by_tag(options[:tag])
  if elements.empty?
    puts "No elements with tag '#{options[:tag]}' found."
  else
    elements.each { |el| parser.display(el) }
  end
elsif options[:attr]
  key, value = options[:attr].split('=', 2)
  if key.nil? || value.nil?
    STDERR.puts "Invalid attribute format. Use key=value"
    exit 1
  end
  elements = parser.find_by_attr(key, value)
  if elements.empty?
    puts "No elements with attr '#{key}=#{value}' found."
  else
    elements.each { |el| parser.display(el) }
  end
elsif options[:json]
  puts JSON.pretty_generate(parser.to_json)
else
  parser.display
end
