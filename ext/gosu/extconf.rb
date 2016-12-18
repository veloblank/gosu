#!/usr/bin/env ruby

if RUBY_PLATFORM =~ /mswin$|mingw32|mingw64|win32\-|\-win32/
  platform = (RUBY_PLATFORM =~ /^x64-/ ? 'x64-mingw32' : 'i386-mingw32')
  
  puts "This gem is not meant to be installed on Windows. Instead, please use:"
  puts "gem install gosu --platform=#{platform}"
  exit 1
end

puts 'The Gosu gem requires some libraries to be installed system-wide.'
puts 'See the following site for a list:'
if `uname`.chomp == 'Darwin'
  puts 'https://github.com/gosu/gosu/wiki/Getting-Started-on-OS-X'
else
  puts 'https://github.com/gosu/gosu/wiki/Getting-Started-on-Linux'
end

BASE_FILES = %w(
  Bitmap.cpp
  BitmapIO.cpp
  BlockAllocator.cpp
  Color.cpp
  DirectoriesUnix.cpp
  FileUnix.cpp
  Font.cpp
  Graphics.cpp
  Image.cpp
  Input.cpp
  Inspection.cpp
  IO.cpp
  LargeImageData.cpp
  Macro.cpp
  Math.cpp
  Resolution.cpp
  TexChunk.cpp
  Text.cpp
  TextInput.cpp
  Texture.cpp
  Transform.cpp
  Utility.cpp
  Window.cpp
  stb_vorbis.c
)

MAC_FILES = %w(
  Audio.mm
  ResolutionApple.mm
  TextApple.mm
  TimingApple.cpp
  UtilityApple.mm
)

LINUX_FILES = %w(
  Audio.cpp
  TextUnix.cpp
  TimingUnix.cpp
)

require 'mkmf'
require 'fileutils'

# Silence internal deprecation warnings in Gosu
$CFLAGS << " -DGOSU_DEPRECATED="

$CXXFLAGS ||= ""
$CXXFLAGS << " -std=gnu++11"

$INCFLAGS << " -I../.. -I../../src"

if `uname`.chomp == 'Darwin'
  SOURCE_FILES = BASE_FILES + MAC_FILES
  
  # To make everything work with the Objective C runtime
  $CFLAGS   << " -x objective-c -fobjc-arc -DNDEBUG"
  # Compile all C++ files as Objective C++ on OS X since mkmf does not support .mm
  # files.
  $CXXFLAGS << " -x objective-c++ -fobjc-arc -DNDEBUG"

  # Explicitly specify libc++ as the standard library.
  # rvm will sometimes try to override this:
  # https://github.com/shawn42/gamebox/issues/96
  $CXXFLAGS << " -stdlib=libc++"
  
  # Dependencies.
  $CXXFLAGS << " #{`sdl2-config --cflags`.chomp}"
  # Prefer statically linking SDL 2.
  $LDFLAGS  << " #{`sdl2-config --static-libs`.chomp} -framework OpenGL -framework OpenAL"
  
  # Disable building of 32-bit slices in Apple's Ruby.
  # (RbConfig::CONFIG['CXXFLAGS'] on 10.11: -arch x86_64 -arch i386 -g -Os -pipe)
  $CFLAGS.gsub! "-arch i386", ""
  $CXXFLAGS.gsub! "-arch i386", ""
  $LDFLAGS.gsub! "-arch i386", ""
  $ARCH_FLAG.gsub! "-arch i386", ""
  CONFIG['LDSHARED'].gsub! "-arch i386", ""
else
  SOURCE_FILES = BASE_FILES + LINUX_FILES

  if /Raspbian/ =~ `cat /etc/issue` or /BCM2708/ =~ `cat /proc/cpuinfo`
    $INCFLAGS << " -I/opt/vc/include/GLES"
    $INCFLAGS << " -I/opt/vc/include"
    $LDFLAGS << " -L/opt/vc/lib"
    $LDFLAGS << " -lGLESv1_CM"
  else
    pkg_config 'gl'
  end

  pkg_config 'sdl2'
  pkg_config 'pangoft2'
  pkg_config 'vorbisfile'
  pkg_config 'openal'
  pkg_config 'sndfile'
  
  have_header 'SDL_ttf.h' if have_library('SDL2_ttf', 'TTF_RenderUTF8_Blended')
  have_header 'AL/al.h'   if have_library('openal')
end

# This is necessary to build on stock Ruby on OS X 10.7.
CONFIG['CXXFLAGS'] ||= $CXXFLAGS

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("1.9.3") and
   Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.2.0")
  # In some versions of Ruby and mkmf, the $CXXFLAGS variable is badly broken.
  # We can modify CONFIG instead, and our changes will end up in the Makefile.
  # See http://bugs.ruby-lang.org/issues/8315
  # The lower bound was reduced to 1.9.3 here: https://github.com/gosu/gosu/issues/321
  CONFIG['CXXFLAGS'] = "#$CFLAGS #$CXXFLAGS"
end

create_makefile 'gosu'
