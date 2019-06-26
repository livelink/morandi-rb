# Morandi

Library of simple image manipulations - replicating the behaviour of
morandi-js.

## Installation

Install `liblcms2-utils` to provide the `jpgicc` command used by `Morandi::ProfiledPixbuf`

Add this line to your application's Gemfile:

    gem 'morandi'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install morandi

## Usage

````
   Morandi.process(in_file, settings, out_file)
````
- in_file is a string
- settings is a hash
- out_file is a string

Settings Key | Values | Description
-------------|--------|---------------
brighten     | Integer -20..20 | Change image brightness
gamma        | Float  | Gamma correct image
contrast     | Integer -20..20  | Change image contrast
sharpen      | Integer -5..5  | Sharpen / Blur (negative value)
redeye       | Array[[Integer,Integer],...]  | Apply redeye correction at point
angle        | Integer 0,90,180,270  | Rotate image
crop         | Array[Integer,Integer,Integer,Integer] | Crop image
fx           | String greyscale,sepia,bluetone | Apply colour filters
border-style  | String square,retro | Set border style
background-style  | String retro,black,white | Set border colour
quality       | String '1'..'100' | Set JPG compression value, defaults to 97%

## Contributing

1. Fork it ( http://github.com/<my-github-username>/morandi/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
