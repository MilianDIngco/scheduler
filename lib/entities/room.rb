class Room

	attr_accessor :attributes, :name, :capacity, :availability

	# @param attributes [CSV::Row] Type of a hashmap { Header : Value }, contains attributes of the room
	# @param name [Integer] Room number 
	# @param capacity [Integer] Capacity of the room
	# @param availability [List[Time]] List of current existing reservations in the form
	#	 [ nil, start time, end time, ...]
	def initialize(attributes, name, capacity, availability)
		@attributes = attributes
		@name = name
		@capacity = capacity
		@availability = availability
	end

	# @param startTime [DateTime] Start time
	# @param endTime [DateTime] end time...
	# @return boolean true if its available
	def isAvailable(startTime, endTime)
		# Check if it ends before the first event
		if endTime < @availability[1]
			return true
		end

		if startTime < @availability[1] && endTime > @availability[1]
			return false
		end
		
		index = 2
		while index < @availability.length && @availability[index] < startTime
			index += 2
		end
		
		if index >= @availability.length
			return true
		end

		if startTime < @availability[index] && endTime > @availability[index]
			return false
		end	
	
		return true 

	end
	
end
		

