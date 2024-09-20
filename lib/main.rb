$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'entities/building'
require 'entities/room'
require 'control/schedulereader'
require 'control/generateschedule'
require 'date'
require 'time'

class Main

	attr_accessor :reqs, :sched_to_csv_header, :buildings, :minCapacity, :minRooms, :req_reqs, :show_attributes

	def initialize

		#========================================== CSV FILE DATA ============================================================
		room_list_headers = ["Building", "Room", "Capacity", "Computers Available", "Seating Available", "Seating Type", "Food Allowed", "Priority", "Room Type"]
		reservation_list_headers = ["Building", "Room", "Date", "Time", "Duration", "Booking Type"]	

		valid_values = {
			"Computers Available"=>["Yes", "No"],
			"Food Allowed"=>["Yes", "No"]
		}	
		
		room_list_csv = "../data/rooms_list.csv"
		reservation_list_csv = "../data/reserved_rooms.csv"

		required_headers = [room_list_headers, reservation_list_headers]
		file_paths = [room_list_csv, reservation_list_csv]
		
		# Read CSV files and get list of buildings
		@buildings = ScheduleReader.readCSV(file_paths, required_headers, valid_values)	
		@buildings.each do |building|
			#puts building.name
			building.rooms.each do |room|
				#puts room.availability
			end
		end

		#======================================================= SCHEDULE REQUIREMENTS ================================================

		food_allowed = ->(rooms, nAttendees, startTime, endTime, marginHours) {                                                                                             # potential_rooms -1 indicates the end of a food period
			potential_rooms = ["Food Allowed"]

			food_interval = 6
			meal_duration = 1

			# Get duration of event
			durationDateTime = endTime - startTime
			durationHour = durationDateTime * 24

			for i in 1..(durationHour / food_interval)
				foodStartTime = startTime + Rational(i * food_interval, 24) - Rational(marginHours, 24)
				foodEndTime = foodStartTime + Rational(meal_duration, 24) + Rational(marginHours, 24)
				rooms.each do |room|
					if room.isAvailable(foodStartTime, foodEndTime) && room.attributes["Food Allowed"] == "Yes"
						potential_rooms.push(room)
					end 
				end
			end

			return potential_rooms
		}
		computers_provided = ->(rooms, nAttendees, startTime, endTime, marginHours) {
			potential_rooms = ["Computers Provided"]

			eventStartTime = startTime - Rational(marginHours, 24)
			eventEndTime = endTime + Rational(marginHours, 24)
			rooms.each do |room|
				if room.attributes["Computers Available"] == "Yes" && room.isAvailable(eventStartTime, eventEndTime)
					potential_rooms.push(room)
				end
			end

			return potential_rooms
		}
		small_group = ->(rooms, nAttendees, startTime, endTime, marginHours) {
			potential_rooms = ["Small Group"]

			eventStartTime = startTime - Rational(marginHours, 24)
			eventEndTime = endTime + Rational(marginHours, 24)
			rooms.each do |room|
				if room.attributes["Room Type"] == "Study Room" && room.isAvailable(eventStartTime, eventEndTime)
					potential_rooms.push(room)
				end
			end

			return potential_rooms
		}
		large_group = ->(rooms, nAttendees, startTime, endTime, marginHours) {
			potential_rooms = ["Large Group"]

			large_capacity = 30
			eventStartTime = startTime - Rational(marginHours, 24)
			eventEndTime = endTime + Rational(marginHours, 24)
			rooms.each do|room|
				if room.capacity > large_capacity && room.isAvailable(eventStartTime, eventEndTime)
					potential_rooms.push(room)
				end
			end

			return potential_rooms
		}	
		opening_ceremony = ->(rooms, nAttendees, startTime, endTime, marginHours) {
			potential_rooms = ["Opening Ceremony"]

			opening_duration = 1
			ceremonyStartTime = startTime - Rational(marginHours, 24)
			ceremonyEndTime = startTime + Rational(opening_duration, 24) + Rational(marginHours, 24)
			rooms.each do |room|
				if room.isAvailable(ceremonyStartTime, ceremonyEndTime) && room.capacity > nAttendees
					potential_rooms.push(room)
				end
			end

			return potential_rooms
		}
		closing_ceremony = ->(rooms, nAttendees, startTime, endTime, marginHours) {
			potential_rooms = ["Closing Ceremony"]

			closing_duration = 3
			ceremonyStartTime = endTime - Rational(closing_duration, 24) - Rational(marginHours, 24)
			ceremonyEndTime = endTime + Rational(marginHours, 24)
			rooms.each do |room|
				if room.isAvailable(ceremonyStartTime, ceremonyEndTime) && room.capacity > nAttendees
					potential_rooms.push(room)
				end
			end

			return potential_rooms
		}
		@reqs = [opening_ceremony, closing_ceremony, food_allowed, computers_provided, large_group, small_group]
		
		# ================================================= SCHEDULE TO CSV HEADERS ==================================================
		# FIRST AND SECOND IS ALWAYS DATE, TIME, LAST IS ALWAYS PURPOSE
		@sched_to_csv_header = ["Building", "Room", "Capacity", "Computers Available", "Seating Available", "Seating Type", "Food Allowed", "Room Type", "Priority"]

		# Percentage of people the rooms need to admit
		@minCapacity = [1, 1, 0.6, 0.1, 0.6, 0.4]
		# Minimum number of rooms per purpose / requirement
		# Negative numbers indicate a maximum amount. -1 indicates there can only be up to 1 opening and closing ceremony room
		@minRooms = [-1, -1, 2, 0, 3, 1]
		# Booleans indicating if this requirement needs to be accounted for. eg: we need computer rooms, but they shouldn't be taken away from small room and large room groups
		@req_reqs = [true, true, true, false, true, true]
		
		# Attributes to show when printing the schedule, by default it starts with Date, Time, Building, Room Name, Capacity, and ends with Purpose
		@show_attributes = ["Computers Available", "Food Allowed"]

	end

	def run

		# Request [year, month, day, time, duration in hours, name of event, number of attendees, margin of time before and after event starts and ends]
		puts "[Scheduling Room Master] (novice)"
		# im so sorry theres going to be absolutely no input sanitization
		wanted = false

		#default values
		year = "2024"
		month = "12"
		day = "25"
		time = "12:00 PM"
		durationHour = "25.0"
		name = "Barangay"
		nAttendees = 500
		marginHours = 1
		
		while !wanted 
		
			puts "Enter the year in this format [20xx]"
			year = gets.chomp

			puts "Enter the month in this format [xx]. [01] to [12]"
			month = gets.chomp

			puts "Enter the day in this format [xx] [01] to [31] (well depending if the month has 31 days i guess)"
			day = gets.chomp

			puts "Enter the time that the event will start in this format [xx:xx xM] eg: [12:30 PM]"
			time = gets.chomp

			puts "Enter the duration of the event in hours in the format [xx.x] eg: [24.5] == 24 hours 30 minutes"
			durationHour = gets.chomp

			puts "Enter the name of the event"
			name = gets.chomp

			puts "Enter the number of attendees you expect" 
			nAttendees = gets.chomp.to_i rescue next

			puts "Enter the margin of time you want the rooms to be open before and after the event starts and ends in hours [xx.x] eg: [1.5] == 1 hour 30 minutes"
			marginHours = gets.chomp.to_f rescue next

			puts "Is this correct?"
			puts "#{year}-#{month}-#{day} at #{time} for #{durationHour} hour/s"
			puts "Name: #{name} with #{nAttendees} attendees and a margin of #{marginHours} hour/s"
			puts "Enter yes if correct, anything else if not"
			isCorrect = gets.chomp.upcase
			wanted = isCorrect.start_with?("Y")

		end
		
		times = GenerateSchedule.strToTimes(year, month, day, time, durationHour)

		#list of schedules
		schedules = GenerateSchedule.getValidSchedule(@buildings, name, times[0], times[1], nAttendees, marginHours, @reqs, @minCapacity, @minRooms, @req_reqs)
		schedules.length.times do |i|
			puts "================================Option #{i}=====================================:"
			GenerateSchedule.printSchedule(schedules[i], @show_attributes)
		end

		wanted = false
		while !wanted
			puts "Enter the option # you want to save to a csv file: "
			option_no = gets.chomp.to_i rescue next

			puts "Enter name of csv file you wish to write the schedule to: "
			file_path = gets.chomp
			puts "Is this what you wanted? Save option # #{option_no} to [#{file_path}] y/n"
			isCorrect = gets.chomp.upcase
			wanted = isCorrect.start_with?("Y")
		end

		GenerateSchedule.createCSV(schedules[0], file_path, @sched_to_csv_header)

	end

end
 
if __FILE__ == $0
	app = Main.new
	app.run
end
