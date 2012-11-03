#!/usr/bin/env ruby

# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'pathname'
require 'test/unit'
require 'stringio'

require 'collada/transforms'

class TestTransforms < Test::Unit::TestCase
	def test_scale
		m = Collada::Transforms.scale(2, 4, 6)
		v = Vector[1, 1, 1, 0]

		assert_equal Vector[2, 4, 6, 0], (m * v)
	end
	
	def test_translate
		m = Collada::Transforms.translate(2, 4, 6)
		v = Vector[1, 1, 1, 1]

		assert_equal Vector[3, 5, 7, 1], (m * v)
	end
	
	def test_rotate
		m = Collada::Transforms.rotate(1, 0, 0, 90)
		v = Vector[0, 0, 1, 0]

		assert_equal Vector[0, -1.0, 0, 0], (m * v).collect{|i| i.round(2)}
	end
end
