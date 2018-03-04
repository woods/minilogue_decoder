#!/usr/bin/env ruby

require 'bindata'

class Header < BinData::Record
  string :declaration, read_length: 4
  string :program_name, read_length: 16
end

class Oscillator1 < BinData::Record
  skip length: 32
  bit2 :wave_value
  bit2 :octave_value

  def wave
    case wave_value
      when 1 then "Square"
      when 2 then "Triangle"
      when 0 then "Saw"
    end
  end

  def octave
    octave_value == 0 ? 4 : octave_value
  end
end

if ARGV.length == 1
  input_file = ARGV.first
else
  puts "Usage: ruby decode.rb path/to/Prog_101.prog_bin"
  exit 1
end

io = File.open(input_file)
header  = Header.read(io)
o1 = Oscillator1.read(io)

p header.declaration
p header.program_name.strip
puts "o1.wave = #{o1.wave}"
puts "o1.octave = #{o1.octave}"
