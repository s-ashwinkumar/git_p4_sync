module GitP4Sync
class Sync

    attr_accessor :git_path, :p4_path, :branch, :simulate, :submit, :show, :ignore, :ignore_list, :diff_files, :timestamp, :current_branch

    def initialize
      self.git_path = "./"
      self.show = false
      self.submit = false
      self.simulate = false
      self.ignore = nil
      # always ignore .git folder because P4 doesnt need it
      self.ignore_list = [".git"]
      self.diff_files = []
      self.timestamp = Time.now.utc.to_i
    end

    def prepare_for_sync
      # Handle defaults and missing
      # handling slash in filenames
      self.git_path = add_slash(File.expand_path(git_path))
      self.p4_path = add_slash(File.expand_path(p4_path))

      # verifying if these path exist
      verify_path_exist!(git_path)
      verify_path_exist!(p4_path)

      # store current branch name to restore it after the whole process.
      Dir.chdir(git_path) do
        self.current_branch = `git rev-parse --abbrev-ref HEAD`.split("\n").first
      end
      
      # setting up git repo on a new branch with the timestamp.
      puts "\n**********************************************************************\n "
      puts "Preparing for sync.\nThis will create a branch named temp_sync_branch_<timestamp> in local from the given origin branch.\nThis branch will be deleted after the sync."
      Dir.chdir(git_path) do
        cmd = system("git fetch && git checkout -b temp_sync_branch_#{timestamp} origin/#{branch}")
        exit_with_error("Cannot checkout, verify if git_path and branch name are correct.") unless cmd
      end

      # preparing the files to be ignored.
      prepare_ignored_files
      
      # prepare diff files and reject the ones in ignored.
      self.diff_files.concat(diff_dirs(p4_path, git_path).reject{|file| is_ignored?(file.last) })
      # if no diff, there is nothing to do -- PS : I know ! its not really an error...
      if diff_files.empty?
        puts "Directories are identical. Nothing to do."
        cleanup
        exit 0
      end
      # exit if there is a file that has a status other than new, edited or deleted
      # TODO : Check if other status present and handle them
      
      exit_with_error("Unknown change type present. Task aborted !") if (diff_files.collect{|arr| arr.first} - [:new, :deleted, :modified]).any?

      
    end

    def cleanup
      Dir.chdir(git_path) do
        result = system("git checkout #{current_branch} && git branch -D temp_sync_branch_#{timestamp}")
        puts "\n**********************************************************************\n "
        puts "Could not delete the temp branch. Please delete it manually later." unless result
        puts "Sync process completed. Please follow the logs to trace any discrepancies."
        puts "\n**********************************************************************\n "
      end
    end

    def show_changes
      puts " \n**********************************************************************\n "
      puts "Change List : \n"
      diff_files.each{|ele| puts "#{ele[0].to_s.upcase} in Git: #{ele[1]}"} 
    end

    def run
      show_changes if show
      puts "\n**********************************************************************\n "
      puts "A total of #{diff_files.size} change(s) !"

      if submit || simulate
        handle_files
        git_head_commit = ""
        Dir.chdir(git_path) do
          git_head_commit = `git show -v -s --pretty=oneline`.split("\n")[0] + " at #{Time.at(timestamp)}"
        end
        puts "\n**********************************************************************\n "
        Dir.chdir(p4_path) do
          puts "Submitting changes to Perforce"
          run_cmd "p4 submit -d '#{git_head_commit.gsub("'", "''")}'", simulate
        end
      end
    end

    def prepare_ignored_files
      # if ignore files provided on commandline add them
      if ignore
        if ignore.include?(":")
          self.ignore_list.concat(ignore.split(":"))
        elsif ignore.include?(",")
          self.ignore_list.concat(ignore.split(","))
        else
          self.ignore_list << ignore
        end
      end

      # if there is a gitignore file, the files inside also have to be ignored.
      # TODO : gitignore files could be inside directories as well. Need to handle that case.
      if File.exist?(gitignore = File.join(git_path, ".gitignore"))
        self.ignore_list.concat(File.read(gitignore).split(/\n/).reject{|i| (i.size == 0) or i.strip.start_with?("#") }.map {|i| i.gsub("*",".*") } )
      end

    end

    # generic method to exit with error.
    def exit_with_error(msg="Exiting for unknown reasons.Check the history", clean = true)
      puts msg
      cleanup if clean
      exit 1
    end

    def handle_files
      diff_files.each do |d|
        action = d[0]
        file = strip_leading_slash(d[1])
        puts "#{action.to_s.upcase} in Git: #{file}" 
        Dir.chdir(p4_path) do
          case action
          when :new
            run_cmd "cp -r '#{git_path}#{file}' '#{p4_path}#{file}'", simulate
            run_cmd "#{p4_add_recursively("'#{p4_path}#{file}'")}", simulate
          when :deleted
            file_path="#{p4_path}#{file}"
            Find.find(file_path) do |f|
              puts "DELETED in Git (dir contents): #{f}" if file_path != f
              run_cmd("p4 delete '#{f}'", simulate)
            end
            FileUtils.remove_entry_secure(file_path,:force => true)
          when :modified
            run_cmd "p4 edit '#{p4_path}#{file}'", simulate
            run_cmd "cp '#{git_path}#{file}' '#{p4_path}#{file}'", simulate
          end
        end
      end
    end
    
    def run_cmd(cmd, simulate = false, puts_prefix = "  ")
      if simulate
        puts "#{puts_prefix}simulation: #{cmd}"
      else
        puts "#{puts_prefix}#{cmd}"
      end
      
      output = false
      output = system("#{cmd}") unless simulate
      exit_with_error unless output
      [output, $?]
    end
    
    def lambda_ignore(item)
      re = Regexp.compile(/#{item}/)
      lambda {|diff| diff =~ re }
    end

    def is_ignored?(file)
      ignore_list.each {|ignored|
        return true if lambda_ignore(ignored).call(file)
      }
      return false
    end
    
    def add_slash(path)
      path << '/' unless path.end_with?('/')
      path
    end
    
    def strip_leading_slash(path)
      path.sub(/^\//, "")
    end
    
    def p4_add_recursively(path)
      # This will recursively add the files when a new folder is added
      # TODO : If one of the files in the new folder is in gitignore, it will still get added. Need to handle it !
      "find #{path} -type f -print | p4 -x - add -f"
    end

    def verify_path_exist!(path)
      if !File.exist?(path) || !File.directory?(path)
        exit_with_error("#{path} must exist and be a directory.", false)
      end
    end
  end

end