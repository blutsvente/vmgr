# Ruby Vmgr (Vmanager) library
#
# Creation Date: AUG/2019
# Author: <tlemail69-github@yahoo.com>
# ---
module Vmgr

    #
    # Class collecting all test or run-containers of a vmanager session
    # runs are extracted from .vsof files, tests (in groups) from .vsif files
    #
    class Session < Struct.new(:description, :name)

      attr_accessor :session_container
      attr_accessor :kind

      # Initialize
      def initialize(_description, _kind = :vsif, _name = "Session")
          super(_description, _name)
          @session_container    = nil
          @kind                 = _kind
          @@block_re            = Regexp.new(/(\w+)\s+([\w"]+)\s+\{/)
          @@vsof_entry_re       = Regexp.new(/(\w+)\s+:\s+(<text>\s*)*([^;<]+)(<\/text>)*\s*;/)
          # The vsif regexp requires preprocessing to remove leading whitespace
          @@vsif_container_re   = Regexp.new(/^(session|group|test|extend)\s+(\w+)\s*/)
          @@vsif_entry_key_re   = Regexp.new(/^(\w+)\s*(:)*/)
          @@vsif_entry_value_re = Regexp.new(/^(<text>|")*([^;"<]+)(<\/text>|")*\s*;/)
          @@include_re          = Regexp.new('^#include\s+\"([^\"]+)\"')
      end

      # Read all unique .vsof files of a session and populate the runs member
      # Returns false on error
      def read_vsofs(filenames)
          @kind = :vsof
          # Iterate over all .vsof files of a session and extract a run-container for each
          @runs = []
          filenames.each {|filename|
            run_container = get_single_run_container(filename)
            if run_container then
                @hattribs["runs"].push(run_container)
            else
                STDERR.puts "#{name} [ERROR]: no single-run container found in vsof file #{filename}"
                return false
            end
          }
          return true
      end

      # Read a .vsif file and populate the groups member; returns false for some errors (other errors
      # trigger only a message on STDERR)
      def read_vsif(filename)
          @kind              = :vsif
          @context           = []
          @session_container = nil
          lines              = [];
          container_type     = ""
          container_name     = ""
          brace_open         = false;

          lines.concat(pre_process_vsif(filename));
          STDERR.puts "#{name} [WARNING]: file #{filename} empty\n" if lines.empty?

          # Iterate over all lines and parse the {... } container entries
          # TODO: does not create container object with no attributes (e.g. no {...};)
          lines.each { |line |
            line.chomp
            begin
                match_found = false
                match = @@vsif_container_re.match(line)
                if match then
                  match_found = true
                  # Parse .vsif for container and push respective context to stack
                  container_type, container_name = match[1..2]
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
                  match_found, line, parse_error = parse_vsif_attribs(line)
                  return false if parse_error
                end

                next if match_found

                if line =~ /\}\s*(;)?\s*/ then
                	if $1 != ";" then
                		STDERR.puts "#{name} [ERROR]: read_vsif(): parse error, closing brace without semicolon (#{line.red})"
                		return false
                	end

                  # Pop context and add container object to enclosing container
                  match_found = true
                  # brace_open  = false
                  return false if !link_parsed_container()
                  line = $'.strip
                end

                if !match_found && line.length()>0
                  if /^\s*\/\//.match(line)
                    line = ""
                  else
                    puts "#{name} [WARNING]: read_vsif(): suspicious trailing string found or missing semicolon (#{line.red})"
                  end
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
            if @context.size == 0 then
              if !@session_container then
                STDERR.puts "#{name} [ERROR]: extension of '#{container_name}' before container definition (currently unsupported)"
                return false
              end
              # search extended container in groups
              existing = @session_container.find_group(container_name)
              if !existing then
                STDERR.puts "#{name} [ERROR]: cannot place extension '#{container_name}' in previously defined group!"
                return false
              end
              # remove group because after extension it will be added again
              @context.push(@session_container.remove_group(container_name))
            else
              parent_container = @context[-1]
              existing = parent_container.find_group(container_name)
              if existing then
                # remove group and add it to top of context stack
                @context.push(parent_container.remove_group(container_name))
              else
                existing = parent_container.find_test(container_name)
                if existing then
                  # remove test and add it to top of context stack
                  @context.push(parent_container.remove_test(container_name))
                end
                # not found in groups, maybe a test of the current group is extended; search from the top of the context stack
                # context_idx = 0
                # @context.reverse.each_with_index { |it, idx|
                    # existing = it.find_test(container_name)
                    # puts "    existing #{container_name} = #{existing.ctype.to_s} #{existing}" if existing
                    # if existing != nil
                      # context_idx = @context.size - 1 - idx
                      # break
                    # end
                # }
                # @context.push(@context.delete_at(context_idx)) if existing
              end
              if !existing then
                STDERR.puts "#{name} [ERROR]: extend '#{container_name}' does not extend a known container"
                return false
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
                if @session_container.find_group_index(container.name) != nil then
                  STDERR.puts "#{name} [WARNING]: adding #{container.ctype.to_s} '#{container.name}' which already exists"
                end
                @session_container.add_group(container)
            else
                STDERR.puts "#{name} [ERROR]: container nesting error for #{container.ctype.to_s} '#{container.name}'"
                return false
            end
          else
            parent_container = @context[-1]
            if parent_container.ctype == :test then
                STDERR.puts "#{name} [ERROR]: cannot nest container #{container.ctype.to_s} '#{container.name}' in #{parent_container.ctype}"
                return false
            end
            case container.ctype
            when :group
                if parent_container.find_group_index(container.name) != nil then
                  STDERR.puts "#{name} [WARNING]: trying to add #{container.ctype.to_s} '#{container.name}' which already exists"
                end
                parent_container.add_group(container)
            when :test
                parent_container.add_test(container)
            else
                STDERR.puts "#{name} [ERROR]: container nesting error for #{container.ctype.to_s} '#{container.name}'"
                return false
            end
          end
          return true
      end

      # Parse an attribute of the form <key>:<value>
      # Returns three variables
      def parse_vsif_attribs(str)
          if @context.size == 0 then
            container = @session_container
          else
            container = @context[-1]
          end
          match_found = false
          err = false
          match_key = @@vsif_entry_key_re.match(str)
          if match_key then
            key         = match_key[1];
            if not match_key[2] then
              STDERR.puts "#{name} [ERROR]: attribute '#{key}' for #{container.ctype.to_s} '#{container.name}' misses : (colon) separator"
              err = true
            else
              str         = match_key.post_match.strip
              match_value = @@vsif_entry_value_re.match(str)
              if match_value then
                match_found = true
                if match_value[1] then
                  value = "<text>"+match_value[2]+"</text>"
                else
                  value = match_value[2];
                end

                if value.strip.length != 0
                  container.add_attribute(key, value)
                end
                str = match_value.post_match.strip
              else
                STDERR.puts "#{name} [ERROR]: attribute '#{key}' for #{container.ctype.to_s} '#{container.name}': could not parse value #{str.red}"
                err = true
              end
            end
          end
          return match_found, str, err
      end

      # Write the content to file handle
      def write_vsif(filename)
          File.open(filename, "w") do |file|
            @session_container.write(file)
          end
          puts "#{name} [INFO]: wrote #{filename}"
      end

      # Write the content to file handle in vms_run testlist format
      def write_tl(filename)
        File.open(filename, "w") do |file|
          @session_container.write_tl(file)
        end
        puts "#{name} [INFO]: wrote #{filename}"
      end

      # Slurp the .vsif and it's includes into an array containing each line.
      # Returns empty array if there was an error.
      def pre_process_vsif(filename)
          result = [];
          begin
            IO.foreach(filename) {|line|
                line.strip!
                next if line == ""            # skip empty lines
                next if line =~ /^\s*\/\//    # skip comments
                match = @@include_re.match(line)
                if match then
                  include_file = locate_file(filename, match[1])
                  result.concat(pre_process_vsif(include_file))
                else
                  result << line.chomp
                end
            }
          rescue Exception
            STDERR.puts("#{name} [ERROR]: File I/O: #{filename}")
            return []
          end
          return result
      end

      # Try to locate an include file, with search priorites, and return the likely[1] candidate's full path:
      # 1. absolute path
      # 2. relative path to working directory
      # 3. relative path to path of includer
      # [1] does not do a final check whether the file exists which is left to the caller
      def locate_file(includer, includee)
        if (includee =~ /^#{File::SEPARATOR}/) then
          return includee
        end

        full_path = File.expand_path(includee, Dir.getwd());
        if (not File.exist?(full_path)) then
          includer_path = File.dirname(includer)
          full_path = File.expand_path(includee, includer_path)
        end
        return full_path
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
                        STDERR.puts "#{name} [ERROR]: could not extract testname from parent_run attribute (file #{filename} line #{n_line}: #{line})"
                        value = "UNKNOWN"
                      end

                      if !run_container then
                        run_container = RunContainer.new(block_val)
                      end
                      # Extract only one seed
                      if attrib == "sv_seed"
                        attrib = "seed"
                      end
                      run_container.add_attribute(attrib,  value)
                  when "session_output"
                      # check if this is the correct file-type
                      if (attrib == "session_type" && value != "single_run")
                        STDERR.puts "#{name} [ERROR]: session_type #{value} not supported (file #{filename} line #{n_line}; must be single_run.)"
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
