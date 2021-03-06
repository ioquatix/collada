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
			
			def self.parse(doc, element)
				arrays = Source.parse_arrays(doc, element)
				
				sources = OrderedMap.parse(element, 'source') do |source_element|
					Source.parse(doc, source_element, arrays)
				end
				
				samplers = OrderedMap.parse(element, 'sampler') do |sampler_element|
					Sampler.parse(doc, sampler_element, sources)
				end
				
				channels = OrderedMap.parse(element, 'channel', 'target') do |channel_element|
					Channel.parse(doc, channel_element, samplers)
				end
				
				self.new(element.attributes['id'], sources, samplers, channels)
			end
		end
	end
end
