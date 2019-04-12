
task :build do
  puts 'Running...'.bold
  sh "ruby connect.rb"
end

# Extend string to allow for formatting
class String
  def bold
    "\033[1m#{self}\033[0m"
  end

  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def green
    colorize(32)
  end
end