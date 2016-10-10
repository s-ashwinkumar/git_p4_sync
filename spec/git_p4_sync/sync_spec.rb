require "spec_helper"

describe GitP4Sync::Sync do
  before(:all) { @sync = GitP4Sync::Sync.new }
  
  describe "constructor test" do
    it "tests default values" do
      expect(@sync.simulate).to be false
      expect(@sync.show).to be false
      expect(@sync.submit).to be false
      expect(@sync.ignore).to be nil
      expect(@sync.git_path).to eq("./")
    end
  end

  describe "test for path verification method" do
    
    it "takes a filename" do
      expect(@sync).to receive(:exit_with_error).with("#{File.expand_path('./sync_spec.rb')} must exist and be a directory.",false)
      @sync.verify_path_exist!(File.expand_path("./sync_spec.rb"))
    end

    it "takes non existing path" do
      expect(@sync).to receive(:exit_with_error).with("#{File.expand_path('./random')} must exist and be a directory.",false)
      @sync.verify_path_exist!(File.expand_path("./random"))
    end

    it "takes working path" do
      expect(@sync).not_to receive(:exit_with_error)
      expect(@sync.verify_path_exist!(File.expand_path("./"))).to be nil
    end
  end

  describe "test method running commands" do
    it "runs simuation" do
      expect(STDOUT).to receive(:puts).with("  simulation: pwd")
      expect(@sync).to receive(:exit_with_error)
      expect(@sync.run_cmd("pwd",true).first).to be false
    end

    it "runs without simuation" do
      expect(STDOUT).to receive(:puts).with("  pwd")
      expect(@sync).to receive(:system).and_return(true)
      expect(@sync.run_cmd("pwd").first).to be true
    end
  end

  describe "add slash method test" do
    it "tests for addition of slash" do
      expect(@sync.add_slash("testing")).to eq("testing/")
    end

    it "tests for existing slash" do
      expect(@sync.add_slash("testing/")).to eq("testing/")
    end
  end

  describe "strip leading slash" do
    it "removes leading slash" do
      expect(@sync.strip_leading_slash("/testing/")).to eq("testing/")
    end
  end

  describe "tests for is_ignored?" do
    after(:each) { @sync.ignore_list = [] }
    it "tests with file not in ignore list" do
      expect(@sync.is_ignored?("cannot_exist.what")).to be false
    end

    it "tests with file in ignored list" do
      @sync.ignore_list << "test_file.test"
      expect(@sync.is_ignored?("test_file.test")).to be true
    end
  end

  describe "show changes" do
    after(:each) { @sync.diff_files = [] }
    it "has no changes" do
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      expect(STDOUT).to receive(:puts).with("Change List : \n")
      @sync.show_changes
    end

    it "has changes to show" do
      @sync.diff_files << ["test","tset"]
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      expect(STDOUT).to receive(:puts).with("Change List : \n")
      expect(STDOUT).to receive(:puts).with("TEST in Git: tset")
      @sync.show_changes
    end
  end

  describe "clean up method" do
    it "checks for cleanup commands with failure" do
      expect(@sync).to receive(:system).with("git checkout #{@sync.current_branch} && git branch -D temp_sync_branch_#{@sync.timestamp}").and_return(false)
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      expect(STDOUT).to receive(:puts).with("Could not delete the temp branch. Please delete it manually later.")
      expect(STDOUT).to receive(:puts).with("Sync process completed. Please follow the logs to trace any discrepancies.")
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      @sync.cleanup
    end

    it "checks for cleanup commands with success" do
      expect(@sync).to receive(:system).with("git checkout #{@sync.current_branch} && git branch -D temp_sync_branch_#{@sync.timestamp}").and_return(true)
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      expect(STDOUT).to receive(:puts).with("Sync process completed. Please follow the logs to trace any discrepancies.")
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      @sync.cleanup
    end
  end

  describe "prep_ignored_files method" do
    before(:each) do
      expect(File).to receive(:exist?).and_return(true)
      expect(File).to receive(:read).and_return("test1\ntest2")
      @sync.ignore_list = [".git"]
    end

    after(:each) do
      @sync.ignore = nil
      @sync.ignore_list = [".git"]
    end

    it "runs without ignore parameter" do
      @sync.prepare_ignored_files
      expect(@sync.ignore_list.size).to eq(3)
      expect(@sync.ignore_list.include?("test1")).to be true
      expect(@sync.ignore_list.include?("test2")).to be true
      expect(@sync.ignore_list.include?(".git")).to be true
    end

    it "runs with ignore parameter having one file" do
      @sync.ignore = "test.test"
      @sync.prepare_ignored_files
      expect(@sync.ignore_list.size).to eq(4)
      expect(@sync.ignore_list.include?("test1")).to be true
      expect(@sync.ignore_list.include?("test1")).to be true
      expect(@sync.ignore_list.include?(".git")).to be true
      expect(@sync.ignore_list.include?("test.test")).to be true
    end

    it "runs with ignore parameter having comma separated files" do
      @sync.ignore = "test.test,test1.test"
      @sync.prepare_ignored_files
      expect(@sync.ignore_list.size).to eq(5)
      expect(@sync.ignore_list.include?("test1")).to be true
      expect(@sync.ignore_list.include?("test1")).to be true
      expect(@sync.ignore_list.include?(".git")).to be true
      expect(@sync.ignore_list.include?("test.test")).to be true
      expect(@sync.ignore_list.include?("test1.test")).to be true
    end

    it "runs with ignore parameter having colon separated files" do
      @sync.ignore = "test.test:test1.test"
      @sync.prepare_ignored_files
      expect(@sync.ignore_list.size).to eq(5)
      expect(@sync.ignore_list.include?("test1")).to be true
      expect(@sync.ignore_list.include?("test1")).to be true
      expect(@sync.ignore_list.include?(".git")).to be true
      expect(@sync.ignore_list.include?("test.test")).to be true
      expect(@sync.ignore_list.include?("test1.test")).to be true
    end
  end

  describe "run method" do
    after(:each) do
      @sync.show = false
      @sync.simulate = false
      @sync.submit = false
      @sync.diff_files = []
      @sync.p4_path = nil
    end

    it "is runs with no simulate submit show and diffs" do
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      expect(STDOUT).to receive(:puts).with("A total of 0 change(s) !")
      @sync.run
    end

    it "is runs with no simulate submit show and some diff" do
      @sync.diff_files << "testing"
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      expect(STDOUT).to receive(:puts).with("A total of 1 change(s) !")
      @sync.run
    end

    it "is runs with no simulate submit and with show and some diff" do
      @sync.diff_files << "testing"
      @sync.show = true
      expect(@sync).to receive(:show_changes)
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      expect(STDOUT).to receive(:puts).with("A total of 1 change(s) !")
      @sync.run
    end

    it "is runs with no submit and with show, simulate and some diff" do
      @sync.diff_files << "testing"
      @sync.show = true
      @sync.p4_path = "./"
      @sync.simulate = true
      expect(@sync).to receive(:show_changes)
      expect(@sync).to receive(:handle_files)
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      expect(STDOUT).to receive(:puts).with("A total of 1 change(s) !")
      expect(@sync).to receive(:`).with("git show -v -s --pretty=format:\"%s : #{Time.at(@sync.timestamp)} : SHA:%H\"").and_return("1234 test_commit")
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      expect(STDOUT).to receive(:puts).with("Submitting changes to Perforce")
      expect(@sync).to receive(:run_cmd).with("p4 submit -d '1234 test_commit'",true)
      @sync.run
    end

    it "is runs with no simulate and with show, submit and some diff" do
      @sync.diff_files << "testing"
      @sync.show = true
      @sync.p4_path = "./"
      @sync.submit = true
      expect(@sync).to receive(:show_changes)
      expect(@sync).to receive(:handle_files)
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      expect(STDOUT).to receive(:puts).with("A total of 1 change(s) !")
      expect(@sync).to receive(:`).with("git show -v -s --pretty=format:\"%s : #{Time.at(@sync.timestamp)} : SHA:%H\"").and_return("1234 test_commit")
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      expect(STDOUT).to receive(:puts).with("Submitting changes to Perforce")
      expect(@sync).to receive(:run_cmd).with("p4 submit -d '1234 test_commit'",false)
      @sync.run
    end
  end

  describe "prepare for sync test" do
    before(:each) do
      expect(File).to receive(:expand_path).and_return("./", "./")
      expect(@sync).to receive(:add_slash).and_return("./", "./")
      expect(@sync).to receive(:`).with("git rev-parse --abbrev-ref HEAD").and_return("test_branch")
      expect(@sync).to receive(:prepare_ignored_files).once
      expect(@sync).to receive(:verify_path_exist!).exactly(2).times
      expect(STDOUT).to receive(:puts).with(/\*\*\*\*/)
      expect(STDOUT).to receive(:puts).with("Preparing for sync.\nThis will create a branch named temp_sync_branch_<timestamp> in local from the given origin branch.\nThis branch will be deleted after the sync.")
    end

    after(:each) do
      @sync.p4_path = nil
      @sync.current_branch = nil
      @sync.diff_files = []
    end

    # TODO - FIX THIS TEST !!
    # it "tests with no diff" do
    #   expect(@sync).to receive(:diff_dirs).with("./","./").and_return([])
    #   expect(STDOUT).to receive(:puts).with("Directories are identical. Nothing to do.")
    #   expect(@sync).to receive(:exit).with(0)
    #   @sync.prepare_for_sync
    # end 
    
    it "tests with unknown change type" do
      expect(@sync).to receive(:diff_dirs).with("./","./").and_return([[:test,"test"]])
      expect(@sync).to receive(:exit_with_error).with("Unknown change type present. Task aborted !")
      expect(@sync).to receive(:system).and_return(true)
      @sync.prepare_for_sync
    end

    it "tests with git checkout issues" do
      expect(@sync).to receive(:diff_dirs).with("./","./").and_return([[:new,"test"]])
      expect(@sync).to receive(:system).and_return(false)
      expect(@sync).to receive(:exit_with_error).with("Cannot checkout, verify if git_path and branch name are correct.")
      @sync.prepare_for_sync
    end

    it "tests with happy path" do
      expect(@sync).to receive(:diff_dirs).with("./","./").and_return([[:new,"test"]])
      expect(@sync).to receive(:system).and_return(true)
      expect(@sync).not_to receive(:exit_with_error)
      @sync.prepare_for_sync
    end
  end

  describe "handle files" do
    after(:each) do
      @sync.diff_files = []
    end
    it "runs with no diff" do
      expect(@sync).not_to receive(:run_cmd)
      expect(@sync.handle_files).to be_empty
    end

    it "runs with new file in diff" do
      @sync.p4_path = "./"
      @sync.diff_files = [[:new, "test.rb"]]
      expect(@sync).to receive(:strip_leading_slash).with("test.rb").and_return("test.rb")
      expect(STDOUT).to receive(:puts).with("NEW in Git: test.rb")
      expect(@sync).to receive(:run_cmd).with("cp -r './test.rb' './test.rb'",false)
      expect(@sync).to receive(:run_cmd).with("#{@sync.p4_add_recursively("'./test.rb'")}",false)
      @sync.handle_files
    end

    it "runs with modified file in diff" do
      @sync.p4_path = "./"
      @sync.diff_files = [[:modified, "test.rb"]]
      expect(@sync).to receive(:strip_leading_slash).with("test.rb").and_return("test.rb")
      expect(STDOUT).to receive(:puts).with("MODIFIED in Git: test.rb")
      expect(@sync).to receive(:run_cmd).with("cp './test.rb' './test.rb'",false)
      expect(@sync).to receive(:run_cmd).with("p4 edit './test.rb'",false)
      @sync.handle_files
    end

    it "runs with deleted file in diff" do
      @sync.p4_path = "./"
      @sync.diff_files = [[:deleted, "test.rb"]]
      expect(@sync).to receive(:strip_leading_slash).with("test.rb").and_return("test.rb")
      expect(STDOUT).to receive(:puts).with("DELETED in Git: test.rb")
      expect(Find).to receive(:find).and_yield("test.rb")
      expect(STDOUT).to receive(:puts).with("DELETED in Git (dir contents): test.rb")
      expect(@sync).to receive(:run_cmd).with("p4 delete 'test.rb'",false)
      expect(FileUtils).to receive(:remove_entry_secure).with("./test.rb",{:force=>true})
      @sync.handle_files
    end
  end

end