#!/usr/bin/env ruby

require 'bindata'

# A class that knows how to parse the raw values from a single Korg Minilogue 
# program data file. No conversions are done.
#
class ProgramData < BinData::Record
  endian :little
                                          # File position:
  string :header, read_length: 4          # byte 0
  string :program_name, read_length: 16   # byte 4
  uint8 :vco1_pitch                       # byte 20
  uint8 :vco1_shape                       # byte 21
  uint8 :vco2_pitch                       # byte 22
  uint8 :vco2_shape                       # byte 23
  uint8 :vco2_cross_mod_depth             # byte 24
  uint8 :vco2_pitch_eg_int                # byte 25
  uint8 :mixer_vco1                       # byte 26
  uint8 :mixer_vco2                       # byte 27
  uint8 :mixer_noise                      # byte 28
  uint8 :filter_cutoff                    # byte 29
  uint8 :filter_resonance                 # byte 30
  uint8 :filter_eg_int                    # byte 31

  skip length: 2                          # byte 32

  uint8 :amp_eg_attack                    # byte 34
  uint8 :amp_eg_decay                     # byte 35
  uint8 :amp_eg_sustain                   # byte 36
  uint8 :amp_eg_release                   # byte 37
  uint8 :eg_attack                        # byte 38
  uint8 :eg_decay                         # byte 39
  uint8 :eg_sustain                       # byte 40
  uint8 :eg_release                       # byte 41
  uint8 :lfo_rate                         # byte 42
  uint8 :lfo_int                          # byte 43
  
  skip length: 8                          # byte 44

  bit2 :vco1_wave                         # byte 52 + 0 bits
  bit2 :vco1_octave                       # byte 52 + 2 bits
  bit4 :skip1                             # byte 52 + 4 bits
  bit2 :vco2_wave                         # byte 53 + 0 bits
  bit2 :vco2_octave                       # byte 53 + 2 bits
  bit4 :skip2                             # byte 53 + 4 bits
  
  skip length: 1                          # byte 54

  bit6 :skip3                             # byte 55 + 0 bits
  bit1 :vco2_ring                         # byte 55 + 6 bits
  bit1 :vco2_sync                         # byte 55 + 7 bits
  bit1 :skip4                             # byte 56 + 0 bits
  bit1 :filter_pole                       # byte 56 + 1 bit
  bit2 :filter_key_track                  # byte 56 + 2 bits
  bit2 :filter_velocity                   # byte 56 + 4 bits
  bit2 :skip5                             # byte 56 + 6 bits

  skip length: 2                          # byte 57

  bit2 :lfo_eg_mod                        # byte 59 + 0 bits
  bit2 :lfo_target                        # byte 59 + 2 bits
  bit4 :skip6                             # byte 59 + 4 bits
  bit6 :skip7                             # byte 60 + 0 bits
  bit2 :lfo_wave                          # byte 60 + 6 bits

  skip length: 12                         # byte 61

  bit5 :skip8                             # byte 73 + 0 bits
  bit3 :octave                            # byte 73 + 5 bits

  skip length: 26                         # byte 74

  uint16 :tempo                           # byte 100

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

  def tempo
    @data.tempo / 10.0
  end

  def octave
    normalize_octave(@data.octave)
  end

  # VCO1

  def vco1_octave
    normalize_octave(@data.vco1_octave)
  end

  def vco1_wave
    normalize_wave(@data.vco1_wave)
  end

  def vco1_pitch
    normalize_balanced_knob(@data.vco1_pitch)
  end

  def vco1_shape
    normalize_positive_knob(@data.vco1_shape)
  end

  # VCO2

  def vco2_octave
    normalize_octave(@data.vco2_octave)
  end

  def vco2_wave
    normalize_wave(@data.vco2_wave)
  end

  def vco2_pitch
    normalize_balanced_knob(@data.vco2_pitch)
  end

  def vco2_shape
    normalize_positive_knob(@data.vco2_shape)
  end

  def vco2_cross_mod_depth
    normalize_positive_knob(@data.vco2_cross_mod_depth)
  end

  def vco2_pitch_eg_int
    normalize_balanced_knob(@data.vco2_pitch_eg_int)
  end

  def vco2_sync
    on_off_switch(@data.vco2_sync)
  end

  def vco2_ring
    on_off_switch(@data.vco2_ring)
  end

  # Mixer

  def mixer_vco1
    normalize_positive_knob(@data.mixer_vco1)
  end

  def mixer_vco2
    normalize_positive_knob(@data.mixer_vco2)
  end

  def mixer_noise
    normalize_positive_knob(@data.mixer_noise)
  end

  # Filter

  def filter_cutoff
    normalize_positive_knob(@data.filter_cutoff)
  end

  def filter_resonance
    normalize_positive_knob(@data.filter_resonance)
  end

  def filter_eg_int
    normalize_balanced_knob(@data.filter_eg_int)
  end

  def filter_pole
    case @data.filter_pole
      when 0 then :two_pole
      when 1 then :four_pole
      else nil
    end
  end

  def filter_key_track
    case @data.filter_key_track
      when 0 then 0.0
      when 1 then 0.5
      when 2 then 1.0
      else nil
    end
  end

  def filter_velocity
    case @data.filter_velocity
      when 0 then 0.0
      when 1 then 0.5
      when 2 then 1.0
      else nil
    end
  end

  # AMP EG

  def amp_eg_attack
    normalize_positive_knob(@data.amp_eg_attack)
  end

  def amp_eg_decay
    normalize_positive_knob(@data.amp_eg_decay)
  end

  def amp_eg_sustain
    normalize_positive_knob(@data.amp_eg_sustain)
  end

  def amp_eg_release
    normalize_positive_knob(@data.amp_eg_release)
  end

  # EG

  def eg_attack
    normalize_positive_knob(@data.eg_attack)
  end

  def eg_decay
    normalize_positive_knob(@data.eg_decay)
  end

  def eg_sustain
    normalize_positive_knob(@data.eg_sustain)
  end

  def eg_release
    normalize_positive_knob(@data.eg_release)
  end

  # LFO

  def lfo_wave
    normalize_wave(@data.lfo_wave)
  end

  def lfo_eg_mod
    case @data.lfo_eg_mod
      when 0 then :off
      when 1 then :rate
      when 2 then :int
      else nil
    end
  end

  def lfo_rate
    normalize_positive_knob(@data.lfo_rate)
  end

  def lfo_int
    normalize_positive_knob(@data.lfo_int)
  end

  def lfo_target
    case @data.lfo_target
      when 0 then :cutoff
      when 1 then :shape
      when 2 then :pitch
      else nil
    end
  end

  private

  def normalize_wave(value)
    case value
      when 0 then :square
      when 1 then :triangle
      when 2 then :saw
      else nil
    end
  end

  def normalize_octave(value)
    value + 1
  end

  def normalize_positive_knob(value)
    value / 255.0
  end

  def normalize_balanced_knob(value)
    normalized = value - 128
    if normalized < 0
      normalized /= 128.0
    else
      normalized /= 127.0
    end
  end

  def on_off_switch(value)
    case value
      when 0 then :off
      when 1 then :on
      else nil
    end
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

    Tempo = #{@program.tempo} BPM
    Octave = #{@program.octave}

    VCO1 Wave = #{@program.vco1_wave}
    VCO1 Octave = #{@program.vco1_octave}
    VCO1 Pitch = #{vco1_pitch}
    VCO1 Shape = #{vco1_shape}

    VCO2 Wave = #{@program.vco2_wave}
    VCO2 Octave = #{@program.vco2_octave}
    VCO2 Pitch = #{vco2_pitch}
    VCO2 Shape = #{vco2_shape}

    VCO2 Cross Mod Depth = #{vco2_cross_mod_depth}
    VCO2 Pitch EG Int = #{vco2_pitch_eg_int}
    VCO2 Sync = #{@program.vco2_sync}
    VCO2 Ring = #{@program.vco2_ring}

    Mixer for VCO1 = #{mixer_vco1}
    Mixer for VCO2 = #{mixer_vco2}
    Mixer for Noise = #{mixer_noise}

    Filter Cutoff = #{filter_cutoff}
    Filter Resonance = #{filter_resonance}
    Filter EG Int = #{filter_eg_int}
    Filter Pole = #{filter_pole}
    Filter Key Track = #{filter_key_track}
    Filter Velocity = #{filter_velocity}

    AMP EG Attack  = #{amp_eg_attack}
    AMP EG Decay   = #{amp_eg_decay}
    AMP EG Sustain = #{amp_eg_sustain}
    AMP EG Release = #{amp_eg_release}

    EG Attack  = #{eg_attack}
    EG Decay   = #{eg_decay}
    EG Sustain = #{eg_sustain}
    EG Release = #{eg_release}

    LFO Wave = #{@program.lfo_wave}
    LFO EG Mod = #{@program.lfo_eg_mod}
    LFO Rate = #{lfo_rate}
    LFO Int = #{lfo_int}
    LFO Target = #{@program.lfo_target}

    EOF
  end

  def program_name
    @program.name.strip
  end

  def vco1_pitch
    format_cents(@program.vco1_pitch, 1200)
  end

  def vco1_shape
    format_percent(@program.vco1_shape)
  end

  def vco2_pitch
    format_cents(@program.vco2_pitch, 1200)
  end

  def vco2_shape
    format_percent(@program.vco2_shape)
  end

  def vco2_cross_mod_depth
    format_percent(@program.vco2_cross_mod_depth)
  end

  def vco2_pitch_eg_int
    format_cents(@program.vco2_pitch_eg_int, 4800)
  end

  def mixer_vco1
    format_percent(@program.mixer_vco1)
  end

  def mixer_vco2
    format_percent(@program.mixer_vco2)
  end

  def mixer_noise
    format_percent(@program.mixer_noise)
  end

  def filter_cutoff
    format_percent(@program.filter_cutoff)
  end

  def filter_resonance
    format_percent(@program.filter_resonance)
  end

  def filter_eg_int
    format_percent(@program.filter_eg_int)
  end

  def filter_pole
    case @program.filter_pole
      when :two_pole  then '2-Pole'
      when :four_pole then '4-Pole'
      else nil
    end
  end

  def filter_key_track
    format_percent(@program.filter_key_track)
  end

  def filter_velocity
    format_percent(@program.filter_velocity)
  end

  def amp_eg_attack
    format_percent(@program.amp_eg_attack)
  end

  def amp_eg_decay
    format_percent(@program.amp_eg_decay)
  end

  def amp_eg_sustain
    format_percent(@program.amp_eg_sustain)
  end

  def amp_eg_release
    format_percent(@program.amp_eg_release)
  end

  def eg_attack
    format_percent(@program.eg_attack)
  end

  def eg_decay
    format_percent(@program.eg_decay)
  end

  def eg_sustain
    format_percent(@program.eg_sustain)
  end

  def eg_release
    format_percent(@program.eg_release)
  end

  def lfo_rate
    format_percent(@program.lfo_rate)
  end

  def lfo_int
    format_percent(@program.lfo_int)
  end

  private

  def format_cents(value, max_value)
    if value.nil?
      nil
    else
      "#{(value * max_value).round}C"
    end
  end

  def format_percent(value)
    if value.nil?
      nil
    else
      "#{(value * 100).round}%"
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
