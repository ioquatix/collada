# Copyright, 2013, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

module Collada
	module Parser
		class Animation
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
					source_id = element.attributes['source']
					target_id = element.attributes['target']
					
					self.new(sources[source_id], target_id)
				end
			end
			
			def initialize(id, sources, samples, channels)
				@id = id
				@sources = sources
				@samples = samplers
				@channels = channels
			end
			
			attr :id
			attr :sources
			attr :samplers
			attr :channels
			
			def self.parse_arrays(doc, element)
				OrderedMap.parse(element, '//float_array | //int_array | //Name_array') do |array_element|
					case array_element.name
					when 'Name_array'
						array_element.text.strip.split(/\s+/)
					else
						array_element.text.strip.split(/\s+/).collect &:to_f
					end
				end
			end
			
			def self.parse(doc, element)
				arrays = parse_arrays(doc, element)
				
				sources = OrderedMap.parse(element, 'source') do |source_element|
					Source.parse(doc, source_element, arrays)
				end
				
				samplers = OrderedMap.parse(element, 'sampler') do |sampler_element|
					Sampler.parse(doc, sampler_element, sources)
				end
				
				channels = OrderedMap.parse(element, 'channel', 'target') do |channel_element|
					Channel.parse(doc, channel_element, sources)
				end
				
				self.new(element.attributes['id'], sources, samplers, channels)
			end
		end
	end
end
