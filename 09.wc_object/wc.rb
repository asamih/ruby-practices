# frozen_string_literal: true

require 'optparse'

module Wc
  class Command
    attr_reader :options, :files

    def initialize
      @options = {}
      option = OptionParser.new
      option.on('-l', '--lines') { |value| @options[:l] = value }
      option.parse!(ARGV)
      @files = ARGV
    end

    def excute
      if options[:l]
        Wc::Formatter.new.line(Wc::File.new.data.flatten!)
      else
        Wc::Formatter.new.output_normal(Wc::File.new.data.flatten!)
      end
    end
  end

  class File < Command
    def data
      file_data = []
      if files.empty?
        file_unit = $stdin.read
        file_data.push count(file_unit)
      else
        files.each do |file_name|
          ::File.open(file_name, 'r') { |file| file_unit = file.read }
          file_data.push(count(file_unit) << file_name)
        end
      end
      file_data
    end

    private

    def count(file_unit)
      @line = file_unit.lines.count,
              @word = file_unit.chomp.split.count,
              @byte = file_unit.bytesize
    end
  end

  class Formatter
    attr_reader :file

    def initialize
      @file = Wc::File.new
    end

    def output_normal(files)
      results = []
      if files.length >= 4
        number = 0
        files.each do |file_name|
          number += 1
          results << (number % 4 != 0 ? rayout(file_name) : " #{file_name}\n")
        end
      else
        files.map { |file_name| results << rayout(file_name) }
      end
      puts results.join('')
      puts "#{total(file.data)} total" if files.length > 4
    end

    def line(files)
      results = []
      if files.length >= 4
        number = 0
        files.each do |file_name|
          number += 1
          results << rayout(file_name) if number == 1 || ((number - 1) % 4).zero?
          results << " #{file_name}\n" if (number % 4).zero?
        end
      else
        results << rayout(files.first)
      end
      puts results.join('')
      puts "#{total_line(file.data)} total" if files.length > 4
    end

    private

    def rayout(file_name)
      file_name.to_s.rjust(8, ' ')
    end

    def total(files)
      total = files.map { |array| array[0..2] }.transpose.map { |file_data| file_data.inject(:+) }
      total.map { |file_total| rayout(file_total) }.join('')
    end

    def total_line(files)
      rayout(files.map { |file_data| file_data[0] }.sum)
    end
  end
end

Wc::Command.new.excute
