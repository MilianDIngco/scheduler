require 'entities/building'
require 'entities/room'

class Schedule 


	attr_accessor :name, :building, :date, :time, :duration, :bookingType, :numAttendees, :reqs

	# @param name [String] : name of the event
	# @param building [Building] : building the event is hosted in, nil if not given
	# @param time [Time] : holds the date and time of the event, nil if not given
	# @param duration [Float] : float number of hours the event lasts, -1 if not given
	# @param bookingType [String] : type of event, nil if not given
	# @param numAttendees [Integer] : number of attendees, -1 if not given
	# @param reqs [ lambda { |building, nAttendees| }] : List of requirements, nil if not given
	# List of lambda expressions to be evaluated to test if a building will work. Takes building: Building, nAttendees: Integer. Returns boolean

	def initialize(name: nil, building: nil, time: nil, duration: -1, bookingType: nil, numAttendees: -1, reqs: nil)
		@name = name
		@building = building
		@date = date
		@time = time
		@duration = duration
		@bookingType = bookingType
		@numAttendees = numAttendees
		@reqs = reqs
	end

end
