#!/usr/bin/env ruby

require 'bindata'

class Header < BinData::Record
  string :declaration, read_length: 4
  string :program_name, read_length: 16
end

class Values < BinData::Record
  endian :little
  int16 :v1
  int16 :v2
  int16 :v3
  int16 :v4
  int16 :v5
  int16 :v6
  int16 :v7
  int16 :v8
  int16 :v9
  int16 :v10
  int16 :v11
  int16 :v12
end


io = File.open("examples/empty/Prog_000.prog_bin")
header  = Header.read(io)
values  = Values.read(io)

p header.declaration
p header.program_name.strip
puts "v1  = #{values.v1}"
puts "v2  = #{values.v2}"
puts "v3  = #{values.v3}"
puts "v4  = #{values.v4}"
puts "v5  = #{values.v5}"
puts "v6  = #{values.v6}"
puts "v7  = #{values.v7}"
puts "v8  = #{values.v8}"
puts "v9  = #{values.v9}"
puts "v10 = #{values.v10}"
puts "v11 = #{values.v11}"
puts "v12 = #{values.v12}"


