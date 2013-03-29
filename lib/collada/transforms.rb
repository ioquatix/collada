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

require 'matrix'

module Collada
	module Transforms
		R2D = (180.0 / Math::PI)
		D2R = (Math::PI / 180.0)
		
		# In x, y, z, w format.
		def self.rotation_matrix_to_quaternion(a)
			t = a[0, 0] + a[1, 1] + a[2, 2]
			
			if (t > 0)
				s = Math::sqrt(t + 1.0) * 2.0
				Vector[
					(a[2, 1] - a[1, 2]) / s,
					(a[0, 2] - a[2, 0]) / s,
					(a[1, 0] - a[0, 1]) / s,
					0.25 * s,
				]
			elsif a[0, 0] > a[1, 1] and a[0, 0] > a[2, 2]
				s = 2.0 * Math::sqrt(1.0 + a[0, 0] - a[1, 1] - a[2, 2])
				Vector[
					0.25 * s,
					(a[0, 1] + a[1, 0]) / s,
					(a[0, 2] + a[2, 0]) / s,
					(a[2, 1] - a[1, 2] ) / s,
				]
			elsif a[1, 1] > a[2, 2]
				s = 2.0 * Math::sqrt(1.0 + a[1, 1] - a[0, 0] - a[2, 2])
				Vector[
					(a[0, 1] + a[1, 0]) / s,
					0.25 * s,
					(a[1, 2] + a[2, 1]) / s,
					(a[0, 2] - a[2, 0]) / s,
				]
			else
				s = 2.0 * Math::sqrt(1.0 + a[2, 2] - a[0, 0] - a[1, 1])
				Vector[
					(a[0, 2] + a[2, 0]) / s,
					(a[1, 2] + a[2, 1]) / s,
					0.25 * s,
					(a[1, 0] - a[0, 1]) / s,
				]
			end
		end
		
		def self.scale(x, y, z)
			Matrix[
				[x, 0, 0, 0],
				[0, y, 0, 0],
				[0, 0, z, 0],
				[0, 0, 0, 1],
			]
		end
		
		def self.rotate(x, y, z, angle)
			c = Math::cos(angle*D2R)
			s = Math::sin(angle*D2R)
			
			Matrix[
				[x*x*(1-c) + c, x*y*(1-c) - z*s, x*z*(1-c) + y*s, 0],
				[x*y*(1-c) + z*s, y*y*(1-c) + c, y*z*(1-c) - x*s, 0],
				[x*z*(1-c) - y*s, y*z*(1-c) + x*s, z*z*(1-c) + c, 0],
				[0, 0, 0, 1],
			]
		end
		
		def self.translate(x, y, z)
			Matrix[
				[1, 0, 0, x],
				[0, 1, 0, y],
				[0, 0, 1, z],
				[0, 0, 0, 1],
			]
		end
		
		def self.matrix(*arguments)
			Matrix[*(arguments.each_slice(4).to_a)]
		end
		
		def self.for(transforms)
			product = Matrix.identity(4)
			
			transforms.each do |(name, arguments)|
				product = product * self.send(name, *arguments)
			end
			
			return product
		end
		
		def self.extract_axis(matrix)
			# Transform [x, y, z], Rotation [x, y, z, w]
			[matrix[0, 3], matrix[1, 3], matrix[2, 3], *rotation_matrix_to_quaternion(matrix)]
		end
	end
end
