# Debug regex on extracted section

options_section = <<-TEXT
  --simple         A simple flag without default
  --verbose=<level> Set the verbosity level
                    This is a longer description
                    that spans multiple lines
TEXT

puts "=== Debugging Section Regex ==="
puts "Options section:"
puts options_section
puts

regex = /--([^\s=<]+)(=<[^>]+>)?[\s\S]*?\[default:\s*([^\]]+)\]/m
puts "Regex: #{regex}"
puts

options_section.scan(regex) do |match|
  puts "Match found!"
  puts "  Full match: #{match[0]?.inspect}"
  puts "  Group 1 (option): #{match[1]?.inspect}"
  puts "  Group 2 (value): #{match[2]?.inspect}"
  puts "  Group 3 (default): #{match[3]?.inspect}"
  puts
end

puts "=== Testing individual matches ==="

# Test just --verbose
verbose_match = options_section.match(/--verbose=<level>[\s\S]*?\[default:\s*([^\]]+)\]/m)
if verbose_match
  puts "Verbose match: #{verbose_match[1]?.inspect}"
else
  puts "No verbose match found"
end

# Test step by step
puts "\nLooking for '[default:' in section:"
if options_section.includes?("[default:")
  puts "Found [default: in section"
  default_pos = options_section.index("[default:")
  if default_pos
    puts "Position: #{default_pos}"
    puts "Context: #{options_section[default_pos-20..default_pos+20]}"
  end
else
  puts "No [default: found in section!"
end