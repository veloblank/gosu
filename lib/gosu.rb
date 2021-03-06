require "rbconfig"

if RUBY_PLATFORM =~ /mswin$|mingw32|mingw64|win32\-|\-win32/
  binary_path = File.dirname(__FILE__)
  # 64-bit builds of Windows use "x64-mingw32" as RUBY_PLATFORM
  binary_path += "64" if RUBY_PLATFORM =~ /^x64-/
  
  # Add this gem to the PATH on Windows so that bundled DLLs can be found.
  # When running through Ocra on Windows, we need to be careful to preserve the ENV["PATH"]
  # encoding (see #385).
  ENV["PATH"] = "#{binary_path.encode ENV["PATH"].encoding};#{ENV["PATH"]}"
  
  # Add the correct lib directory for the current version of Ruby (major.minor).
  $LOAD_PATH.unshift File.join(binary_path, RUBY_VERSION[/^\d+.\d+/])
end

require "gosu.#{RbConfig::CONFIG["DLEXT"]}"

require "gosu/swig_patches"
require "gosu/patches"
require "gosu/compat"
