require "csv"
require "time"

require_relative "passenger"
require_relative "trip"
require_relative "driver"

module RideShare
  class TripDispatcher
    attr_reader :drivers, :passengers, :trips

    def initialize(directory: "./support")
      @passengers = Passenger.load_all(directory: directory)
      @trips = Trip.load_all(directory: directory)
      @drivers = Driver.load_all(directory: directory)
      connect_trips
    end

    def find_passenger(id)
      Passenger.validate_id(id)
      return @passengers.find { |passenger| passenger.id == id }
    end

    def find_driver(id)
      Driver.validate_id(id)
      return @drivers.find { |driver| driver.id == id }
    end

    def inspect
      # Make puts output more useful
      return "#<#{self.class.name}:0x#{object_id.to_s(16)} \
              #{trips.count} trips, \
              #{drivers.count} drivers, \
              #{passengers.count} passengers>"
    end

    def request_trip(passenger_id)
      trip_driver = nil
      @drivers.each do |driver|
        if driver.status == :AVAILABLE
          trip_driver = driver
          break
        end
      end

      unless trip_driver 
        raise ArgumentError, "No drivers are available"
      end

      id = trips.map do |trip|
        trip.id
      end

      new_trip = RideShare::Trip.new(id: id.max + 1,
                                     passenger: find_passenger(passenger_id),
                                     passenger_id: passenger_id,
                                     start_time: Time.new.to_s,
                                     end_time: nil,
                                     cost: nil,
                                     rating: nil,
                                     driver_id: trip_driver.id,
                                     driver: trip_driver)

      new_trip.driver.assign_trip(new_trip)
      new_trip.passenger.add_trip(new_trip)

      @trips << new_trip

      return new_trip
    end

    private

    def connect_trips
      @trips.each do |trip|
        passenger = find_passenger(trip.passenger_id)
        driver = find_driver(trip.driver_id)

        trip.connect(passenger, driver)
      end

      return trips
    end
  end
end
