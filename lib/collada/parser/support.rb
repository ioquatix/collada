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
			
			def self.parse(doc, element)
				self.new(element.attributes['name'], element.attributes['type'])
			end
		end
		
		class Accessor
			include Enumerable
			
			def initialize(array, parameters, options = {})
				@array = array
				@parameters = parameters
				@names = parameters.collect{|parameter| parameter.name}
				
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
				values = @array[base, @parameters.size]
				
				@names.zip(values)
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
	end
end
