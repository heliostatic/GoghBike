#!/usr/bin/env ruby -wKU

# if ARGV.length == 0
#     puts "You must specify a file to remove duplicate lines."
#     exit
# end
# filepath = File.expand_path(ARGV[0])
d = 'recordings'
files = Dir.entries(d)
puts files

files.each do |filepath|
    filepath = File.expand_path(d + '/' + filepath)
    puts "Trying to open #{filepath}"
    if File.exists?(filepath) && !File.directory?(filepath)
        infile = File.open(filepath)
        outfilepath = File.dirname(filepath) + '/' + filepath.split('/').last.sub(/\.([a-z]{1,4})/, '-nodupe\0')
        outfilepath += 'nodupe' if outfilepath == filepath
        outfile = File.new(outfilepath, 'w')

        puts "Outputting file to #{outfilepath}"

        lines, dupes = 0, 0
        lastline = nil
        infile.readlines.each do |line|
            lines += 1
            dupes += 1 if line == lastline
            outfile.write(line) if line != lastline
            lastline = line
        end
    end
end

puts "\n\nFile: #{filepath}\nLines: #{lines}\nDuplicate lines: #{dupes}"