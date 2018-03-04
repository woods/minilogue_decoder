#!/usr/bin/env ruby

require 'bindata'

# A class that knows how to parse the raw values from a single Korg Minilogue 
# program data file. No conversions are done.
#
class ProgramData < BinData::Record       # File position (in bytes):
  string :header, read_length: 4          # 0
  string :program_name, read_length: 16   # 4
  uint8 :osc1_pitch                       # 20
  uint8 :osc1_shape                       # 21

  skip length: 30                         # 22
  
  bit2 :osc1_wave                         # 52 + 0 bits
  bit2 :osc1_octave                       # 52 + 2 bits
end

# A class that knows how to convert the raw program data values into more
# meaningful, calculatable values. 
# 
# - Switch values are returned as symbols, e.g. :triangle, :off, :bypass
# - Knob values range from either 0.0 to 1.0 or from -1.0 to 1.0, depending
#   on the function of the knob
#
class Program

  def initialize(program_data)
    @data = program_data
    if @data.header != "PROG"
      raise ArgumentError "Incorrect format: could not find header for program file"
      exit 1
    end
  end

  def name
    @data.program_name
  end

  def osc1_wave
    case @data.osc1_wave
      when 1 then :square
      when 2 then :triangle
      when 0 then :saw
    end
  end

  def osc1_octave
    @data.osc1_octave == 0 ? 4 : @data.osc1_octave
  end

  def osc1_pitch
    normalized = @data.osc1_pitch - 128
    if normalized < 0
      normalized /= 128.0
    else
      normalized /= 127.0
    end
  end

  def osc1_shape
    @data.osc1_shape / 255.0
  end

end

# A class that is useful for outputting program values. It knows the names
# and sequence of all the attributes, and it can format the values for 
# display, e.g. showing knobs as a percentage, or as their proper values, 
# and converting switch values to English strings.
#
class ProgramFormatter

  def initialize(program)
    @program = program
  end

  # Return a sensible text rendering of the program
  def to_s
    <<-EOF
    Program name = #{program_name}
    OSC1 Wave = #{@program.osc1_wave}
    OSC1 Octave = #{@program.osc1_octave}
    OSC1 Pitch = #{osc1_pitch}
    OSC1 Shape = #{osc1_shape}
    EOF
  end

  def program_name
    @program.name.strip
  end

  def osc1_pitch
    if @program.osc1_pitch.nil?
      nil
    else
      "#{(@program.osc1_pitch * 1200).round}C"
    end
  end

  def osc1_shape
    if @program.osc1_shape.nil?
      nil
    else
      "#{(@program.osc1_shape * 100).round}%"
    end
  end

end

# Command-line execution

if ARGV.length == 1
  input_file = ARGV.first
else
  puts "Usage: ruby decode.rb path/to/Prog_101.prog_bin\n"
  exit 1
end

io = File.open(input_file)
program_data  = ProgramData.read(io)
p program_data
program = Program.new(program_data)
formatter = ProgramFormatter.new(program)
print formatter
