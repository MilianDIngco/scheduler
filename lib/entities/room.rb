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

	def addReservation(startTime, endTime) 
	# ========== ADDING AND SORTING DATES =================
			# if room reservation array has no dates, just append it
			if @availability.length <= 1
				@availability.push(startTime)
				@availability.push(endTime)
			else
				# Otherwise, perfom a linear search to find where the date should be inserted
				
				# Check if end time is less than the first start date
				if @availability[1] < endTime
					@availability.insert(1, startTime)
					@availability.insert(2, endTime)
				else
					# Loop over the lists end times
					(2..(@availability.length - 1)).step(2) do |i|
						# Check if the start time is greater than the current end time and less than the next start time
						if (i == @availability.length - 1) && (@availability[i] < startTime)
							@availability.push(startTime)
							@availability.push(endTime)
							break
						end
				
						# If starts later than current end and ends earlier than next start, add start and end	
						if (@availability[i] < start) && (@availability[i + 1] > endTime)
							@availability.insert(i + 1, startTime)
							@availability.insert(i + 2, endTime)
							break
						end
					end
				end	
	
			end	# END OF SORTING DATES	

	end
	
end
		

