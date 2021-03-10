# frozen_string_literal: true

require 'optparse'

module WC
  class Command
    attr_reader :options, :files

    def initialize
      @options = {}
      opt = OptionParser.new
      opt.on('-l', '--lines') { |v| @options[:l] = v }
      opt.parse!(ARGV)
      @files = ARGV
    end

    def option_select
      if options[:l] == true
        WC::Formatter.new.line(WC::File.new.data.flatten!)
      else
        WC::Formatter.new.normal(WC::File.new.data.flatten!)
      end
    end
  end

  class File < Command
    def data
      fdata = []
      if files.empty?
        funit = $stdin.read
        fdata.push count(funit)
      else
        files.each do |fname|
          ::File.open(fname, 'r') { |f| funit = f.read }
          fdata.push(count(funit) << fname)
        end
      end
      fdata
    end

    private

    def count(funit)
      @line = funit.lines.count,
              @word = funit.chomp.split.count,
              @byte = funit.bytesize
    end
  end

  class Formatter
    attr_reader :file

    def initialize
      @file = WC::File.new
    end

    def normal(files)
      result = []
      if files.length >= 4
        n = 0
        files.each do |fname|
          n += 1
          result << (n % 4 != 0 ? rayout(fname) : " #{fname}\n")
        end
      else
        files.map { |fname| result << rayout(fname) }
      end
      puts result.join('')
      puts "#{total(file.data)} total" if files.length > 4
    end

    def line(files)
      result = []
      if files.length >= 4
        n = 0
        files.each do |fname|
          n += 1
          result << rayout(fname) if n == 1 || ((n - 1) % 4).zero?
          result << " #{fname}\n" if (n % 4).zero?
        end
      else
        result << rayout(files.first)
      end
      puts result.join('')
      puts "#{total_line(file.data)} total" if files.length > 4
    end

    private

    def rayout(fname)
      fname.to_s.rjust(8, ' ')
    end

    def total(files)
      total = files.map { |a| a[0..2] }.transpose.map { |i| i.inject(:+) }
      total.map { |t| rayout(t) }.join('')
    end

    def total_line(files)
      rayout(files.map { |i| i[0] }.sum)
    end
  end
end

WC::Command.new.option_select
