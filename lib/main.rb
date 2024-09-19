$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'entities/building'
require 'entities/room'
require 'control/schedulereader'
require 'control/generateschedule'
require 'date'
require 'time'

class Main

	def initialize
		room_list_headers = ["Building", "Room", "Capacity", "Computers Available", "Seating Available", "Seating Type", "Food Allowed", "Priority", "Room Type"]
		reservation_list_headers = ["Building", "Room", "Date", "Time", "Duration", "Booking Type"]	
		
		room_list_csv = "../data/rooms_list.csv"
		reservation_list_csv = "../data/reserved_rooms.csv"

		required_headers = [room_list_headers, reservation_list_headers]
		file_paths = [room_list_csv, reservation_list_csv]
		
		buildings = ScheduleReader.readCSV(file_paths, required_headers)	
		buildings.each do |building|
			#puts building.name
			building.rooms.each do |room|
				#puts room.availability
			end
		end

	
		food_allowed = ->(rooms, nAttendees, startTime, endTime, marginHours) {                                                                                             # potential_rooms -1 indicates the end of a food period
                	potential_rooms = []

                	food_interval = 6
                	meal_duration = 1

                	# Get duration of event
                	durationDateTime = endTime - startTime
                	durationHour = durationDateTime * 24

                	for i in 1..(durationHour / food_interval)
                        	foodStartTime = startTime + Rational(i * food_interval, 24) - Rational(marginHours, 24)
                        	foodEndTime = foodStartTime + Rational(meal_duration, 24) + Rational(marginHours, 24)
                        	rooms.each_with_index do |room, index|
	                                if room.isAvailable(foodStartTime, foodEndTime)
                	                        potential_rooms.push(index)
					end 
				end
                        end

                	return potential_rooms
        	}

		computers_provided = ->(rooms, nAttendees, startTime, endTime, marginHours) {
	                potential_rooms = []

        	        eventStartTime = startTime - Rational(marginHours, 24)
                	eventEndTime = endTime + Rational(marginHours, 24)
                	rooms.each_with_index do |room, index|
                       		if room.attributes["Computers Available"] == "Yes" && room.isAvailable(eventStartTime, eventEndTime)
                                	potential_rooms.push(index)
                        	end
                	end

                	return potential_rooms
        	}

		small_group = ->(rooms, nAttendees, startTime, endTime, marginHours) {
        	        potential_rooms = []
	
                	eventStartTime = startTime - Rational(marginHours, 24)
                	eventEndTime = endTime + Rational(marginHours, 24)
                	rooms.each_with_index do |room, index|
                        	if room.attributes["Room Type"] == "Study Room" && room.isAvailable(eventStartTime, eventEndTime)
					potential_rooms.push(index)
                        	end
                	end

        	        return potential_rooms
	        }

		large_group = ->(rooms, nAttendees, startTime, endTime, marginHours) {
                	potential_rooms = []

                	large_capacity = 30
                	eventStartTime = startTime - Rational(marginHours, 24)
                	eventEndTime = endTime + Rational(marginHours, 24)
                	rooms.each_with_index do|room, index|
                        	if room.capacity > large_capacity && room.isAvailable(eventStartTime, eventEndTime)
                                	potential_rooms.push(index)
                        	end
                	end

        	        return potential_rooms
	        }

		
		opening_ceremony = ->(rooms, nAttendees, startTime, endTime, marginHours) {
                	potential_rooms = []

                	opening_duration = 1
                	ceremonyStartTime = startTime - Rational(marginHours, 24)
                	ceremonyEndTime = startTime + Rational(opening_duration, 24) + Rational(marginHours, 24)
                	rooms.each_with_index do |room, index|
                        	if room.isAvailable(ceremonyStartTime, ceremonyEndTime) && room.capacity > nAttendees
                                	potential_rooms.push(index)
                        	end
                	end
			puts "POTENTIAL #{potential_rooms}" 

        	        return potential_rooms
	        }
		
		closing_ceremony = ->(rooms, nAttendees, startTime, endTime, marginHours) {
        	        potential_rooms = []
	
                	closing_duration = 3
                	ceremonyStartTime = endTime - Rational(closing_duration, 24) - Rational(marginHours, 24)
                	ceremonyEndTime = endTime + Rational(marginHours, 24)
                	rooms.each_with_index do |room, index|
	                        if room.isAvailable(ceremonyStartTime, ceremonyEndTime) && room.capacity > nAttendees
	                                potential_rooms.push(index)
	                        end
	                end
	
	                return potential_rooms
	        }

		reqs = [opening_ceremony, closing_ceremony, food_allowed, computers_provided, large_group, small_group]
		
		min_capacity = [1, 1, 0.6, 0.1, 0.6, 0.4]

		potentials = GenerateSchedule.getValidSchedule(buildings, "Barangay", "2024", "12", "25", "1:30 AM", 13, 300, 1, reqs, min_capacity) 

		puts potentials

	end

	def run
	end

end
 

if __FILE__ == $0
	app = Main.new
	app.run
end
