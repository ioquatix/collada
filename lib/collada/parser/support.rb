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

require 'rexml/document'
require 'yaml'

module Collada
	module Parser
		class UnsupportedFeature < StandardError
		end
		
		class OrderedMap
			include Enumerable
			
			def initialize(ordered, indexed)
				@ordered = ordered
				@indexed = indexed
			end
			
			attr :ordered
			attr :indexed
			
			def keys
				@indexed.keys
			end
			
			def values
				@ordered
			end
			
			def [] key
				@indexed[key]
			end
			
			def each(&block)
				@ordered.each(&block)
			end
			
			def size
				@ordered.size
			end
			
			def append(key, value)
				@indexed[key] = value
				@ordered << value
			end
			
			def self.parse(top, path, id_key = 'id')
				ordered = []
				indexed = {}
			
				top.elements.each(path) do |element|
					id = element.attributes[id_key]
					value = (yield element)

					indexed[id] = value if id
					ordered << value
				end
				
				return OrderedMap.new(ordered, indexed)
			end
		end
		
		class Attribute
			def initialize(semantic, value)
				@semantic = semantic
				@value = value
			end
			
			attr :semantic
			attr :value
			
			def [] key
				@value[key]
			end
					
			def == other
				@value == other.value
			end
					
			def inspect
				"Attribute.#{@semantic}(#{@value.inspect})"
			end
					
			def self.method_missing(method, *args)
				if args.size == 1 && Hash === args[0]
					new(method, args[0])
				else
					new(method, args)
				end
			end
					
			def flatten
				if Array === @value
					@value.collect{|attribute| attribute.flatten}
				else
					self
				end
			end
					
			def self.flatten(attributes)
				attributes.collect{|attribute| attribute.flatten}.flatten
			end
		end
		
		class Parameter
			def initialize(name, type)
				@name = name ? name.to_sym : nil
				@type = type
			end
			
			attr :name
			attr :type
			
			def size
				1
			end
			
			def read value
				value.first
			end
			
			def self.parse(doc, element)
				name = element.attributes['name']
				type = element.attributes['type']
				
				case type
				when /float(\d)x(\d)/
					MatrixParameter.new(name, type, [$1.to_i, $2.to_i])
				when /float(\d)/
					VectorParameter.new(name, type, [$1.to_i, $2.to_i])
				else
					Parameter.new(name, type)
				end
			end
		end
		
		class MatrixParameter < Parameter
			def initialize(name, type, dimensions)
				super name, type
				
				@rows = dimensions[1]
				@size = dimensions[0] * dimensions[1]
			end
			
			attr :size
			
			def read(value)
				Matrix[*(value.each_slice(@rows).to_a)]
			end
		end
		
		class VectorParameter < Parameter
			def initialize(name, type, size)
				super name, type
				
				@size = size
			end
			
			attr :size
			
			def read(value)
				Vector[*value]
			end
		end
		
		class Accessor
			include Enumerable
			
			def initialize(array, parameters, options = {})
				@array = array
				@parameters = parameters
				
				@count = @parameters.inject(0) {|sum, parameter| sum + parameter.size}
				
				@offset = (options[:offset] || 0).to_i
				@stride = (options[:stride] || parameters.size).to_i
			end
			
			attr :array
			attr :parameters
			attr :names
			
			attr :offset
			attr :stride
			
			def read index
				base = @offset + (index * @stride)
				values = @array[base, @count]
				
				Hash[@parameters.collect{|parameter| [parameter.name, parameter.read(values.shift(parameter.size))]}]
			end
			
			def [] index
				read(index).delete_if{|(name, value)| name == nil}
			end
			
			def size
				(@array.size - @offset) / @stride
			end
			
			def each
				size.times.each do |i|
					yield self[i]
				end
			end
			
			def self.parse_parameters(doc, element)
				OrderedMap.parse(element, 'param', 'name') do |param_element|
					Parameter.parse(doc, param_element)
				end
			end
			
			def self.parse(doc, element, arrays = {})
				if (array_id = element.attributes['source'])
					array_id.sub!(/^#/, '')
					
					array = arrays[array_id]
				else
					array = Mesh.parse_arrays(doc, element).first
				end
				
				raise UnsupportedFeature.new("Source array binding must be valid (id=#{array_id})") unless array
				
				parameters = parse_parameters(doc, element)
				
				options = {
					:offset => element.attributes['offset'],
					:stride => element.attributes['stride'],
				}
				
				self.new(array, parameters, options)
			end
		end
		
		# A source that reads directly from a data array:
		class Source
			def initialize(id, accessor)
				@id = id
				@accessor = accessor
			end
			
			attr :id
			attr :accessor
			
			def self.parse(doc, element, arrays = {})
				accessor = Accessor.parse(doc, element.elements['technique_common/accessor'], arrays)
				
				self.new(element.attributes['id'], accessor)
			end
			
			def [] index
				Hash[@accessor[index]]
			end
		end
		
		class Input
			# `Vertices` or `Source` are both okay for source.
			def initialize(semantic, source, offset = 0)
				@semantic = semantic
				@source = source
				@offset = offset
			end
			
			attr :semantic
			attr :source
			attr :offset
			
			def [] index
				Attribute.new(@semantic, @source[index])
			end
			
			def self.parse(doc, element, sources = {})
				semantic = element.attributes['semantic']
				
				if (source_id = element.attributes['source'])
					source_id.sub!(/^#/, '')
					source = sources[source_id]
				end
				
				raise UnsupportedFeature.new("Can't instantiate input with nil source (#{source_id})!") unless source
				
				offset = element.attributes['offset'] || 0
				
				self.new(semantic.downcase.to_sym, source, offset.to_i)
			end
		end
		
		class Sampler
			def initialize(id, inputs)
				@id = id
				@inputs = inputs
			end
				
			attr :id
			attr :inputs
				
			# Vertices by index, same interface as Input.
			def [] index
				@inputs.collect do |input|
					input[index]
				end
			end
				
			def self.parse_inputs(doc, element, sources = {})
				OrderedMap.parse(element, 'input') do |input_element|
					Input.parse(doc, input_element, sources)
				end
			end
				
			def self.parse(doc, element, sources = {})
				inputs = parse_inputs(doc, element, sources)
						
				self.new(element.attributes['id'], inputs)
			end
		end
			
		class Channel
			def initialize(source, target)
				@source = source
				@target = target
			end
				
			attr :source
			attr :target
				
			def self.parse(doc, element, sources = {})
				source_id = element.attributes['source'].sub(/^\#/, '')
				target_id = element.attributes['target']
				
				self.new(sources[source_id], target_id)
			end
		end
	end
end
