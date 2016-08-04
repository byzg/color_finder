class ColorFinder
  HEX_COLOR = /#[0-9ABCDEFfabcdef]{6}/
  RGBA_COLOR = /rgba\([0-9\.\s\,]+\)/
  EXCEPT = /#(ffffff|FFFFFF|000000)/
  CONST = /\$[a-z\-]+(?=\:)/

  def initialize(root, vars_file)
    @root = root
    @vars_file = vars_file
    @vars = File.foreach(@vars_file).grep(HEX_COLOR).map { |line| [line[HEX_COLOR], line[CONST]] }.to_h
  end
  
  def find_and_replace
    @without_names = []
    Dir["#{@root}/**/*"].each do |filename|
      next if filename == @vars_file || !filename.match(/\.sass$/)
      text = File.read(filename)
      content = []
      text.split(/\n/).each_with_index do |line, index|
        _line = replace_hex(filename, line, index)
        _line = replace_rgba(filename, _line, index)
        content << _line
      end
      content = content.join("\n")
      content << "\n" if text.end_with?("\n")
      File.open(filename, 'w') { |file| file << content } unless text == content
    end
  end
  
  def report
    @without_names.each do |colorinfo|
      count = @without_names.count {|ci| ci[:color] == colorinfo[:color]}
      puts "color #{colorinfo[:color]} (#{count}) is not replaced in #{relpath(colorinfo[:path], colorinfo[:index])}"
    end
    puts 'Done'
  end
  
  private
  def replace_hex(filename, line, index)
    line.gsub(HEX_COLOR) do |color|
      if !color.match(EXCEPT) && @vars[color]
        puts_replacement(color, @vars[color], filename, index)
        @vars[color]
      else
        @without_names << {color: color, path: filename, index: index} unless color.match(EXCEPT)
        color
      end
    end
  end

  def replace_rgba(filename, line, index)
    line.gsub(RGBA_COLOR) do |rgba_color|
      color = "#%02X%02X%02X" % rgba_color.scan(/\d+/)[0..2].to_a.map(&:to_i)
      opacity = rgba_color[(/\d?(\.)?\d*(?=\))/)]
      if !color.match(EXCEPT) && @vars[color]
        to = "rgba(#{@vars[color]}, #{opacity})"
        to = @vars[color] if opacity.to_i == 1
        puts_replacement(rgba_color, to, filename, index)
        to
      else
        @without_names << {color: rgba_color, path: filename, index: index} unless color.match(EXCEPT)
        rgba_color
      end
    end
  end

  def puts_replacement(from, to, filename, index)
    puts "replacement #{from} -> #{to} in #{relpath(filename, index)}"
  end

  def relpath(path, index)
    "#{path.sub(@root, '..')}:#{index + 1}"
  end
end

# Rails.root.join('app', 'assets', 'stylesheets').to_s
# Rails.root.join('app', 'assets', 'stylesheets', '_vars.sass').to_s
color_finder = ColorFinder.new(*ARGV)
color_finder.find_and_replace
color_finder.report
