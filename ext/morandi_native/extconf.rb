require 'mkmf'

  require 'rubygems'
  gem 'glib2'
  require 'mkmf-gnome2'
  %w[rbglib.h rbpango.h].each do |header|
    Gem.find_files(header).each do |f|
      $CFLAGS += " '-I#{File.dirname(f)}'"
    end
  end
# Look for headers in {gem_root}/ext/{package}
  %w[glib2].each do |package|
    require package
    if Gem.loaded_specs[package]
      $CFLAGS += " -I" + Gem.loaded_specs[package].full_gem_path + "/ext/" + package
    else
      if fn = $".find { |n| n.sub(/[.](so|rb)$/, '') == package }
        dr = $:.find { |d| File.exist?(File.join(d, fn)) }
        pt = File.join(dr, fn) if dr && fn
      else
        pt = "??"
      end
      STDERR.puts "require '" + package + "' loaded '" + pt + "' instead of the gem - trying to continue, but build may fail"
    end
  end
if RbConfig::CONFIG.has_key?('rubyhdrdir')
  $CFLAGS += " -I" + RbConfig::CONFIG['rubyhdrdir'] + '/ruby'
end

$CFLAGS += " -I."
have_func("rb_errinfo")
PKGConfig.have_package("gdk-pixbuf-2.0") or exit(-1)
PKGConfig.have_package("gdk-2.0") or exit(-1)

unless have_header("gdk-pixbuf/gdk-pixbuf.h")
  paths = Gem.find_files("gdk-pixbuf/gdk-pixbuf.h")
  paths.each do |path|
    $CFLAGS += " '-I#{File.dirname(path)}'"
  end
  have_header("gdk-pixbuf/gdk-pixbuf.h") or exit -1
end

unless have_header("rbglib.h")
  paths = Gem.find_files("rbglib.h")
  paths.each do |path|
    $CFLAGS += " '-I#{File.dirname(path)}'"
  end
  have_header("rbglib.h") or exit -1
end

unless have_header("rbgobject.h")
  paths = Gem.find_files("rbgobject.h")
  paths.each do |path|
    $CFLAGS += " '-I#{File.dirname(path)}'"
  end
  have_header("rbgobject.h") or exit -1
end

$defs << "-DHAVE_OBJECT_ALLOCATE"

top = File.expand_path(File.dirname(__FILE__) + '/..') # XXX
$CFLAGS += " " + ['glib/src'].map { |d|
  "-I" + File.join(top, d)
}.join(" ")

begin
  srcdir = File.expand_path(File.dirname($0))

  begin
    obj_ext = "." + $OBJEXT
    $libs = $libs.split(/ /).uniq.join(' ')
    $source_files = Dir.glob(sprintf("%s/*.c", srcdir)).map { |fname|
      fname[0, srcdir.length + 1] = ''
      fname
    }
    $objs = $source_files.collect do |item|
      item.gsub(/.c$/, obj_ext)
    end

    #
    # create Makefile
    #
    $defs << "-DRUBY_MORANDI_NATIVE_COMPILATION"
    create_makefile("morandi_native", srcdir)
    raise Interrupt if not FileTest.exist? "Makefile"

    File.open("Makefile", "a") do |mfile|
      $source_files.each do |e|
        mfile.print sprintf("%s: %s\n", e.gsub(/.c$/, obj_ext), e)
      end
    end
  end
rescue Interrupt
  print "  [error] " + $!.to_s + "\n"
end

