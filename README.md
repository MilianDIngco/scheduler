Name: Milian
VM-Name: student1@csc415-server08.hpc.tcnj.edu
Path to project directory: /home/student1/vm-csc415/scheduler
Github Repo: https://github.com/MilianDIngco/scheduler
Assumptions: 
Assumes room_list has columns ["Computers Available", "Food Allowed"] and ["Building", "Room", "Capacity", "Computers Available", "Seating Available", "Seating Type", "Food Allowed", "Room Type", "Priority"]

Not too many assumptions as the schedule reader checks if it’s given a valid csv file and if each row is valid before creating objects

To run the program
cd /home/student1/vm-csc415/scheduler/lib
ruby main.rb

Limitations
- Little to no input sanitization
