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

require 'collada/parser/visual_scene'
require 'collada/parser/geometry'
require 'collada/parser/animation'
require 'collada/parser/controller'

module Collada
	module Parser
		class Library
			SECTIONS = {
				:visual_scenes => ['COLLADA/library_visual_scenes/visual_scene', VisualScene],
				:geometries => ['COLLADA/library_geometries/geometry', Geometry],
				:animations => ['COLLADA/library_animations/animation', Animation],
				:controllers => ['COLLADA/library_controllers/controller', Controller],
			}
			
			def initialize(doc, sections = {})
				@doc = doc
				@sections = sections
			end
			
			def [] key
				@sections.fetch(key) do
					path, klass = SECTIONS[key]
					
					raise ArgumentError.new("Invalid section name #{key}!") unless klass
					
					@sections[key] = OrderedMap.parse(@doc, path) do |element|
						klass.parse(@doc, element)
					end
				end
			end
			
			def self.parse(doc)
				return Library.new(doc)
			end
		end
	end
end
