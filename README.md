# Morandi

Library of simple image manipulations - replicating the behaviour of morandi-js.

## Installation

Install `liblcms2-utils` to provide the `jpgicc` command used by `Morandi::ProfiledPixbuf`. Also ensure that your host system has `imagemagick` installed, which is required by the `colorscore` gem.

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

Since this gem depends on the `liblcms2-utils` library, which can be awkward to install on some operating systems, we also provide a development docker image. A Makefile is also provided as a simple CLI. To build the image and run the container, type `make` from the project root. The container itself runs `guard` as its main process. Running the container via `make` will drop you into the guard prompt, which will run the test suite whenever any of the source code or tests are changed. The tests can be kicked-off manually via the `all` command at the guard prompt. Individual test can be run using the `focus: true` annotation on an example or describe block. If you need to access a bash shell in the container (for example, to run rubocop), use the command `make shell`.
