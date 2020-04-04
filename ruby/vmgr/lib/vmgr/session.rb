# Ruby Vmgr (Vmanager) library
#
# Creation Date: AUG/2019
# Author: <thorste.dworzak@verilab.com

module Vmgr

   #
   # Class collecting all test or run-containers of a vmanager session
   # runs are extracted from .vsof files, tests (in groups) from .vsif files
   #
   class Session
      attr_reader   :name
      attr_reader   :kind
      attr_accessor :runs
      attr_accessor :groups

      # Setter for container attributes
      def method_missing(name, *args, &block)
         if name =~ /^(\w+)=$/ then
            return self.instance_variable_set("@#{$1}", *args)
         #elsif name =~ /^(\w+)$/ then
         #   return self.instance_variable_get("@#{$1}", *args)
         end
         super
      end

      # Initialize
      def initialize(name_="new_session", kind_=:none)
         @name                 = name_
         @kind                 = kind_

         @@block_re            = Regexp.new(/(\w+)\s+([\w"]+)\s+\{/)
         @@vsof_entry_re       = Regexp.new(/(\w+)\s+:\s+(<text>\s*)*([^;<]+)(<\/text>)*\s*;/)
         # The vsif regexp require preprocessing to remove leading whitespace
         @@vsif_container_re   = Regexp.new(/^(session|group|test|extend)\s+(\w+)\s*/)
         @@vsif_entry_re       = Regexp.new(/^(\w+)\s*:\s*(<text>|")*([^;"<]+)(<\/text>|")*\s*;/)
         @@include_re          = Regexp.new('^#include\s+\"([\w+\.]+)\"')
         # TODO @@entry_old_re bla: "value";

         @runs                 = [] # only populated for vsofs
         @groups               = [] # only populated for vsifs
      end


      # Write content to file handle
      def write(handle, indent=0)
         handle.puts "// Sanity regression; automatically generated by script #{ME} from #{handle.path}"
         handle.puts "session #{@name} {"
         self.instance_variables.each {|member|
            case member
            when :@name, :@kind, :@runs, :@groups   # skip these attributes
               next
            else
               if defined?(v = instance_variable_get(member)) then
                  handle.puts "   " * (indent + 1) + "#{member}".sub(/^@/, '') + ":  #{v};"
               end
            end

            # handle.puts "#{member} => #{instance_variable_get(member)}"
         }
         handle.puts "};"
         groups.each {|it|
            it.write(handle, indent)
         }
      end

      # Read all unique .vsof files of a session adn populate the runs member
      def read_vsofs(filenames)
         @kind = :vsof
         # Iterate over all .vsof files of a session and extract a run-container for each
         @runs = []
         filenames.each {|filename|
            run_container = get_single_run_container(filename)
            if run_container then
               # puts run_container.inspect
               @runs.push(run_container)
            else
              STDERR.puts "#{ME} [ERROR]: no single-run container found in vsof file #{filename}"
            end
         }
      end

      # Read a .vsif file and populate the groups member
      def read_vsif(filename)
         group_container = nil
         test_container  = nil
         existing        = nil
         container_type  = ""
         container_name  = ""
         n_line          = -1;
         context         = [:none]
         lines           = [];
         lines.concat(pre_process_vsif(filename));
         brace_open      = false;

         # Iterate over all lines and parse the {... } container entries
         while line = lines.next
            line.chomp
            n_line += 1
            begin
               # puts "#{n_line}:#{line}\n"
               match_found = false
               match = @@vsif_container_re.match(line);
               if match then
                  match_found = true
                  # parse .vsif for container and push respective  context to stack
                  container_type = match[1];
                  container_name = match[2];

                  case container_type
                  when "session"
                     context.push(:session)
                     @name = container_name
                  when "group"
                     puts "context group"
                     context.push(:group)
                     group_container = GroupContainer.new(container_name, [], [])
                  when "test"
                     context.push(:test)
                     test_container = TestContainer.new(container_name)
                  when "extend"
                     existing = @groups.rindex{|item| item.name == container_name}
                     if existing then
                        context.push(:group)
                        group_container = existing
                     else
                        existing = @tests.rindex{|item| item.test_name == container_name}
                        if existing then
                           context.push(:test)
                           test_container = existing
                        end
                     end
                     if !existing then
                        STDERR.puts "#{ME} [ERROR]: extend #{container_name} does not extend a known container (line #{n_line}: #{line})"
                        return 0
                     end
                  end
                  line = match.post_match.strip
                  brace_open = false;
               elsif line =~ /\{\s*/ then
                  match_found = true
                  brace_open = true
                  line = $'.strip
                  puts "bo #{n_line}:#{line}\n"
               end
BAUSTELLE need to match all params before closing brace; put code below in its own function
make lines + current_line instance instance_variables

               if brace_open and (context[-1] != :none) then
                  # Pick up attributes
                  # puts "pa #{n_line}:#{line}\n"
                  case context[-1]
                     when :session
                        match_found, line = parse_vsif_attribs(self, line)
                     when :group
                        puts "attributes group"
                        match_found, line = parse_vsif_attribs(group_container, line)
                     when :test
                        match_found, line = parse_vsif_attribs(test_container, line)
                  end
               end
               next if match_found

               if line =~ /\}\s*;\s*/ then
                  # pop context and add container object to enclosing container
                  match_found = true
                  brace_open  = false
                  pop_context = context.pop
                  puts "bc #{n_line}:#{line} context #{pop_context.to_s}\n"
                  if !pop_context then
                     STDERR.puts "#{ME} [ERROR]: parsing error, found closing brace with no matching opening brace (line #{n_line}: #{line})"
                     return 0
                  end
                  case pop_context
                  when :group
                     if !existing then
                        @groups.push(group_container)
                        group_container = nil
                     end
                  when :test
                     if !existing then
                        group_container.tests.push(test_container)
                        test_container = nil
                     end
                  end
                  existing = nil
                  line = $'.strip
               end
            end while line.length > 0 && match_found
         }
         return 1
      end

      def parse_vsif_attribs(container, str)
         match_found = false
         match = @@vsif_entry_re.match(str)
         if match then
            match_found = true
            key   = match[1];
            if match[2] then
               value = "<text>"+match[3]+"</text>"
            else
               value = match[3];
            end
            puts ">>> #{key}=#{value}"
            container.send("#{key}=", value)
            str = match.post_match
         end
         return match_found, str
      end

      def write_vsif(filename)
         File.open(filename, "w") do |file|
            self.write(file)
         end
      end

      # Slurp the .vsif and it's includes into an array containing each line
      def pre_process_vsif(filename)
         result = [];
         @kind = :vsif
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
         n_line        = -1;
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
               match  = @@entry_re.match(line)
               if (match != nil) and (match[1] != nil) then
                  attrib = match[1]
                  value  = match[3]
                  case block_name
                  when "run"
                     # extract the real testname that is hidden in the parent_run attribute
                     next if (attrib == "test_name")
                     if (attrib == "parent_run")
                        attrib = "test_name"
                        if /(\w+)@\d+/.match(value)
                           value = $+
                        else
                           STDERR.puts "#{ME} [ERROR]: could not extract testname from parent_run attribute (file #{filename} line #{n_line}: #{line})"
                           value = "UNKNOWN"
                        end
                     end
                     if !run_container then
                        run_container = RunContainer.new()
                     end
                     # Extract only one seed
                     if attrib == "sv_seed"
                        attrib = "seed"
                     end
                     # some Ruby magic: send all attributes to the RunContainer object by invoking an accessor method
                     # which is ignored if the object does not care about
                     run_container.send("#{attrib}=", value)
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
