# frozen_string_literal: true

# rubocop:disable Style/GlobalVars
require 'mkmf'

require 'English'
require 'rubygems'
gem 'glib2'
require 'mkmf-gnome'

def macos?
  !!(RUBY_PLATFORM =~ /darwin/)
end

def clang?
  cc_version = `#{RbConfig.expand('$(CC) --version' + '')}`
  cc_version.match?(/clang/i)
end

# XCode 14 warns if `-Wl,-undefined dynamic_lookup` is specified, and as
# a result Ruby interpreters compiled under XCode 14 no longer specify
# this flag by default in DLDFLAGS. Let's specify the list of dynamic symbols
# here to avoid compilation failures.
if clang? && macos?
  dynamic_symbols = %w[
    _rbgobj_instance_from_ruby_object
    _rbgobj_ruby_object_from_instance
  ]
  dynamic_symbols.each do |sym|
    $DLDFLAGS << " -Wl,-U,#{sym.strip}"
  end
end

%w[rbglib.h rbpango.h].each do |header|
  Gem.find_files(header).each do |f|
    $CFLAGS += " '-I#{File.dirname(f)}'"
  end
end
# Look for headers in {gem_root}/ext/{package}
%w[glib2].each do |package|
  require package
  if Gem.loaded_specs[package]
    $CFLAGS += " -I#{Gem.loaded_specs[package].full_gem_path}/ext/#{package}"
  else
    fn = $LOADED_FEATURES.find { |n| n.sub(/[.](so|rb)$/, '') == package }
    if fn
      dr = $LOAD_PATH.find { |d| File.exist?(File.join(d, fn)) }
      pt = File.join(dr, fn) if dr && fn
    else
      pt = '??'
    end
    warn "require '#{package}' loaded '#{pt}' instead of the gem - trying to continue, but build may fail"
  end
end
$CFLAGS += " -I#{RbConfig::CONFIG['rubyhdrdir']}/ruby" if RbConfig::CONFIG.key?('rubyhdrdir')

$CFLAGS += ' -I.'
have_func('rb_errinfo')
PKGConfig.have_package('gdk-pixbuf-2.0') or exit(-1)
# PKGConfig.have_package('gdk-2.0') or exit(-1)

unless have_header('gdk-pixbuf/gdk-pixbuf.h')
  paths = Gem.find_files('gdk-pixbuf/gdk-pixbuf.h')
  paths.each do |path|
    $CFLAGS += " '-I#{File.dirname(path)}'"
  end
  have_header('gdk-pixbuf/gdk-pixbuf.h') or exit(-1)
end

unless have_header('rbglib.h')
  paths = Gem.find_files('rbglib.h')
  paths.each do |path|
    $CFLAGS += " '-I#{File.dirname(path)}'"
  end
  have_header('rbglib.h') or exit(-1)
end

unless have_header('rbgobject.h')
  paths = Gem.find_files('rbgobject.h')
  paths.each do |path|
    $CFLAGS += " '-I#{File.dirname(path)}'"
  end
  have_header('rbgobject.h') or exit(-1)
end

$defs << '-DHAVE_OBJECT_ALLOCATE'

top = File.expand_path("#{File.dirname(__FILE__)}/..") # XXX
$CFLAGS << ' ' << ['glib/src'].map do |d|
  "-I#{File.join(top, d)}"
end.join(' ')

begin
  srcdir = File.expand_path(File.dirname($PROGRAM_NAME))

  obj_ext = ".#{$OBJEXT}"
  $libs = $libs.split(/ /).uniq.join(' ')
  $source_files = Dir.glob(format('%s/*.c', srcdir)).map do |fname|
    fname[0, srcdir.length + 1] = ''
    fname
  end
  $objs = $source_files.collect do |item|
    item.gsub(/.c$/, obj_ext)
  end

  #
  # create Makefile
  #
  $defs << '-DRUBY_MORANDI_NATIVE_COMPILATION'
  create_makefile('morandi_native', srcdir)
  raise Interrupt unless FileTest.exist? 'Makefile'

  File.open('Makefile', 'a') do |mfile|
    $source_files.each do |e|
      mfile.print("#{e.gsub(/.c$/, obj_ext)}: #{e}\n")
    end
  end
rescue Interrupt
  print "  [error] #{$ERROR_INFO}\n"
end
# rubocop:enable Style/GlobalVars
