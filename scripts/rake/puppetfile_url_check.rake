require 'simp/rake/pupmod/helpers'
namespace :puppetfile do

  desc <<-EOM
    Checks all git URLs in the Puppetfile.

    Args:
      * :strict => Fail on warnings, accepts 'true' and 'false'. Defaults to 'false'.
  EOM
  task :url_check, [:strict] do |t, args|
    require 'simp/rake/build/deps'
    require 'highline'

    HighLine.colorize_strings

    args.with_defaults(:strict => 'false')

    strict = args[:strict] == 'true' ? true : false

    puppetfile = R10KHelper.new('Puppetfile')

    stats = {
      :warning => 0,
      :error => 0,
      :ok => 0
    }

    puppetfile.modules.each do |mod|
      name = mod[:r10k_module].full_name

      # Yeah, this isn't good, but it's not exposed
      args = mod[:r10k_module].instance_variable_get('@args')

      git_repo = args[:git]

      next unless git_repo

      git_tag = args[:tag]
      git_branch = args[:branch]

      unless git_tag || git_branch
        $stderr.puts("WARNING: Module '#{name}' is not using a branch or tag reference".yellow)
        stats[:warning] += 1
        next
      end

      git_remote_refs = %x(git ls-remote -h -t #{git_repo} 2>/dev/null).scan(/refs\/.*$/)

      unless $?.success?
        $stderr.puts("ERROR: Invalid Repository #{git_repo}".red)
        stats[:error] += 1
        next
      end

      if git_remote_refs.include?("refs/tags/#{git_tag}") || git_remote_refs.include?("refs/heads/#{git_branch}")
        $stdout.puts("OK: Module '#{name}'".green)
        stats[:ok] += 1
      elsif git_tag
        $stdout.puts("ERROR: Module '#{name}' does not contain tag '#{git_tag}' ".red)
        stats[:error] += 1
      else
        $stdout.puts("ERROR: Module '#{name}' does not contain branch '#{git_branch}' ".red)
        stats[:error] += 1
      end
    end

    $stdout.puts("Stats:")
    $stdout.puts("  OK: #{stats[:ok]}".green)
    $stdout.puts("  WARNING: #{stats[:warning]}".yellow)
    $stdout.puts("  ERROR: #{stats[:error]}".red)

    if stats[:error] != 0
      exit 1
    end

    if stats[:warning] != 0
      if strict
        exit 2
      end
    end
  end

end
