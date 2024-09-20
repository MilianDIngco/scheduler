require 'entities/building'
require 'entities/room'

class Schedule 

	attr_accessor :building, :name, :startTime, :endTime, :numAttendees, :rooms

	# @param buildings [Building]
	# @param name [String] : name of the event
	# @param startTime [Time] : holds the start date and time of the event, nil if not given
	# @param endTime [Time] : holds the end date and time of the event, nil if not given
	# @param numAttendees [Integer] : number of attendees, -1 if not given
	# @param rooms [List[Room]] : List of rooms [ ["Purpose", room list ...] ... ]
	def initialize(building, name, startTime, endTime, numAttendees, rooms)
		@building = building
		@name = name
		@startTime = startTime
		@endTime = endTime
		@numAttendees = numAttendees
		@rooms = rooms
	end

end
