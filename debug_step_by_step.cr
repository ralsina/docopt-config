# Debug step by step what the regex is matching

doc_edge_case = <<-DOC
Usage: test [--simple] [--verbose=<level>]

Options:
  --simple         A simple flag without default
  --verbose=<level> Set the verbosity level
                    This is a longer description
                    that spans multiple lines
                    [default: 42]
DOC

puts "=== Step by Step Debug ==="
puts "Original docopt:"
puts doc_edge_case
puts

# Current problematic regex
regex = /--([^\s=<]+)(=<[^>]+>)?[\s\S]*?\[default:\s*([^\]]+)\]/m

puts "Testing current regex: #{regex}"
puts

# Find all matches with details
doc_edge_case.scan(regex) do |match|
  puts "Match found!"
  puts "  Full match: #{match[0]?.inspect}"
  puts "  Group 1 (option): #{match[1]?.inspect}"
  puts "  Group 2 (value): #{match[2]?.inspect}"
  puts "  Group 3 (default): #{match[3]?.inspect}"
  puts
end

puts "=== Testing simpler case first ==="
simple_doc = <<-DOC
Options:
  --verbose=<level> Set verbosity [default: 5]
DOC

puts "Simple doc:"
puts simple_doc
puts

simple_doc.scan(regex) do |match|
  puts "Simple match found!"
  puts "  Full match: #{match[0]?.inspect}"
  puts "  Group 1 (option): #{match[1]?.inspect}"
  puts "  Group 2 (value): #{match[2]?.inspect}"
  puts "  Group 3 (default): #{match[3]?.inspect}"
  puts
end