require 'entities/building'
require 'entities/room'
require 'entities/schedule'
require 'date'
require 'time'

=begin
Assumes room has attribute capacity

=end

class GenerateSchedule

	# @param buildings [List[Building]] 
	# @param name [String] name of event
	# @param year [String] year
	# @param month [String] number of month
	# @param day [String] day number
	# @param hour [String]
	# @param minute [String]
	# @param meridian [String] AM or PM
	# @param durationHour [Float] length of event in hours
	# @param numAttendees [Integer] Number of attendees
	# @param marginHours [Float] Number of hours before and after your event starts and ends that rooms should be clear
	# @param reqs [List[lambda : (rooms, roomAvail, nAttendees, startTime, endTime, marginHours)]] list of requirements
	# @param min_capacity [List[integer]] Lists of minimum total capacities
	
	# @return Returns a hashmap { Building Name : List[ List[Indices] ]

	def self.getValidSchedule(buildings, name, year, month, day, time, durationHour, nAttendees, marginHours, reqs, min_capacity)
		# Create Start and End DateTimes
		startTimeStr = year + "-" + month + "-" + day + " " + time 
		startTime = DateTime.strptime(startTimeStr, "%Y-%m-%d %H:%M %p")
		seconds = durationHour * 3600
		endTime = startTime + (seconds.to_f / 86400)	

		result = {}

		buildings.each do |building|
			# Iterate over list of lambdas and store potential rooms in list of lists
			potential_rooms = []
			reqs.each do |req|
				potential_rooms.push(req.call(building.rooms, nAttendees, startTime, endTime, marginHours))
			end

			# Check if the set of each list of given rooms has enough 					
			totals = Array.new(reqs.length, 0)
			index = 0
			for room_list in potential_rooms
				for room_index in room_list
					totals[index] += building.rooms[room_index].capacity
				end
				puts totals[index]
				index += 1
			end

			index = 0
			for t in totals
				puts "total capacity: #{t} min capacity: #{min_capacity[index] * nAttendees}"
				if t < (min_capacity[index] * nAttendees)
					puts "#{building.name} Failed to meet the criteria for capacity at index #{index}"
					index += 1
					next
				end	
				index += 1
			end
			
			result[building.name] = potential_rooms
	
		end	#building loop ending
		
		return result
	end		#method ending


	def self.format(potentials) 
		

		# { building: [
		# 		[room #, t]		
		# 		]}
		
		
		
	end

end 			#class ending
