require 'entities/room'

class Building
	attr_accessor :rooms, :name

	# @param rooms [List[Room]] List of rooms in the building
	# @param name [String] Name of the building	
	def initialize(rooms, name)
		@rooms = rooms
		@name = name
	end

	# @param roomNo [Integer] gets room with this number
	def getRoom(roomNo) 
		for room in rooms
			if room.name == roomNo
				return room	
			end
		end

		return nil
	end

end

