ROOT = ARGV[0] # || Rails.root.join('app', 'assets', 'stylesheets').to_s
VARS_FILE = ARGV[1] # || Rails.root.join('app', 'assets', 'stylesheets', '_vars.sass').to_s

COLOR = /#[0-9ABCDEfabcdef]{6}/
EXCEPT = /#(ffffff|000000)/
CONST = /\$[a-z\-]+(?=\:)/

vars = {}
File.foreach(VARS_FILE).grep(COLOR).each do |line|
  name, val = line[CONST], line[COLOR]
  vars[val] = name
end

without_names = []
Dir["#{ROOT}/**/*"].each do |filename|
  next if filename == VARS_FILE || !filename.match(/\.sass$/)
  text = File.read(filename)
  content = text.gsub(COLOR) do |color|
    if !color.match(EXCEPT) && vars[color]
      vars[color]
    else
      without_names << {color: color, path: filename} unless color.match(EXCEPT)
      color
    end
  end
  unless text == content
    puts "replacement in #{filename}"
    File.open(filename, 'w') { |file| file << content }
  end
end

without_names.each do |colorinfo|
  count = without_names.count {|ci| ci[:color] == colorinfo[:color]}
  puts "color #{colorinfo[:color]} (#{count}) is not replaced in #{colorinfo[:path]}"
end
puts 'Done'
