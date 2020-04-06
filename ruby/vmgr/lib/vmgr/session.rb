# Ruby Vmgr (Vmanager) library
#
# Creation Date: AUG/2019
# Author: <thorsten.dworzak@verilab.com

module Vmgr

    #
    # Class collecting all test or run-containers of a vmanager session
    # runs are extracted from .vsof files, tests (in groups) from .vsif files
    #
    class Session < Struct.new(:description)

      # Initialize
      def initialize(_description)
          super(_description)

          @@block_re            = Regexp.new(/(\w+)\s+([\w"]+)\s+\{/)
          @@vsof_entry_re       = Regexp.new(/(\w+)\s+:\s+(<text>\s*)*([^;<]+)(<\/text>)*\s*;/)
          # The vsif regexp requires preprocessing to remove leading whitespace
          @@vsif_container_re   = Regexp.new(/^(session|group|test|extend)\s+(\w+)\s*/)
          @@vsif_entry_re       = Regexp.new(/^(\w+)\s*:\s*(<text>|")*([^;"<]+)(<\/text>|")*\s*;/)
          @@include_re          = Regexp.new('^#include\s+\"([\w+\.]+)\"')
      end

      # Read all unique .vsof files of a session and populate the runs member
      def read_vsofs(filenames)
          @kind = :vsof
          # Iterate over all .vsof files of a session and extract a run-container for each
          @runs = []
          filenames.each {|filename|
            run_container = get_single_run_container(filename)
            if run_container then
                @hattribs["runs"].push(run_container)
            else
                STDERR.puts "#{ME} [ERROR]: no single-run container found in vsof file #{filename}"
            end
          }
      end

      # Read a .vsif file and populate the groups member
      def read_vsif(filename)
          @kind              = :vsif
          @context           = []
          @session_container = nil
          lines              = [];
          container_type     = ""
          container_name     = ""
          brace_open         = false;

          lines.concat(pre_process_vsif(filename));

          # Iterate over all lines and parse the {... } container entries
          lines.each { |line |
            line.chomp
            begin
                match_found = false
                match = @@vsif_container_re.match(line);
                if match then
                  match_found = true
                  # parse .vsif for container and push respective context to stack
                  container_type, container_name = match[1..2];
                  add_to_context_stack(container_type, container_name)
                  line = match.post_match.strip
                  brace_open = false;
                end

                if line =~ /\{\s*/ then
                  match_found = true
                  brace_open = true
                  line = $'.strip
                  # puts "bo #{n_line}:#{line}\n"
                end

                if brace_open then
                  # Pick up attributes
                  match_found, line = parse_vsif_attribs(line)
                end

                next if match_found

                if line =~ /\}\s*(;)?\s*/ then
                	if $1 != ";" then
                		STDERR.puts "#{ME} [ERROR]: parse error, closing brace without semicolon (#{line})"
                		return false
                	end
                  # pop context and add container object to enclosing container
                  match_found = true
                  brace_open  = false
                  return false if !link_parsed_container()
                  line = $'.strip
                end
            end while line.length > 0 && match_found
          }
          return true
      end

      def add_to_context_stack(container_type, container_name)
          case container_type
          when "session"
            if !@session_container
                @session_container = SessionContainer.new(container_name, description, @kind)
            else
                @session_container.name = container_name
            end
          when "group"
            @context.push(GroupContainer.new(container_name))
          when "test"
            @context.push(TestContainer.new(container_name))
          when "extend"
            if @context.size > 0 then
                existing = @context[-1].find_group(container_name)
                if existing then
                  @context.push(existing)
                else
                  @context.reverse_each { |it|
                      existing = it.find_test(container_name)
                      break if existing != nil
                  }
                  @context.push(existing) if existing
                end
                if !existing then
                  STDERR.puts "#{ME} [ERROR]: extend #{container_name} does not extend a known container"
                  return 0
                end
            end
          end
      end

      def link_parsed_container()
          return true if @context.size == 0

          container = @context.pop
          if @context.size == 0
            if container.ctype == :group then
                @session_container = SessionContainer.new("unknown", description, @kind) if !@session_container
                @session_container.add_group(container)
            else
                STDERR.puts "#{ME} [ERROR]: container nesting error for #{container.ctype.to_s} #{container.name}"
                return false
            end
          else
            parent_container = @context[-1]
            if parent_container.ctype == :test then
                STDERR.puts "#{ME} [ERROR]: cannot nest container #{container.ctype.to_s} #{container.name} in #{parent_container.ctype}"
                return false
            end
            case container.ctype
            when :group
                parent_container.add_group(container)
            when :test
                parent_container.add_test(container)
            else
                STDERR.puts "#{ME} [ERROR]: container nesting error for #{container.ctype.to_s} #{container.name}"
                return false
            end
          end
          return true
      end

      def parse_vsif_attribs(str)
          if @context.size == 0 then
            container = @session_container
          else
            container = @context[-1]
          end
          match_found = false
          match = @@vsif_entry_re.match(str)
          if match then
            match_found = true
            key         = match[1];
            if match[2] then
                value = "<text>"+match[3]+"</text>"
            else
                value = match[3];
            end
            if value.strip.length != 0
                container.add_attribute(key, value)
            end
            str = match.post_match
          end
          return match_found, str
      end

      def write_vsif(filename)
          File.open(filename, "w") do |file|
            @session_container.write(file)
          end
      end

      # Slurp the .vsif and it's includes into an array containing each line
      def pre_process_vsif(filename)
          result = [];
          begin
            IO.foreach(filename) {|line|
                line.strip!
                next if line == ""            # skip empty lines
                next if line =~ /^\s*\/\//    # skip comments
                match = @@include_re.match(line)
                if match then
                  result.concat(pre_process_vsif(match[1]))
                else
                  result << line.chomp
                end
            }
          rescue Exception
            STDERR.puts("#{ME} [ERROR]: File I/O: #{filename}")
            return []
          end
          return result
      end

      # Parse a single-run vsof file and return its run-container
      def get_single_run_container(filename)
          block_lvl     = 0
          run_container = nil
          block_name    = ""
          block_val     = ""
          n_line        = 0;
          # Iterated over all lines and parse the {... } block entries
          IO.foreach(filename) {|line|
            n_line += 1
            match = @@block_re.match(line);
            if match != nil then
                # Block start
                block_name = match[1];
                block_val  = match[2];
                block_lvl += 1
                # print "block \"#{block_name}\" value \"#{block_val}\" level #{block_lvl}\n"
                next
            elsif line =~ /^\s*\}\s*$/ then
                # Block end
                block_lvl -= 1
                break if run_container != nil
                next
            elsif block_lvl == 1 then
                match  = @@vsof_entry_re.match(line)
                if (match != nil) and (match[1] != nil) then
                  attrib = match[1]
                  value  = match[3]
                  case block_name
                  when "run"
                      # extract the real testname that is hidden in the parent_run attribute
                      next if (attrib == "test_name")
                      if (attrib == "parent_run") then
                        attrib = "test_name"
                      end
                      match = /(\w+)@\d+/.match(value)
                      if match then
                        value = match[1]
                      else
                        STDERR.puts "#{ME} [ERROR]: could not extract testname from parent_run attribute (file #{filename} line #{n_line}: #{line})"
                        value = "UNKNOWN"
                      end

                      if !run_container then
                        run_container = RunContainer.new(block_val)
                      end
                      # Extract only one seed
                      if attrib == "sv_seed"
                        attrib = "seed"
                      end
                      run_container.add_attribute(atrrib,  value)
                  when "session_output"
                      # check if this is the correct file-type
                      if (attrib == "session_type" && value != "single_run")
                        STDERR.puts "#{ME} [ERROR]: session_type #{value} not supported (file #{filename} line #{n_line}; must be single_run.)"
                        return nil
                      end
                  end
                end
            end
          }
          return run_container
      end
    end
end
