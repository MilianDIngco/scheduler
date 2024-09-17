require 'entities/room'

class Building
	attr_accessor :rooms, :name
	
	def initialize(rooms, name)
		@rooms = rooms
		@name = name
	end

end

