class Room

	attr_accessor :name, :capacity, :computers, :seat, :seatType, :food, :roomType, :priority, :purpose

	def initializer(name, capacity, computers, seat, seatType, food, roomType, priority, purpose)
	
		@name = name
		@capacity = capacity
		@computers = computers
		@seat = seat
		@seatType = seatType
		@food = food
		@roomType = roomType
		@priority = priority
		@purpose = purpose

	end

end
		

