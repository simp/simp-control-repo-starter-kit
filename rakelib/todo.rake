desc "Show a todolist from all the TODO|FIXME|THINK tags in the source"
task :todo, [:fail_on_todo, :fail_on_fixme]  do |_t, args|
  args.with_defaults(
    fail_on_todo:  'no',
    fail_on_fixme: 'yes',
  )
  underyellow = "\e[4;33m%s\e[0m"
  underred    = "\e[4;31m%s\e[0m"
  undergreen  = "\e[4;32m%s\e[0m"
  undercolor = ""

  color = ""
  fixmes = 0
  todos = 0

  Dir.glob('{site,data,manifests}/**/*.{pp,yaml,erb,epp,rb,xhtml}') do |file|
    lastline = todo = comment = long_comment = false

    File.readlines(file).each_with_index do |line, lineno|
      lineno      += 1
      comment      = line =~ /^\s*?#.*?$/
      long_comment = line =~ /^=begin/
      long_comment = line =~ /^=end/

      todo = true if line =~ /(TODO|FIXME|THINK)/ and (long_comment or comment)

      fixmes += 1 if ($1 && $1.strip == 'FIXME')
      todos += 1 if ($1 && $1.strip == 'TODO')

      todo = false if line.gsub('#', '').strip.empty?
      todo = false unless comment or long_comment

      undercolor = underyellow if line =~ /TODO/
      undercolor = underred    if line =~ /FIXME/
      undercolor = undergreen  if line =~ /THINK/

      color = undercolor.gsub('4', '0')

      if todo
        unless lastline and lastline + 1 == lineno
          puts
          puts undercolor % "#{file}# #{lineno} : "
        end

        l = '  . ' + line.strip.gsub(/^#\s*/, '')
        #print '  . ' unless l =~ /^-/
        puts color % l
        lastline = lineno
      end
    end # File.readlines
  end

  final, boo = [], nil
  if todos > 0
    boo = true unless args[:fail_on_todo] =~ /\Ano|false\Z/i
    final << "#{boo ? 'FAIL' : 'WARN'}: Found #{todos} TODOS"
  end

  if fixmes > 0
    boo ||= _boo = true unless args[:fail_on_fixme] =~ /\Ano|false\Z/i
    final << "#{_boo ? 'FAIL' : 'WARN'}: Found #{fixmes} FIXMES" if (fixmes > 0)
  end

  unless final.empty?
    abort("\n#{final.join("\n")}") if boo
    warn("\n#{final.join("\n")}")
  end
end # task :todo

