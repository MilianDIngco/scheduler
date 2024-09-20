require 'entities/building'
require 'entities/room'
require 'entities/schedule'
require 'date'
require 'time'
require 'set'

=begin
Assumes room has attribute capacity

In writeCSV
Assumes 
=end

class GenerateSchedule

	# @return Returns a Schedule

	def self.getValidSchedule(buildings, name, startTime, endTime, nAttendees, marginHours, reqs, min_capacity, min_rooms, req_reqs)
		
		# For each building, gets a list of rooms that fulfils each requirement
		building_potential_rooms = checkRequirements(reqs, buildings, nAttendees, startTime, endTime, marginHours)

		options = []
		buildings.each do |building|
			failed = false
			fulfill = [] # List of lists that fulfill their associated requirement
			# Do FCFS algorithm to get rooms
			seen = Set.new # Set of rooms already used

			# List of lists associated with requirements, potential_rooms[n][0] = purpose
			potential_rooms = building_potential_rooms[building.name]
			# Loop over each requirement list
			potential_rooms.each_with_index do |req_rooms, index|
				# puts "Requirement: #{req_rooms[0]}"
				req_fulfilled = [req_rooms[0]]

				curr_capacity = 0
				n_rooms = 0
				curr_min_capacity = min_capacity[index] * nAttendees
				curr_min_rooms = min_rooms[index] # DONT FORGET IF ITS NEGATIVE, THATS THE MAX
				max = (curr_min_rooms < 0) ? -1 * curr_min_rooms : Float::INFINITY
				for room in req_rooms[1..-1]
					# puts "Checking room #{room.name} w/ capacity #{room.capacity}"
					# Checks for max limit on rooms
					if n_rooms >= max
						# puts "hit max ^"
						break
					end

					# Check if target capacity is hit, break only if capacity is hit AND min rooms 
					if curr_capacity >= curr_min_capacity && n_rooms >= curr_min_rooms
						# puts "hit capacity ^"
						break
					end

					# Skip over rooms that have been seen
					if seen.include?(room.name)
						# puts "seen it ^"
						next
					end
					
					# Keeps track of the current capacity and number of rooms added
					# puts "ADDED room #{room.name} w/ capacity #{room.capacity}"
					curr_capacity += room.capacity
					n_rooms += 1
					req_fulfilled.push(room)

					# Add room to seen if it's a required set
					if req_reqs[index]
						seen.add(room.name)
					end
				end
				# Will only fail if the current number of rooms is less than the minimum
				if n_rooms < curr_min_rooms 
					puts "GENERATE SCHEDULE: Failed; generated less rooms than minimum @ index #{index}, n_rooms #{n_rooms}, curr_min #{curr_min_rooms}"
					failed = true
				end

				# Will fail if the max isn't infinite and n_rooms > max
				if !max.infinite? && n_rooms > max
					puts "GENERATE SCHEDULE: Failed; generated more than max somehow"
					failed = true
				end

				fulfill.push(req_fulfilled) # Add lists regardless of failed since the whole building will get rejected in the end anyways
				# puts "END OF REQUIREMENT"
			end #END of loop with potential rooms of the building

			if !failed
				options.push(fulfill)
			end
			# puts "END OF BUILDING"
		end #END of buildings loop
		
		
		# options [
		# 	[] # Buildings
		# 	[
		# 		[] # Requirements
		# 		[
		# 			[] # List of rooms that fulfill requirements
		# 			[]
		# 			[]
		# 			[]
		# 			[]
		# 			[]
		# 		]
		# 		[]
		# 		[]
		# 		[]
		# 		[]
		# 	]
		# 	[]
		# 	[]
		# 	[]
		# 	[]
		# ]

		# option[building][requirement][rooms]
		# option[building][requirement][0] = purpose
		# puts options.length

		# index = 0
		# for building in options
		# 	puts "Building: #{buildings[index].name}"
		# 	index += 1
		# 	for requirement in building
		# 		if requirement.length > 0
		# 			puts requirement[0]
		# 			for room in requirement[1..-1]
		# 				print "Name: #{room.name} Cap: #{room.capacity} "
		# 			end
		# 			puts " "
		# 		end
		# 	end
		# 	puts " "
		# end

		#CREATE SCHEDULES FROM OPTIONS
		schedules = []
		options.each_with_index do |building, index|
			puts buildings[index].name
			# reqs.length.times do |i|
			# 	puts (building[i].length - 1)
			# end
			temp_sched = Schedule.new(buildings[index], name, startTime, endTime, nAttendees, building)
			schedules.push(temp_sched)
		end

		return schedules
	end

	# @param schedule [Schedule]
	# @param filepath [String] 
	def self.createCSV(schedule, filepath, required_headers) 
		# Create CSV file
		CSV.open(filepath, "w") do |csv|
			# HEADER ROW
			csv << required_headers
			rooms_list = schedule.rooms
			for rooms in rooms_list # Get list of rooms not including the purpose
				for room in rooms[1..-1]
					row_list = []
					# Assumes that the first two entries will always be date and time
					date = "#{schedule.startTime.year}-#{schedule.startTime.month}-#{schedule.startTime.day}"
					row_list.push(date)
					time = "#{schedule.startTime.hour}:#{schedule.startTime.minute} #{schedule.startTime.strftime("%p")}"
					row_list.push(time)

					# Assumes all headers are included in the room's attribute variable
					for header in required_headers
						begin 
							row_list.push(room.attributes[header])
						rescue 
							puts "GENERATESCHEDULE: createCSV: row does not have header: #{header}"
						end
					end

					# Assumes last entry is always the purpose
					purpose = rooms[0]
					row_list.push(purpose)

					csv << row_list
				end # Individual room end
			end # List of rooms
		end # End of adding to CSV
	end

	def self.printSchedule(schedule, show_attributes)
		date = "#{schedule.startTime.year}-#{schedule.startTime.month}-#{schedule.startTime.day}"
		time = "#{schedule.startTime.hour}:#{schedule.startTime.minute} #{schedule.startTime.strftime("%p")}"
		for requirement in schedule.rooms
			if requirement.length > 0
				for room in requirement[1..-1]
					#Assumes print format will always start with this
					print "Date: [#{date}] Time: [#{time}] Building: [#{schedule.building.name}] Room Name: [#{room.name}] Capacity: [#{room.capacity}] "
					for attribute in show_attributes
						begin
							curr_attr = room.attributes[attribute]
							print "#{attribute}: [#{curr_attr}] " 
						rescue
							puts "GENERATE SCHEDULE: ERROR room does not have this attribute #{attribute}"
						end
					end
					# Assumes always ends with purpose
					print "Purpose: [#{requirement[0]}]\n"
				end
			end
		end
	end

	# @return Returns an array [StartTime, EndTime]
	def self.strToTimes(year, month, day, time, durationHour)
		startTimeStr = year + "-" + month + "-" + day + " " + time 
		startTime = DateTime.strptime(startTimeStr, "%Y-%m-%d %I:%M %p")
		endTime = startTime + (durationHour.to_f / 24)
		return [startTime, endTime]
	end

	# @return Returns an array [StartTime, Duration in hours]
	def self.timesToDuration(startTime, endTime) 
		durationDateTime = endTime - startTime
		durationHour = durationDateTime * 24
		return [startTime, durationHour]
	end

	# @return Returns a dictionary from a building to a list of potential rooms for each requirement
	def self.checkRequirements(reqs, buildings, nAttendees, startTime, endTime, marginHours)
		# Dictionary { Building : [ for opening ceremony[rooms] closing[] food[] comp[] large[] small[]]}
		result = {}

		# Iterate over each buildings rooms and run the list of requirements
		# Gets a dictionary of buildings and a list of potential rooms that fulfil each requirement
		buildings.each do |building|
			potential_rooms = []
			reqs.each do |req|
				potential_rooms.push(req.call(building.rooms, nAttendees, startTime, endTime, marginHours))
			end
			result[building.name] = potential_rooms
		end

		return result
	end

end 			#class ending