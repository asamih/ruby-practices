# frozen_string_literal: true

require 'optparse'
require 'etc'

module LS
  class File
    attr_reader :files

    def initialize
      @files = Dir.glob('*').sort
    end

    def all(files)
      Dir.glob('.*').sort + files
    end

    def reverse(files)
      files.reverse
    end

    def data(files)
      file_data = []
      files.each do |file_name|
        file_stat = ::File::Stat.new(file_name)
        file_data.push [
          permission_convert(file_stat),
          file_stat.nlink.to_s.rjust(nlink_length(files)),
          Etc.getpwuid(file_stat.uid).name,
          Etc.getgrgid(file_stat.gid).name.rjust(6),
          file_stat.size.to_s.rjust(5),
          file_stat.mtime.strftime('%_m %e %H:%M'),
          file_name
        ]
      end
      file_data
    end

    private

    def nlink_length(files)
      max_length = []
      files.each do |file_name|
        file_stat = ::File::Stat.new(file_name)
        max_length << file_stat.nlink
      end
      max_length.max_by { |num| num.to_s.length }.to_s.length
    end

    def permission_convert(file_stat)
      type = file_stat.ftype == 'file' ? '-' : file_stat.ftype[0]
      rwx = { '0' => '---', '1' => '--x', '2' => '-w-', '3' => '-wx',
              '4' => 'r--', '5' => 'r-x', '6' => 'rw-', '7' => 'rwx' }
      mode = file_stat.mode.to_s(8)[-3, 3].gsub(/\d/, rwx)
      "#{type}#{mode} "
    end
  end

  class Command < File
    attr_reader :options, :files

    def initialize
      super
      @options = {}
      opt = OptionParser.new
      opt.on('-a', '--all') { |v| @options[:a] = v }
      opt.on('-l', '--long') { |v| @options[:l] = v }
      opt.on('-r', '--reverse') { |v| @options[:r] = v }
      opt.parse(ARGV)
    end

    def select_option
      if options[:a] == true
        @files = all(files)
      else
        @files
      end

      @files = reverse(files) if options[:r] == true

      if options[:l] == true
        LS::VerticalFormatter.new.single_column(@files)
      else
        LS::HorizontalFormatter.new.multi_column(@files)
      end
    end
  end

  class HorizontalFormatter
    def multi_column(files)
      result = []
      files.map { |file_name| result << file_name.to_s.ljust(24, ' ') }
      format = result.each_slice(length(files)).to_a
      push_nil(format).transpose.each { |array| puts array.join('') }
    end

    private

    def length(files)
      (files.length % 4).zero? ? files.length / 4 : files.length / 4 + 1
    end

    def push_nil(format)
      max = format.max_by(&:length).length
      format.each { |array| array[max - 1] = nil if array.length < max }
    end
  end

  class VerticalFormatter
    def total(files)
      total = 0
      files.each do |file_name|
        file_stat = ::File::Stat.new(file_name)
        total += file_stat.blocks
      end
      puts "total #{total}"
    end

    def single_column(files)
      total(files)
      file_data = LS::Command.new.data(files)
      file_data.map { |array| puts array.each_slice(7).to_a.join(' ') }
    end
  end
end

LS::Command.new.select_option
