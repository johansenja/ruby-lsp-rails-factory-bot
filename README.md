# ruby-lsp-rails-factory-bot

A ruby-lsp addon to integrate with [Factory bot](https://github.com/thoughtbot/factory_bot). Currently supports hover and completion

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add ruby-lsp-rails-factory-bot

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install ruby-lsp-rails-factory-bot

## Usage

Hover over a factory name, trait, or attribute

![lsp-factory-bot-hover-all](https://github.com/user-attachments/assets/16e463cb-dddf-4d12-8a85-3357d47df6ff)

Receive completion suggestions as you type

![lsp-factory-bot-completion](https://github.com/user-attachments/assets/4255a86a-8f36-4de2-8d10-8cb5a3f49e50)

Click through to definitions

![lsp-factory-bot-definition-trait](https://github.com/user-attachments/assets/92a4b224-b587-442d-9463-50d526872039)

![lsp-factory-bot-definition-attribute](https://github.com/user-attachments/assets/d8650678-6759-42c8-b015-0fdbd4045494)


### Supports

|         | Hover           | Completion  | Go to definition |
| ------------- |-------------| -----| ----|
| Attribute | ✅      |  ✅ | ✅ |
| Trait      | ✅      |  ⭕️ | ✅ 
| Factory name      | ✅ | ⭕️ | ❌ ||

Notes:

- The extension has "understanding" of factory/trait completion items, but due to limitations on when ruby-lsp displays the completion suggestions, they aren't visible for Symbols (eg. factory/trait names) :/ though they happen to be visible for symbols in Hash/Kw notation (ie with `:` after - `key: ...`)
- Factory definition is not supported at the moment (limitation of current implementation), but might come in due course


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/johansenja/ruby-lsp-factory-bot.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
