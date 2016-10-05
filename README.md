# GitP4Sync

For people who have their code repositories in Perforce and are trying to transition to git, this tool could aid your transition. This gel, takes in two folders, one git local repo and one perforce local folder from your system, looks for changes between the folders and copies all the changes in git repo to the perforce folder and then submits to perforce central repo.

This does not use the git-p4 python tool and is just based on command line git, p4 and simple file comparisons.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'git_p4_sync'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install git_p4_sync

## Command Line Usage

git-p4-sync [options]

    -b, --branch [STRING]            Git origin branch that needs to be synced.
    -g, --git [STRING]               Path to Git repository. Current directory by default.
    -p, --p4 [STRING]                Path to Perforce workspace directory
    -d, --diff                       Show the diff between the Git and Perforce repo
    -S, --submit                     Submit to Perforce after processing
    -t, --test                       Simulates a syncronisation without actually synchrnozing the repos.
    -i, --ignore [STRING]            Items to ignore. This is a colon ':' or comma ',' delimited list


  - The --test switch is useful to test git-p4-sync without actually doing anything to your files.
  - The --diff switch can be used to just see the diff before submitting.

## Dependencies

  - Git command line executable.
  - Perforce command line executable.
  - diff_dirs gem for checking difference between directories.
  
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/git_p4_sync.

## Additional Information

This gem is based out of Carl Mercier's https://github.com/cmer/git-p4-sync gem. It has been modified according to certain needs and is open for further development.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).