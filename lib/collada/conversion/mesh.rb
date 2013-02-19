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

require 'collada/parser/support'
require 'collada/transforms'

module Collada
	module Conversion
		class VertexFormat
			def initialize(format)
				@format = format
			end
			
			def extract(attributes)
				@format.collect do |name, components|
					value = attributes[name]
				
					raise ArgumentError.new("Invalid vertex format, undefined property #{name} for #{attributes.inspect}!") unless value
				
					components.collect{|key| value[key]}
				end.flatten
			end
		
			def self.[] (format)
				self.new(format)
			end
		end
		
		class WeightFormat
			def initialize(count)
				@count = count
			end
			
			def extract(vertex_weights)
				# Ensure that we have the correct number:
				vertex_weights = @count.times.collect do |offset|
					vertex_weights[offset] || [0, 0.0]
				end
				
				# Go from [[bone1, weight1], [bone2, weight2]] => [bone1, bone2, weight1, weight2]
				return vertex_weights.collect{|(bone,_)| bone}, vertex_weights.collect{|(_,weight)| weight}
			end
			
			def self.[] (count)
				self.new(count)
			end
		end
		
		class Vertex
			# The format provided here is used purely to calculate unique vertices.
			def initialize(attributes, format)
				@attributes = Parser::Attribute.to_hash(attributes)
				@format = format
			end
			
			attr :attributes
			
			def to_a
				@format.extract(@attributes)
			end
			
			def <=>(other)
				to_a <=> other.to_a
			end
			
			def index
				@attributes[:vertex][:index]
			end
			
			def hash
				to_a.hash
			end
		end
		
		class Mesh
			def initialize()
				@indices = []
				
				# vertex -> index
				@vertices = {}
				
				# index -> vertex
				@indexed = []
			end
			
			attr :indices
			attr :vertices
			attr :indexed
			
			def size
				@indexed.size
			end
			
			def << vertex
				if index = vertices[vertex]
					@indices << index
				else
					@vertices[vertex] = self.size
					@indices << self.size
					
					@indexed << vertex
				end
			end
		end
	end
end
