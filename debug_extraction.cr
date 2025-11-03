# Debug the section extraction

doc_edge_case = <<-DOC
Usage: test [--simple] [--verbose=<level>]

Options:
  --simple         A simple flag without default
  --verbose=<level> Set the verbosity level
                    This is a longer description
                    that spans multiple lines
                    [default: 42]
DOC

puts "=== Debugging Section Extraction ==="
puts "Original docopt:"
puts doc_edge_case
puts

puts "=== Current regex ==="
current_regex = /^Options:\s*\n((?:\s*.*\n)*)/m
puts "Regex: #{current_regex}"

if match = doc_edge_case.match(current_regex)
  puts "Match found!"
  puts "Group 1: #{match[1]?.inspect}"
  if group1 = match[1]?
    puts "Group 1 length: #{group1.size}"
    puts "Group 1 lines: #{group1.split('\n').size}"
  end
else
  puts "No match found!"
end

puts
puts "=== Better regex ==="
# Match until we find a line that doesn't start with whitespace or is empty
better_regex = /^Options:\s*\n((?:\s+.*\n*)*)/m
puts "Regex: #{better_regex}"

if match = doc_edge_case.match(better_regex)
  puts "Match found!"
  puts "Group 1: #{match[1]?.inspect}"
  if group1 = match[1]?
    puts "Group 1 length: #{group1.size}"
    puts "Group 1 lines: #{group1.split('\n').size}"
  end

  if options_section = match[1]?
    puts "Full section:"
    puts options_section
  end
else
  puts "No match found!"
end

puts
puts "=== Even better regex - capture until non-indented line ==="
# Match indented lines until we hit a non-indented line or end
best_regex = /^Options:\s*\n((?:\s+[^\n]*\n*)*)/m
puts "Regex: #{best_regex}"

if match = doc_edge_case.match(best_regex)
  puts "Match found!"
  puts "Group 1: #{match[1]?.inspect}"

  if options_section = match[1]?
    puts "Full section:"
    puts options_section
    puts "Contains [default:]: #{options_section.includes?("[default:")}"
  end
else
  puts "No match found!"
end