# frozen_string_literal: true

require 'optparse'

module Wc
  class Command
    attr_reader :options

    def initialize
      @options = {}
      option = OptionParser.new
      option.on('-l', '--lines') { |value| @options[:l] = value }
      option.parse!(ARGV)
      @file_details = Wc::FileCollector.new.file_details
      @file_elements = @file_details.flatten
    end

    def excute
      if options[:l]
        Wc::LineFormatter.output_line(@file_details, @file_elements)
      else
        Wc::StandardFormatter.output_all(@file_details, @file_elements)
      end
    end
  end

  class StandardFormatter
    class << self
      def output_all(file_details, file_elements)
        results = []
        if file_elements.length >= 4
          number = 0
          results = file_elements.map do |file_data|
            number += 1
            number % 4 != 0 ? layout(file_data) : " #{file_data}\n"
          end
        else
          results = file_elements.map { |file_data| layout(file_data) }
        end
        puts results.join('')
        puts "#{total(file_details)} total" if file_elements.length > 4
      end

      private

      def layout(file_data)
        file_data.to_s.rjust(8, ' ')
      end

      def total(file_details)
        total = file_details.map { |array| array[0..2] }.transpose.map { |file_subtotal| file_subtotal.inject(:+) }
        total.map { |file_total| layout(file_total) }.join('')
      end
    end
  end

  class LineFormatter
    class << self
      def output_line(file_details, file_elements)
        results = []
        if file_elements.length >= 4
          number = 0
          file_elements.each do |file_data|
            number += 1
            results << layout(file_data) if number == 1 || ((number - 1) % 4).zero?
            results << " #{file_data}\n" if (number % 4).zero?
          end
        else
          results << layout(file_elements.first)
        end
        puts results.join('')
        puts "#{total_line(file_details)} total" if file_elements.length > 4
      end

      private

      def layout(file_data)
        file_data.to_s.rjust(8, ' ')
      end

      def total_line(file_details)
        layout(file_details.map { |file_subtotal| file_subtotal[0] }.sum)
      end
    end
  end

  class FileCollector
    def initialize
      @files = ARGV
    end

    def file_details
      file_details = []
      if @files.empty?
        file_unit = $stdin.read
        file_details.push count(file_unit)
      else
        @files.each do |file_name|
          ::File.open(file_name, 'r') { |file| file_unit = file.read }
          file_details.push(count(file_unit) << file_name)
        end
      end
      file_details
    end

    def count(file_unit)
      @line = file_unit.lines.count,
              @word = file_unit.chomp.split.count,
              @byte = file_unit.bytesize
    end
  end
end

Wc::Command.new.excute
