# frozen_string_literal: true

require 'optparse'
require 'etc'

module Ls
  class Command
    attr_reader :options, :files

    def initialize
      @options = {}
      option = OptionParser.new
      option.on('-a', '--all') { |value| @options[:a] = value }
      option.on('-l', '--long') { |value| @options[:l] = value }
      option.on('-r', '--reverse') { |value| @options[:r] = value }
      option.parse(ARGV)
      @files = Dir.glob('*').sort
    end

    def all_files
      Dir.glob('.*').sort + @files
    end

    def reverse_files
      @files.reverse
    end

    def excute
      @files = all_files if options[:a]
      @files = reverse_files if options[:r]
      if options[:l]
        Ls::VerticalFormatter.output_single_column(@files)
      else
        Ls::HorizontalFormatter.output_multi_column(@files)
      end
    end
  end

  class HorizontalFormatter
    class << self
      def output_multi_column(files)
        results = files.map { |file| file.to_s.ljust(24, ' ') }
        file_names = results.each_slice(length(files)).to_a
        push_nil(file_names).transpose.each { |array| puts array.join('') }
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
  end

  class VerticalFormatter
    class << self
      def output_single_column(files)
        puts "total #{total(files)}"
        file_details(files).each { |array| puts array.each_slice(7).to_a.join(' ') }
      end

      private

      def total(files)
        files.sum do |file_name|
          file_stat = ::File::Stat.new(file_name)
          file_stat.blocks
        end
      end

      def file_details(files)
        files.map do |file_name|
          file_stat = ::File::Stat.new(file_name)
          [
            permission_convert(file_stat),
            file_stat.nlink.to_s.rjust(nlink_length(files)),
            Etc.getpwuid(file_stat.uid).name,
            Etc.getgrgid(file_stat.gid).name.rjust(6),
            file_stat.size.to_s.rjust(5),
            file_stat.mtime.strftime('%_m %e %H:%M'),
            file_name
          ]
        end
      end

      def nlink_length(files)
        max_length = files.map do |file_name|
          file_stat = ::File::Stat.new(file_name)
          file_stat.nlink
        end
        max_length.max_by { |number| number.to_s.length }.to_s.length
      end

      def permission_convert(file_stat)
        type = file_stat.ftype == 'file' ? '-' : file_stat.ftype[0]
        rwx = { '0' => '---', '1' => '--x', '2' => '-w-', '3' => '-wx',
                '4' => 'r--', '5' => 'r-x', '6' => 'rw-', '7' => 'rwx' }
        mode = file_stat.mode.to_s(8)[-3, 3].gsub(/\d/, rwx)
        "#{type}#{mode} "
      end
    end
  end
end

Ls::Command.new.excute
