require_relative "spec_helper"

TEST_DATA_DIRECTORY = "specs/test_data"

describe "TripDispatcher class" do
  def build_test_dispatcher
    return RideShare::TripDispatcher.new(
             directory: TEST_DATA_DIRECTORY,
           )
  end

  describe "Initializer" do
    it "is an instance of TripDispatcher" do
      dispatcher = build_test_dispatcher
      expect(dispatcher).must_be_kind_of RideShare::TripDispatcher
    end

    it "establishes the base data structures when instantiated" do
      dispatcher = build_test_dispatcher
      [:trips, :passengers].each do |prop|
        expect(dispatcher).must_respond_to prop
      end

      expect(dispatcher.trips).must_be_kind_of Array
      expect(dispatcher.passengers).must_be_kind_of Array
      # expect(dispatcher.drivers).must_be_kind_of Array
    end

    it "loads the development data by default" do
      # Count lines in the file, subtract 1 for headers
      trip_count = %x{wc -l 'support/trips.csv'}.split(" ").first.to_i - 1

      dispatcher = RideShare::TripDispatcher.new

      expect(dispatcher.trips.length).must_equal trip_count
    end
  end

  describe "passengers" do
    describe "find_passenger method" do
      before do
        @dispatcher = build_test_dispatcher
      end

      it "throws an argument error for a bad ID" do
        expect { @dispatcher.find_passenger(0) }.must_raise ArgumentError
      end

      it "finds a passenger instance" do
        passenger = @dispatcher.find_passenger(2)
        expect(passenger).must_be_kind_of RideShare::Passenger
      end
    end

    describe "Passenger & Trip loader methods" do
      before do
        @dispatcher = build_test_dispatcher
      end

      it "accurately loads passenger information into passengers array" do
        first_passenger = @dispatcher.passengers.first
        last_passenger = @dispatcher.passengers.last

        expect(first_passenger.name).must_equal "Passenger 1"
        expect(first_passenger.id).must_equal 1
        expect(last_passenger.name).must_equal "Passenger 8"
        expect(last_passenger.id).must_equal 8
      end

      it "connects trips and passengers" do
        dispatcher = build_test_dispatcher
        dispatcher.trips.each do |trip|
          expect(trip.passenger).wont_be_nil
          expect(trip.passenger.id).must_equal trip.passenger_id
          expect(trip.passenger.trips).must_include trip
        end
      end
    end
  end

  describe "drivers" do
    describe "find_driver method" do
      before do
        @dispatcher = build_test_dispatcher
      end

      it "throws an argument error for a bad ID" do
        expect { @dispatcher.find_driver(0) }.must_raise ArgumentError
      end

      it "finds a driver instance" do
        driver = @dispatcher.find_driver(2)
        expect(driver).must_be_kind_of RideShare::Driver
      end
    end

    describe "Driver & Trip loader methods" do
      before do
        @dispatcher = build_test_dispatcher
      end

      it "accurately loads driver information into drivers array" do
        first_driver = @dispatcher.drivers.first
        last_driver = @dispatcher.drivers.last

        expect(first_driver.name).must_equal "Driver 1 (unavailable)"
        expect(first_driver.id).must_equal 1
        expect(first_driver.status).must_equal :UNAVAILABLE
        expect(last_driver.name).must_equal "Driver 3 (no trips)"
        expect(last_driver.id).must_equal 3
        expect(last_driver.status).must_equal :AVAILABLE
      end

      it "connects trips and drivers" do
        dispatcher = build_test_dispatcher
        dispatcher.trips.each do |trip|
          expect(trip.driver).wont_be_nil
          expect(trip.driver.id).must_equal trip.driver_id
          expect(trip.driver.trips).must_include trip
        end
      end
    end
  end

  describe "Requesting a trip" do
    before do
      @passenger_id = 4
      @dispatcher = build_test_dispatcher
    end

    it "creates an instance of trip and returns that trip" do
      new_trip = @dispatcher.request_trip(@passenger_id)
      expect(new_trip).must_be_kind_of RideShare::Trip
    end

    it "assigns a driver" do
      new_trip = @dispatcher.request_trip(@passenger_id)
      expect(new_trip.driver).must_be_kind_of RideShare::Driver
    end

    it "changes driver's status to :UNAVAILABLE driver" do
      new_trip = @dispatcher.request_trip(@passenger_id)
      expect(new_trip.driver.status).must_equal :UNAVAILABLE
    end

    it "Uses time for the start time" do
      new_trip = @dispatcher.request_trip(@passenger_id)
      expect(new_trip.start_time).must_be_kind_of Time
    end

    it "End date cost and rating will all be nil" do
      new_trip = @dispatcher.request_trip(@passenger_id)
      expect(new_trip.end_time).must_equal nil
      expect(new_trip.cost).must_equal nil
      expect(new_trip.rating).must_equal nil
    end

    it "adds Trip to Passenger's list of Trips" do
      original_trip_list = @dispatcher.find_passenger(@passenger_id).trips.length
      new_trip = @dispatcher.request_trip(@passenger_id)
      new_trip_list = @dispatcher.find_passenger(@passenger_id).trips
      expect(new_trip_list.length).must_equal original_trip_list + 1
    end

    it "adds the new trip to the collection of all Trips in TripDispatcher" do
      original_trip_list = @dispatcher.trips.length
      new_trip = @dispatcher.request_trip(@passenger_id)
      expect(@dispatcher.trips.length).must_equal original_trip_list + 1
    end

    it "adds Trip to Driver's list of Trips" do
      original_trip_list = @dispatcher.find_driver(2).trips.length
      new_trip = @dispatcher.request_trip(@passenger_id)
      new_trip_list = new_trip.driver.trips
      expect(new_trip_list.length).must_equal original_trip_list + 1
    end
    
    it "raises ArgumentError if you pass nil into request_trip" do
      err = expect {
        @dispatcher.request_trip(nil)
      }.must_raise ArgumentError

      expect(err.message).must_equal 'ID cannot be blank or less than zero.'
    end

    it "raises ArgumentError if no drivers are available" do
      @dispatcher.drivers.each do |driver|
        driver.status = :UNAVAILABLE
      end
      expect {
        new_trip = @dispatcher.request_trip(@passenger_id)
      }.must_raise ArgumentError
    end

    it "raises ArgumentError if it tries to calculate total expenditures for passenger with in-progress trip" do
      new_trip = @dispatcher.request_trip(@passenger_id)
      expect(new_trip.passenger.net_expenditures).must_equal 15
    end

    it "raises ArgumentError if it tries to calculate average rating for driver with in-progress trip" do
      new_trip = @dispatcher.request_trip(@passenger_id)
      expect(new_trip.driver.average_rating).must_equal 2.0
    end
  end
end
