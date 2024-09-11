# ruby-lsp-rails-factory-bot

A ruby-lsp addon to integrate with [Factory bot](https://github.com/thoughtbot/factory_bot). Currently supports hover and completion

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add ruby-lsp-rails-factory-bot

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install ruby-lsp-rails-factory-bot

Note that this currenlty uses a fork of ruby-lsp-rails (to extend its server to be able to provide factory information).

## Usage

Hover over an attribute or factory definition

![lsp-factory-bot-hover](https://github.com/user-attachments/assets/6f570288-3cf3-4d12-acf9-71c86e834cd8)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/johansenja/ruby-lsp-factory-bot.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
