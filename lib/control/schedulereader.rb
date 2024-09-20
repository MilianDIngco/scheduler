require 'entities/building'
require 'entities/room'
require 'csv'
require 'time'
require 'date'

=begin
Assumes csv has columns:
 - Building

Assumes csv has headers

to do:
write function that prior to read checks for all assumptions

=end

class ScheduleReader

	# Hard coded valid values for rooms
	# Assumes we don't care about seating type, seating available, priority, and room type
	# We do care about Building, Room, and Capacity, however the name of the building doesn't matter and we check if room / capacity is a valid integer anyways

	def self.readCSV(file_paths, required_headers, valid_values)
		buildings = {}
		reservations = {}	

		reservation_list_csv = CSV.read(file_paths[1], headers: true)
		reservation_list_headers = required_headers[1]
		
		room_list_csv = CSV.read(file_paths[0], headers: true)
		room_list_headers = required_headers[0]

		# Check if its a valid room list file
		if !valid_csv(room_list_csv, room_list_headers)
			puts "SCHEDULE READER: ERROR: Invalid csv file"
			return nil
		end

		# Check if its a valid reservation list file
		if !valid_csv(reservation_list_csv, reservation_list_headers)
			puts "SCHEDULE READER ERROR: Invalid reservation csv"
			return nil
		end

		# =====================Read reservation list==========================
		reservation_list_csv.each do |row|
			# Make start time stamp
			start_str = row["Date"] + " " + row["Time"]

			# Calculate start and end DateTime objects
			begin
				start = DateTime.strptime(start_str, "%Y-%m-%d %H:%M %p")
				durationDateTime = DateTime.strptime(row["Duration"], "%H:%M") rescue next
			rescue ArgumentError
				puts "SCHEDULE READER: ERROR: Bad DateTime input"
				next
			end
			seconds = (durationDateTime.hour * 3600) + (durationDateTime.minute * 60)
			endTime = start + (seconds.to_f / 86400)

			#Add building if not seen
			# reservations = { Building Name : [ [room#, start times, end times, ...], ...] }
			if !reservations.key?(row["Building"])
				reservations[row["Building"]] = []
			end
			
			# List of a buildings rooms' reservations	
			rooms = reservations[row["Building"]]
			
			# Check if room number is valid
			if (Integer(row["Room"]) rescue false) == false
				puts "SCHEDULE READER: ERROR: Invalid room value input"
				next
			end

			if (Integer(row["Room"]) < 0)
				puts "SCHEDULE READER: ERROR: Negative room value"
				next
			end

			roomNumber = Integer(row["Room"])

			# ========= ADDING AND SORTING NEW ROOMS ===========
			# Check if roomNumber is contained
			found = rooms.any? { |room| room[0] == roomNumber }
			
			# If room number isn't found, add it
			if !found
				temp_arr = [roomNumber]
				rooms.push(temp_arr)
			end	
				
			# Sort the array
			rooms.sort_by! { |room| room[0] }

			# Find index
			room_res_list = nil
			rooms.each_with_index do |room, i|
				if room[0] == roomNumber
					room_res_list = room
					break
				end
			end
			
			if room_res_list == nil
				puts "SCHEDULE READER: ERROR what"
			end
			
			# ========== ADDING AND SORTING DATES =================
			# if room reservation array has no dates, just append it
			# I have a function to 
			if room_res_list.length <= 1
				room_res_list.push(start)
				room_res_list.push(endTime)
			else
				# Otherwise, perfom a linear search to find where the date should be inserted
				
				# Check if end time is less than the first start date
				if room_res_list[1] < endTime
					room_res_list.insert(1, start)
					room_res_list.insert(2, endTime)
				else
					# Loop over the lists end times
					(2..(room_res_list.length - 1)).step(2) do |i|
						# Check if the start time is greater than the current end time and less than the next start time
						if (i == room_res_list.length - 1) && (room_res_list[i] < start)
							room_res_list.push(start)
							room_res_list.push(endTime)
							break
						end
				
						# If starts later than current end and ends earlier than next start, add start and end	
						if (room_res_list[i] < start) && (room_res_list[i + 1] > endTime)
							room_res_list.insert(i + 1, start)
							room_res_list.insert(i + 2, endTime)
							break
						end
					end
				end	
	
			end	# END OF SORTING DATES
			
		end	# END OF READING RESERVATIONS
		
		# just a waterfall or maybe a cliff of end keywords	

		# =====================Read room list==================================	
		room_list_csv.each do |row|
			#Check if new building has been seen
			if !buildings.key?(row["Building"])	
				temp_building = Building.new([], row["Building"])
				buildings[row["Building"]] = temp_building
			end
	
			#Check if a room is valid, skip room if not
			if (!valid_room(row, valid_values))	
				puts "SCHEDULE READER: ERROR: Invalid room value input"
				next
			end
			
			room_no = Integer(row["Room"])
			room_capacity = Integer(row["Capacity"])
			# Searching for the current room's reservation list
			room_res_list = nil
			for res_list in reservations[row["Building"]]
				if (res_list[0] == room_no)
					room_res_list = res_list
					break
				end	
			end
						
			temp_room = Room.new(row, room_no, room_capacity, room_res_list)
			buildings[row["Building"]].rooms.push(temp_room)
		end
		
		return buildings.values
	end

	# @param csv_data [CSV] csv file read by the CSV.read function
	# @param required_headers [List[String]] List of string names of each required header	
	# @return Returns boolean true if the file has the valid headers
	def self.valid_csv (csv_data, required_headers) 
		
		# Loop over all required headers and check if the csv file contains them
		required_headers.each do |header|
			if !csv_data.headers.include?(header)
				return false
			end
		end

		return true
	end

	# @param row [CSV::row] row of a rooms_list csv read from a csv file
	# @param valid_values [Hashmap { String : List[String] }] <- { Header name : List of valid values }	
	# @return returns boolean true if the given row is a valid set of attributes for a room 
	def self.valid_room (row, valid_values) 
		# Checks if room number is valid	
		room_num = row["Room"]
		if ((Integer(room_num) rescue false) != false) 
			if (Integer(room_num) < 0)
				puts "SCHEDULE READER: Negative room number: #{room_num}"
				return false
			end
		else
			puts "SCHEDULE READER: Invalid room number: #{room_num}"
			return false
		end 

		# Checks if capacity is valid
		capacity = row["Capacity"]
		if ((Integer(capacity) rescue false) != false)
			if (Integer(capacity) < 0)
				puts "SCHEDULE READER: Negative capacity: #{capacity}"
				return false
			end
		else
			puts "SCHEDULE READER: Invalid capacity: #{capacity}"
			return false
		end


		row.each do |header, value|
			# Check if the current header is one of the required headers
			if valid_values.key?(header) 
				# Check if the current value is one of the valid values
				if !(valid_values[header].include?(value))
					puts "SCHEDULE READER: Failed check header: #{header} value: #{value}"
					return false
				end
			end
		end
			
		return true 
	end

end
