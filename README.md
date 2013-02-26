# Collada

This library provides support for loading and processing data from Collada Digital Asset Exchange files. These files are typically used for sharing geometry and scenes.

[![Build Status](https://secure.travis-ci.org/ioquatix/collada.png)](http://travis-ci.org/ioquatix/collada)

## Installation

Add this line to your application's Gemfile:

    gem 'collada'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install collada

## Usage

This library is designed to be used in scripts which extract data from collada files and output in some other format. As such, you'd typically create your own conversion script which takes the collada file as an argument. Then, use this library to extract relevant geometry and write it out.

To assist with some basic tasks, the `collada-convert` executable provides a number of basic conversion functions. At present, `collada-convert` is primarily designed to produce [tagged format text][1].

[1]: https://github.com/ioquatix/tagged-format

### Example Conversion

Several example `.dae` files are included and used as part of the unit tests. The `collada-convert` executable can dump the geometries contained within easily:

	$ ./bin/collada-convert tagged-format -v p3n3 ./test/sample.dae 
	Cube-mesh: mesh triangles
		indices: array index16
			    0    1    2    3    4    5    6    7    8    9   10   11
			   12   13   14   15   16   17   18   19   20   21   22   23
		end
		vertices: array vertex-p3n3
			         1.0          1.0         -1.0          0.0          0.0         -1.0
			         1.0         -1.0         -1.0          0.0          0.0         -1.0
			        -1.0         -1.0         -1.0          0.0          0.0         -1.0
			        -1.0          1.0         -1.0          0.0          0.0         -1.0
			         1.0          1.0          1.0          0.0          0.0          1.0
			        -1.0          1.0          1.0          0.0          0.0          1.0
			        -1.0         -1.0          1.0          0.0          0.0          1.0
			         1.0         -1.0          1.0          0.0          0.0          1.0
			         1.0          1.0         -1.0          1.0         -0.0          0.0
			         1.0          1.0          1.0          1.0         -0.0          0.0
			         1.0         -1.0          1.0          1.0         -0.0          0.0
			         1.0         -1.0         -1.0          1.0         -0.0          0.0
			         1.0         -1.0         -1.0         -0.0         -1.0          0.0
			         1.0         -1.0          1.0         -0.0         -1.0          0.0
			        -1.0         -1.0          1.0         -0.0         -1.0          0.0
			        -1.0         -1.0         -1.0         -0.0         -1.0          0.0
			        -1.0         -1.0         -1.0         -1.0          0.0          0.0
			        -1.0         -1.0          1.0         -1.0          0.0          0.0
			        -1.0          1.0          1.0         -1.0          0.0          0.0
			        -1.0          1.0         -1.0         -1.0          0.0          0.0
			         1.0          1.0          1.0          0.0          1.0          0.0
			         1.0          1.0         -1.0          0.0          1.0          0.0
			        -1.0          1.0         -1.0          0.0          1.0          0.0
			        -1.0          1.0          1.0          0.0          1.0          0.0
		end
	end
	top: offset-table
		Cube: $Cube-mesh
	end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Desired Features

* Converter: Support .obj files.
* Support more of the collada standard.

## License

Released under the MIT license.

Copyright, 2012, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.