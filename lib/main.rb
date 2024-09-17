$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'entities/building'
require 'entities/room'
require 'control/schedulereader'

class Main

	def initialize
		buildings = ScheduleReader.readCSV("../data/rooms_list.csv")	
		buildings.each do |building|
			puts "Name: %s" % building.name
			building.rooms.each do |room|
				puts "Room #: %s" % room.attributes["Room"]
			end
		end
	end

	def run
	end

end
 

if __FILE__ == $0
	app = Main.new
	app.run
end
