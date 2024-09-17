require 'entities/building'
require 'entities/room'
require 'csv'

=begin
Assumes csv has columns:
 - Building

Assumes csv has headers
=end

class ScheduleReader

	def self.readCSV(file_path)
		buildings = {}
		CSV.foreach(file_path, headers: true) do |row|
			#Check if new building has been seen
			if !buildings.key?(row["Building"])	
				temp_building = Building.new([], row["Building"])
				buildings[row["Building"]] = temp_building
			end

			temp_room = Room.new(row)
			buildings[row["Building"]].rooms.push(temp_room)

		end
		
		return buildings.values
	end

end
