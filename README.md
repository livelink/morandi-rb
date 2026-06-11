# Morandi

Library of simple image manipulations - replicating the behaviour of morandi-js.

## Installation

Install `liblcms2-utils` to provide the `jpgicc` command used by `Morandi::ProfiledPixbuf`.

Add this line to your application's Gemfile:

    gem 'morandi'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install morandi

## Usage

````
   Morandi.process(source, options, target_path)
````

For the detailed documentation of options see `lib/morandi.rb`

## Contributing

1. Fork it ( http://github.com/livelink/morandi-rb/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Development

Development happens inside a docker image, with a Makefile provided as a simple CLI.

#### Build the image and run the container

```bash
make
```

Above launches `guard`, which automatically runs tests when any file changes.

#### Run the full test suite manually from the guard prompt
```bash
all
```

#### Run an individual test

Add the `focus: true` annotation to an example or describe block.

#### Open a bash shell in the container

Useful, for example, to run rubocop:

```bash
make shell
```
