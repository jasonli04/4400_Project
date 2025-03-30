-- CS4400: Introduction to Database Systems: Monday, March 3, 2025
-- Simple Airline Management System Course Project Mechanics [TEMPLATE] (v0)
-- Views, Functions & Stored Procedures

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'flight_tracking';
use flight_tracking;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [_] supporting functions, views and stored procedures
-- -----------------------------------------------------------------------------
/* Helpful library capabilities to simplify the implementation of the required
views and procedures. */
-- -----------------------------------------------------------------------------
drop function if exists leg_time;
delimiter //
create function leg_time(ip_distance integer, ip_speed integer)
    returns time
    reads sql data
begin
    declare total_time decimal(10, 2);
    declare hours, minutes integer default 0;
    set total_time = ip_distance / ip_speed;
    set hours = truncate(total_time, 0);
    set minutes = truncate((total_time - hours) * 60, 0);
    return maketime(hours, minutes, 0);
end //
delimiter ;

-- [1] add_airplane()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airplane.  A new airplane must be sponsored
by an existing airline, and must have a unique tail number for that airline.
username.  An airplane must also have a non-zero seat capacity and speed. An airplane
might also have other factors depending on it's type, like the model and the engine.  
Finally, an airplane must have a new and database-wide unique location
since it will be used to carry passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airplane;
delimiter //
create procedure add_airplane(in ip_airlineID varchar(50), in ip_tail_num varchar(50),
                              in ip_seat_capacity integer, in ip_speed integer, in ip_locationID varchar(50),
                              in ip_plane_type varchar(100), in ip_maintenanced boolean, in ip_model varchar(50),
                              in ip_neo boolean)
sp_main:
begin

    -- Ensure that the plane type is valid: Boeing, Airbus, or neither
    -- Ensure that the type-specific attributes are accurate for the type
    -- Ensure that the airplane and location values are new and unique
    -- Add airplane and location into respective tables

    DECLARE duplicate_airplane INT DEFAULT 0;
    DECLARE duplicate_location INT DEFAULT 0;

    -- Check model types
    IF ip_plane_type NOT IN ('Boeing', 'Airbus') AND ip_plane_type IS NOT NULL THEN
        LEAVE sp_main;
    END IF;

    -- Check boeing invalid attributes
    IF ip_plane_type = 'Boeing' AND (ip_model IS NULL OR ip_model = '' OR ip_maintenanced IS NULL) THEN
        LEAVE sp_main;
    END IF;

    -- Check airbus invalid attributes
    IF ip_plane_type = 'Airbus' AND ip_neo IS NULL THEN
        LEAVE sp_main;
    END IF;

    -- Check for duplicates
    SELECT COUNT(*)
    INTO duplicate_airplane
    FROM airplane
    WHERE airlineID = ip_airlineID
      AND tail_num = ip_tail_num;

    IF duplicate_airplane > 0 THEN
        LEAVE sp_main;
    END IF;

    -- check for duplicate location
    IF ip_locationID IS NOT NULL THEN
        SELECT COUNT(*)
        INTO duplicate_location
        FROM airplane
        WHERE locationID = ip_locationID;

        IF duplicate_location > 0 THEN
            LEAVE sp_main;
        END IF;
    END IF;

    INSERT INTO location (locationID) VALUES (ip_locationID);

    INSERT INTO airplane (airlineID, tail_num, seat_capacity, speed, locationID, plane_type, maintenanced, model, neo)
    VALUES (ip_airlineID, ip_tail_num, ip_seat_capacity, ip_speed, ip_locationID, ip_plane_type, ip_maintenanced,
            ip_model, ip_neo);

end //
delimiter ;

-- [2] add_airport()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airport.  A new airport must have a unique
identifier along with a new and database-wide unique location if it will be used
to support airplane takeoffs and landings.  An airport may have a longer, more
descriptive name.  An airport must also have a city, state, and country designation. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airport;
delimiter //
create procedure add_airport(in ip_airportID char(3), in ip_airport_name varchar(200),
                             in ip_city varchar(100), in ip_state varchar(100), in ip_country char(3),
                             in ip_locationID varchar(50))
sp_main:
begin

    -- Ensure that the airport and location values are new and unique
    -- Add airport and location into respective tables
    DECLARE cnt INT DEFAULT 0;


    SELECT COUNT(*)
    INTO cnt
    FROM airport
    WHERE airportID = ip_airportID;
    IF cnt > 0 THEN
        LEAVE sp_main;
    END IF;

    IF ip_locationID IS NOT NULL THEN
        SELECT COUNT(*)
        INTO cnt
        FROM airport
        WHERE locationID = ip_locationID;
        IF cnt > 0 THEN
            LEAVE sp_main;
        END IF;
        -- add if the location does not exist in the location table
        SELECT COUNT(*)
        INTO cnt
        FROM location
        WHERE locationID = ip_locationID;
        IF cnt = 0 THEN
            INSERT INTO location(locationID) VALUES (ip_locationID);
        END IF;
    END IF;

    INSERT INTO airport (airportID, airport_name, city, state, country, locationID)
    VALUES (ip_airportID, ip_airport_name, ip_city, ip_state, ip_country, ip_locationID);

end //
delimiter ;

-- [3] add_person()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new person.  A new person must reference a unique
identifier along with a database-wide unique location used to determine where the
person is currently located: either at an airport, or on an airplane, at any given
time.  A person must have a first name, and might also have a last name.

A person can hold a pilot role or a passenger role (exclusively).  As a pilot,
a person must have a tax identifier to receive pay, and an experience level.  As a
passenger, a person will have some amount of frequent flyer miles, along with a
certain amount of funds needed to purchase tickets for flights. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_person;
delimiter //
create procedure add_person(in ip_personID varchar(50), in ip_first_name varchar(100),
                            in ip_last_name varchar(100), in ip_locationID varchar(50), in ip_taxID varchar(50),
                            in ip_experience integer, in ip_miles integer, in ip_funds integer)
sp_main:
begin

    -- Ensure that the location is valid
    -- Ensure that the persion ID is unique
    -- Ensure that the person is a pilot or passenger
    -- Add them to the person table as well as the table of their respective role

    IF ip_locationID NOT IN (select locationID from location) THEN
        LEAVE sp_main;
    END IF;

    IF ip_personID IN (select personID from person) THEN
        LEAVE sp_main;
    END IF;

    IF ip_taxID IS NOT NULL and ip_experience IS NOT NULL and ip_experience > 0 THEN
        INSERT INTO person (personID, first_name, last_name, locationID)
        VALUES (ip_personID, ip_first_name, ip_last_name, ip_locationID);
        INSERT INTO pilot (personID, taxID, experience, commanding_flight)
        VALUES (ip_personID, ip_taxID, ip_experience, NULL);
    END IF;

    IF ip_miles IS NOT NULL and ip_miles > 0 and ip_funds IS NOT NULL and ip_funds > 0 THEN
        INSERT INTO person (personID, first_name, last_name, locationID)
        VALUES (ip_personID, ip_first_name, ip_last_name, ip_locationID);
        INSERT INTO passenger (personID, miles, funds)
        VALUES (ip_personID, ip_miles, ip_funds);
    END IF;

end //
delimiter ;

-- [4] grant_or_revoke_pilot_license()
-- -----------------------------------------------------------------------------
/* This stored procedure inverts the status of a pilot license.  If the license
doesn't exist, it must be created; and, if it aready exists, then it must be removed. */
-- -----------------------------------------------------------------------------
drop procedure if exists grant_or_revoke_pilot_license;
delimiter //
create procedure grant_or_revoke_pilot_license(in ip_personID varchar(50), in ip_license varchar(100))
sp_main:
begin

    -- Ensure that the person is a valid pilot
    -- If license exists, delete it, otherwise add the license
    DECLARE pilotCount INT DEFAULT 0;
    DECLARE licenseCount INT DEFAULT 0;

    SELECT COUNT(*) INTO pilotCount FROM pilot WHERE personID = ip_personID;
    IF pilotCount = 0 THEN
        LEAVE sp_main;
    END IF;


    SELECT COUNT(*)
    INTO licenseCount
    FROM pilot_licenses
    WHERE personID = ip_personID
      AND license = ip_license;

    IF licenseCount > 0 THEN
        DELETE
        FROM pilot_licenses
        WHERE personID = ip_personID
          AND license = ip_license;
    ELSE
        INSERT INTO pilot_licenses (personID, license)
        VALUES (ip_personID, ip_license);
    END IF;

end //
delimiter ;

-- [5] offer_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new flight.  The flight can be defined before
an airplane has been assigned for support, but it must have a valid route.  And
the airplane, if designated, must not be in use by another flight.  The flight
can be started at any valid location along the route except for the final stop,
and it will begin on the ground.  You must also include when the flight will
takeoff along with its cost. */
-- -----------------------------------------------------------------------------
drop procedure if exists offer_flight;
delimiter //
create procedure offer_flight(in ip_flightID varchar(50), in ip_routeID varchar(50),
                              in ip_support_airline varchar(50), in ip_support_tail varchar(50), in ip_progress integer,
                              in ip_next_time time, in ip_cost integer)
sp_main:
begin

    -- Ensure that the airplane exists
    -- Ensure that the route exists
    -- Ensure that the progress is less than the length of the route
    -- Create the flight with the airplane starting in on the ground

    IF (ip_support_airline, ip_support_tail) not in (select airlineID, tail_num from airplane) THEN
        LEAVE sp_main;
    END IF;

    IF ip_routeID not in (select routeID from route) THEN
        LEAVE sp_main;
    END IF;

    IF ip_progress >= (select max(sequence) from route_path group by routeID having routeID = ip_routeID) THEN
        LEAVE sp_main;
    END IF;

    INSERT INTO flight (flightID, routeID, support_airline, support_tail, progress, airplane_status, next_time, cost)
    VALUES (ip_flightID, ip_routeID, ip_support_airline, ip_support_tail, ip_progress, 'on_ground', ip_next_time, ip_cost);

end //
delimiter ;

-- [6] flight_landing()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight landing at the next airport
along it's route.  The time for the flight should be moved one hour into the future
to allow for the flight to be checked, refueled, restocked, etc. for the next leg
of travel.  Also, the pilots of the flight should receive increased experience, and
the passengers should have their frequent flyer miles updated. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_landing;
delimiter //
create procedure flight_landing(in ip_flightID varchar(50))
sp_main:
begin

    -- Ensure that the flight exists
    -- Ensure that the flight is in the air

    -- Increment the pilot's experience by 1
    -- Increment the frequent flyer miles of all passengers on the plane
    -- Update the status of the flight and increment the next time to 1 hour later
    -- Hint: use addtime()

    declare airplane_location VARCHAR(50);
    declare curr_status VARCHAR(100);
    declare curr_next_time TIME;
    declare flight_miles INT;

    select airplane_status, next_time
    into
        curr_status, curr_next_time
    from flight
    where flightId = ip_flightID;

    if curr_status != 'in_flight' then
        leave sp_main;
    end if;

    select a.locationID
    into airplane_location
    from flight f
             join airplane a on f.support_airline = a.airlineID
        and f.support_tail = a.tail_num
    where f.flightID = ip_flightID;

    select l.distance
    into flight_miles
    from flight f
             join route_path rp ON f.routeID = rp.routeID
             join leg l ON rp.legID = l.legID
    where f.flightID = ip_flightID
      and rp.sequence = f.progress;

    update pilot
    set experience = experience + 1
    where commanding_flight = ip_flightID;


    update passenger p
        join person pe on p.personID = pe.personId
    set p.miles = p.miles + flight_miles
    where pe.locationID = airplane_location;

    update flight
    set airplane_status = 'on_ground',
        next_time       = ADDTIME(next_time, '01:00:00')
    where flightID = ip_flightID;


end //
delimiter ;

-- [7] flight_takeoff()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight taking off from its current
airport towards the next airport along it's route.  The time for the next leg of
the flight must be calculated based on the distance and the speed of the airplane.
And we must also ensure that Airbus and general planes have at least one pilot
assigned, while Boeing must have a minimum of two pilots. If the flight cannot take
off because of a pilot shortage, then the flight must be delayed for 30 minutes. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_takeoff;
delimiter //
create procedure flight_takeoff(in ip_flightID varchar(50))
sp_main:
begin

    -- Ensure that the flight exists
    -- Ensure that the flight is on the ground
    -- Ensure that the flight has another leg to fly
    -- Ensure that there are enough pilots (1 for Airbus and general, 2 for Boeing)
    -- If there are not enough, move next time to 30 minutes later

    -- Increment the progress and set the status to in flight
    -- Calculate the flight time using the speed of airplane and distance of leg
    -- Update the next time using the flight time
    
    DECLARE numPilots INT DEFAULT 0;
    DECLARE ip_support_airline varchar(64);
    DECLARE ip_support_tail varchar(64);
    DECLARE ip_speed INT DEFAULT 0;
    DECLARE ip_distance INT DEFAULT 0;
    
    
    IF ip_flightID not in (select flightID from flight) THEN
		LEAVE sp_main;
	END IF;
    
    IF (select airplane_status from flight where flightID = ip_flightID) not like 'on_ground' THEN
		LEAVE sp_main;
	END IF;
    
    select support_airline into ip_support_airline from flight where flightID = ip_flightID;
    select support_tail into ip_support_tail from flight where flightID = ip_flightID;
    
    IF (select progress from flight where flightID = ip_flightID)
    >= (select max(sequence) from route_path group by routeID having
    routeID = (select routeID from flight where flightID = ip_flightID)) THEN
    	LEAVE sp_main;
	END IF;
    
    select count(*) into numPilots from pilot where commanding_flight = ip_flightID;
    
    IF ((select plane_type from airplane
    where ip_support_airline = airlineID
    and ip_support_tail = tail_num) like 'Airbus' and numPilots < 1)
    OR
    ((select plane_type from airplane
    where ip_support_airline = airlineID
    and ip_support_tail = tail_num) like 'Boeing' and numPilots < 2)
    THEN
        UPDATE flight SET next_time = ADDTIME(next_time, '00:30:00') where flightID = ip_flightID;
	END IF;
    
    UPDATE flight SET progress = progress + 1 where flightID = ip_flightID;
    UPDATE flight SET airplane_status = 'in_flight' where flightID = ip_flightID;
    
    SELECT l.distance into ip_distance from flight f
    join route_path rp on f.routeID = rp.routeID
    join leg l on rp.legID = l.legID
    where rp.sequence = f.progress and flightID = ip_flightID;
    
    SELECT speed into ip_speed from
    flight f join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
    where flightID = ip_flightID;
    
    UPDATE flight SET next_time = ADDTIME(next_time, SEC_TO_TIME((ip_distance / ip_speed) * 3600)) where flightID = ip_flightID;
    
end //
delimiter ;

-- [8] passengers_board()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting on a flight at
its current airport.  The passengers must be at the same airport as the flight,
and the flight must be heading towards that passenger's desired destination.
Also, each passenger must have enough funds to cover the flight.  Finally, there
must be enough seats to accommodate all boarding passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_board;
delimiter //
create procedure passengers_board(in ip_flightID varchar(50))
sp_main:
begin

    -- Ensure the flight exists
    -- Ensure that the flight is on the ground
    -- Ensure that the flight has further legs to be flown

    -- Determine the number of passengers attempting to board the flight
    -- Use the following to check:
    -- The airport the airplane is currently located at
    -- The passengers are located at that airport
    -- The passenger's immediate next destination matches that of the flight
    -- The passenger has enough funds to afford the flight

    -- Check if there enough seats for all the passengers
    -- If not, do not add board any passengers
    -- If there are, board them and deduct their funds

    declare flight_count INT;
	declare flight_status VARCHAR(100);
	declare flight_cost INT;
	declare curr_progress INT;
	declare total_route_legs INT;
	declare airplane_loc VARCHAR(50);
	declare seat_capacity INT;
	declare next_dest CHAR(3);
	declare boarding_count INT;
	declare curr_airport CHAR(3);
	declare airport_loc VARCHAR(50);
	declare q_route_id VARCHAR(50);

    -- verify flight exists and can be boarded
    select count(*) into flight_count from flight where flightID = ip_flightID;
    if flight_count != 1 then
        leave sp_main;
    end if;

    select airplane_status, cost, progress, routeID
    into flight_status, flight_cost, curr_progress, q_route_id
    from flight
    where flightID = ip_flightID;

    if flight_status != 'on_ground' then
        leave sp_main;
    end if;

    select max(sequence)
    into total_route_legs
    from route_path
    where routeID = q_route_id;

    if curr_progress >= total_route_legs then
        leave sp_main;
    end if;

    select a.locationID, a.seat_capacity
    into airplane_loc, seat_capacity
    from flight f
             join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
    where f.flightID = ip_flightID;

    -- get the current airport of the airplane
    if curr_progress = 0 then
		select l.departure into curr_airport
		from route_path rp join leg l on rp.legID = l.legID
		where rp.routeID = q_route_id and rp.sequence = 1;
	else
		select l.arrival into curr_airport
		from route_path rp join leg l on rp.legID = l.legID
		where rp.routeID = q_route_id and rp.sequence = curr_progress;
	end if;

	select locationID into airport_loc
	from airport
	where airportID = curr_airport;
    
    -- get the next destination in the route
    select l.arrival
    into next_dest
    from route_path rp
             join leg l on rp.legID = l.legID
    where rp.routeID = q_route_id
      and rp.sequence = curr_progress + 1;

    -- count passengers who want to board and check that they can board
    select count(*)
    into boarding_count
    from person p
             join passenger pa on p.personID = pa.personID
             join (
        select pv.personID, min(pv.sequence) as next_seq
        from passenger_vacations pv
        group by pv.personID
    ) as pv_min on p.personID = pv_min.personID
             join passenger_vacations pv_next on p.personID = pv_next.personID and pv_next.sequence = pv_min.next_seq
    where p.locationID = airport_loc
      and pv_next.airportID = next_dest
      and pa.funds >= flight_cost;

    if boarding_count > seat_capacity then
        leave sp_main;
    end if;

    -- update passenger funds and move them to the airplane
    update passenger pa
        join person p on pa.personID = p.personID
        join (
            select pv.personID, min(pv.sequence) as next_seq
            from passenger_vacations pv
            group by pv.personID
        ) as pv_min on p.personID = pv_min.personID
        join passenger_vacations pv_next on p.personID = pv_next.personID and pv_next.sequence = pv_min.next_seq
    set
        pa.funds = pa.funds - flight_cost,
        p.locationID = airplane_loc
    where p.locationID = airport_loc
      and pv_next.airportID = next_dest
      and pa.funds >= flight_cost;

end //
delimiter ;

-- [9] passengers_disembark()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting off of a flight
at its current airport.  The passengers must be on that flight, and the flight must
be located at the destination airport as referenced by the ticket. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_disembark;
delimiter //
create procedure passengers_disembark(in ip_flightID varchar(50))
sp_main:
begin

    -- Ensure the flight exists
    -- Ensure that the flight is in the air

    -- Determine the list of passengers who are disembarking
    -- Use the following to check:
    -- Passengers must be on the plane supporting the flight
    -- Passenger has reached their immediate next destionation airport

    -- Move the appropriate passengers to the airport
    -- Update the vacation plans of the passengers
    
	DECLARE current_airport CHAR(3);
	DECLARE current_location VARCHAR(50);
	DECLARE plane_location VARCHAR(50);

	IF ip_flightID not in (select flightID from flight) THEN
		LEAVE sp_main;
	END IF;

	IF (select airplane_status from flight where flightID = ip_flightID) != 'on_ground' THEN
		LEAVE sp_main;
	END IF;

	SELECT arrival INTO current_airport
	FROM leg
	WHERE legID = (
		SELECT legID 
		FROM route_path 
		WHERE routeID = (SELECT routeID FROM flight WHERE flightID = ip_flightID)
		AND sequence = (SELECT progress FROM flight WHERE flightID = ip_flightID)
	);

	SELECT locationID INTO current_location 
	FROM airport 
	WHERE airportID = current_airport;

	SELECT locationID INTO plane_location 
	FROM airplane 
	WHERE airlineID = (SELECT support_airline FROM flight WHERE flightID = ip_flightID)
	AND tail_num = (SELECT support_tail FROM flight WHERE flightID = ip_flightID);

	CREATE TEMPORARY TABLE disembarking_passengers AS
	SELECT p.personID, pv.sequence as min_seq
	FROM person p
	JOIN passenger pa ON p.personID = pa.personID
	JOIN passenger_vacations pv ON p.personID = pv.personID
	WHERE p.locationID = plane_location
	AND pv.airportID = current_airport
	AND pv.sequence = (
		SELECT MIN(sequence)
		FROM passenger_vacations
		WHERE personID = p.personID
	);

	UPDATE person
	SET locationID = current_location
	WHERE personID IN (SELECT personID FROM disembarking_passengers);

	DELETE FROM passenger_vacations
	WHERE (personID, sequence) IN (
		SELECT personID, min_seq FROM disembarking_passengers
	);

	UPDATE passenger_vacations pv
	INNER JOIN disembarking_passengers dp ON pv.personID = dp.personID
	SET pv.sequence = pv.sequence - 1
	WHERE pv.sequence > dp.min_seq;

	DROP TEMPORARY TABLE IF EXISTS disembarking_passengers;

end //
delimiter ;

-- [10] assign_pilot()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a pilot as part of the flight crew for a given
flight.  The pilot being assigned must have a license for that type of airplane,
and must be at the same location as the flight.  Also, a pilot can only support
one flight (i.e. one airplane) at a time.  The pilot must be assigned to the flight
and have their location updated for the appropriate airplane. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_pilot;
delimiter //
create procedure assign_pilot(in ip_flightID varchar(50), ip_personID varchar(50))
sp_main:
begin

    -- Ensure the flight exists
    -- Ensure that the flight is on the ground
    -- Ensure that the flight has further legs to be flown

    -- Ensure that the pilot exists and is not already assigned
    -- Ensure that the pilot has the appropriate license
    -- Ensure the pilot is located at the airport of the plane that is supporting the flight

    -- Assign the pilot to the flight and update their location to be on the plane

    declare flight_count INT;
    declare flight_status VARCHAR(100);
    declare curr_progress INT;
    declare total_route_legs INT;
    declare q_route_id VARCHAR(50);
    declare pilot_count INT;
    declare pilot_assigned_count INT;
    declare airplane_loc VARCHAR(50);
    declare airplane_airport_loc VARCHAR(50);
    declare pilot_loc VARCHAR(50);
    declare airplane_type VARCHAR(100);
    declare license_count INT;

    select count(*) into flight_count from flight where flightID = ip_flightID;
    if flight_count != 1 then
        leave sp_main;
    end if;

    select airplane_status, progress, routeID
    into flight_status, curr_progress, q_route_id
    from flight
    where flightID = ip_flightID;

    if flight_status != 'on_ground' then
        leave sp_main;
    end if;

    select max(sequence)
    into total_route_legs
    from route_path
    where routeID = q_route_id;

    if curr_progress >= total_route_legs then
        leave sp_main;
    end if;

    select airplane_type, a.locationID
    into airplane_type, airplane_loc
    from flight f
             join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
    where f.flightID = ip_flightID;

    select a.locationID into airplane_airport_loc
    from airport a
             join leg l on a.airportID = l.departure
             join route_path rp on l.legID = rp.legID
    where rp.routeID = q_route_id
      and rp.sequence = curr_progress;

    select locationID
    into pilot_loc
    from person
    where personID = ip_personID;

    select count(*)
    into pilot_count
    from pilot
    where personID = ip_personID;

    select count(*)
    into pilot_assigned_count
    from pilot
    where commanding_flight = ip_flightID;

    select count(*)
    into license_count
    from pilot_licenses
    where personID = ip_personID
      and license = airplane_type;

    if pilot_count = 0 or pilot_assigned_count > 0 or license_count = 0 then
        leave sp_main;
    end if;

    if pilot_loc != airplane_airport_loc then
        leave sp_main;
    end if;

    update pilot
    set commanding_flight = ip_flightID
    where personID = ip_personID;

    update person
    set locationID = airplane_loc
    where personID = ip_personID;

end //
delimiter ;

-- [11] recycle_crew()
-- -----------------------------------------------------------------------------
/* This stored procedure releases the assignments for a given flight crew.  The
flight must have ended, and all passengers must have disembarked. */
-- -----------------------------------------------------------------------------
drop procedure if exists recycle_crew;
delimiter //
create procedure recycle_crew(in ip_flightID varchar(50))
sp_main:
begin

    -- Ensure that the flight is on the ground
    -- Ensure that the flight does not have any more legs

    -- Ensure that the flight is empty of passengers

    -- Update assignements of all pilots
    -- Move all pilots to the airport the plane of the flight is located at

    declare flight_status varchar(100);
    declare curr_progress int;
    declare total_route_legs int;
    declare airplane_loc varchar(50);
    declare routeId varchar(50);
    declare passengerCount int default 0;

    select airplane_status, progress, routeID
    into flight_status, curr_progress, routeId
    from flight
    where flightID = ip_flightID;

    if flight_status != 'on_ground' then
        leave sp_main;
    end if;

    select max(sequence)
    into total_route_legs
    from route_path
    where routeID = routeId;

    if curr_progress < total_route_legs then
        leave sp_main;
    end if;

    -- check the flight has no passengers
    select a.locationID
    into airplane_loc
    from flight f
             join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
    where f.flightID = ip_flightID;

    select count(*)
    into passengerCount
    from passenger p
             join person pe on p.personID = pe.personID
    where pe.locationID = airplane_loc;

    select a.locationID
    into airplane_loc
    from airport a
             join leg l on a.airportID = l.arrival
             join route_path rp on l.legID = rp.legID
    where rp.routeID = routeId
      and rp.sequence = curr_progress;

    update pilot
    set commanding_flight = NULL
    where commanding_flight = ip_flightID;

    update person
    set locationID = airplane_loc
    where locationID = ip_flightID;
end //
delimiter ;

-- [12] retire_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a flight that has ended from the system.  The
flight must be on the ground, and either be at the start its route, or at the
end of its route.  And the flight must be empty - no pilots or passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists retire_flight;
delimiter //
create procedure retire_flight(in ip_flightID varchar(50))
sp_main:
begin

    -- Ensure that the flight is on the ground
    -- Ensure that the flight does not have any more legs

    -- Ensure that there are no more people on the plane supporting the flight

    -- Remove the flight from the system

    declare flight_status varchar(100);
    declare curr_progress int;
    declare total_route_legs int;
    declare airplane_loc varchar(50);
    declare pilotCount int default 0;
    declare passengerCount int default 0;
    declare routeId varchar(50);

    select airplane_status, progress, routeID
    into flight_status, curr_progress, routeId
    from flight
    where flightID = ip_flightID;

    if flight_status != 'on_ground' then
        leave sp_main;
    end if;

    select max(sequence)
    into total_route_legs
    from route_path
    where routeID = routeId;

    if curr_progress <> 0 and curr_progress <> total_route_legs then
        leave sp_main;
    end if;

    select count(*)
    into pilotCount
    from pilot
    where commanding_flight = ip_flightID;

    if pilotCount > 0 then
        leave sp_main;
    end if;


    select a.locationID
    into airplane_loc
    from flight f
             join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
    where f.flightID = ip_flightID;


    select count(*)
    into passengerCount
    from passenger p
             join person pe on p.personID = pe.personID
    where pe.locationID = airplane_loc;

    if passengerCount > 0 then
        leave sp_main;
    end if;

    delete from flight
    where flightID = ip_flightID;

end //
delimiter ;

-- [13] simulation_cycle()
-- -----------------------------------------------------------------------------
/* This stored procedure executes the next step in the simulation cycle.  The flight
with the smallest next time in chronological order must be identified and selected.
If multiple flights have the same time, then flights that are landing should be
preferred over flights that are taking off.  Similarly, flights with the lowest
identifier in alphabetical order should also be preferred.

If an airplane is in flight and waiting to land, then the flight should be allowed
to land, passengers allowed to disembark, and the time advanced by one hour until
the next takeoff to allow for preparations.

If an airplane is on the ground and waiting to takeoff, then the passengers should
be allowed to board, and the time should be advanced to represent when the airplane
will land at its next location based on the leg distance and airplane speed.

If an airplane is on the ground and has reached the end of its route, then the
flight crew should be recycled to allow rest, and the flight itself should be
retired from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists simulation_cycle;
delimiter //
create procedure simulation_cycle()
sp_main:
begin

    -- Identify the next flight to be processed

    -- If the flight is in the air:
    -- Land the flight and disembark passengers
    -- If it has reached the end:
    -- Recycle crew and retire flight

    -- If the flight is on the ground:
    -- Board passengers and have the plane takeoff

    -- Hint: use the previously created procedures

    declare next_flight_id varchar(50);
    declare flight_status varchar(100);
    declare flight_next_time time;
    declare flight_progress int;
    declare total_route_legs int;
    declare route_id varchar(50);

    -- find the next flight to process, based on smallest next_time
    select flightID, airplane_status, next_time, progress, routeID
    into next_flight_id, flight_status, flight_next_time, flight_progress, route_id
    from flight
    order by next_time, (case when airplane_status = 'landing' then 0 else 1 end), flightID
    limit 1;

    -- if no flights to process, exit the procedure
    if next_flight_id is null then
        leave sp_main;
    end if;

    -- if the flight is in the air and about to land
    if flight_status = 'in_flight' then
        -- ensure the flight is landing at the next stop
        call flight_landing(next_flight_id);

        -- advance the time by 1 hour (as per the requirement)
        update flight
        set next_time = addtime(flight_next_time, '01:00:00')
        where flightID = next_flight_id;

        -- if the flight has reached the end of the route, recycle crew and retire flight
        select max(sequence)
        into total_route_legs
        from route_path
        where routeID = route_id;

        if flight_progress = total_route_legs then
            -- recycle the crew and retire the flight
            call recycle_crew(next_flight_id);
            call retire_flight(next_flight_id);
        end if;
    end if;

    -- if the flight is on the ground and waiting to take off
    if flight_status = 'on_ground' then
        call passengers_board(next_flight_id);
        call flight_takeoff(next_flight_id);
    end if;

end //
delimiter ;


-- [14] flights_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where flights that are currently airborne are located. 
We need to display what airports these flights are departing from, what airports 
they are arriving at, the number of flights that are flying between the 
departure and arrival airport, the list of those flights (ordered by their 
flight IDs), the earliest and latest arrival times for the destinations and the 
list of planes (by their respective flight IDs) flying these flights. */
-- -----------------------------------------------------------------------------
create or replace view flights_in_the_air
            (departing_from, arriving_at, num_flights,
             flight_list, earliest_arrival, latest_arrival, airplane_list)
as
select '_',
       '_',
       '_',
       '_',
       '_',
       '_',
       '_';

-- [15] flights_on_the_ground()
-- ------------------------------------------------------------------------------
/* This view describes where flights that are currently on the ground are 
located. We need to display what airports these flights are departing from, how 
many flights are departing from each airport, the list of flights departing from 
each airport (ordered by their flight IDs), the earliest and latest arrival time 
amongst all of these flights at each airport, and the list of planes (by their 
respective flight IDs) that are departing from each airport.*/
-- ------------------------------------------------------------------------------
create or replace view flights_on_the_ground
            (departing_from, num_flights,
             flight_list, earliest_arrival, latest_arrival, airplane_list)
as
select
    '_',
    '_',
    '_',
    '_',
    '_',
    '_';

-- [16] people_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently airborne are located. We 
need to display what airports these people are departing from, what airports 
they are arriving at, the list of planes (by the location id) flying these 
people, the list of flights these people are on (by flight ID), the earliest 
and latest arrival times of these people, the number of these people that are 
pilots, the number of these people that are passengers, the total number of 
people on the airplane, and the list of these people by their person id. */
-- -----------------------------------------------------------------------------
create or replace view people_in_the_air
            (departing_from, arriving_at, num_airplanes,
             airplane_list, flight_list, earliest_arrival, latest_arrival, num_pilots,
             num_passengers, joint_pilots_passengers, person_list)
as
select '_',
       '_',
       '_',
       '_',
       '_',
       '_',
       '_',
       '_',
       '_',
       '_',
       '_';

-- [17] people_on_the_ground()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently on the ground and in an 
airport are located. We need to display what airports these people are departing 
from by airport id, location id, and airport name, the city and state of these 
airports, the number of these people that are pilots, the number of these people 
that are passengers, the total number people at the airport, and the list of 
these people by their person id. */
-- -----------------------------------------------------------------------------
create or replace view people_on_the_ground
            (departing_from, airport, airport_name,
             city, state, country, num_pilots, num_passengers, joint_pilots_passengers, person_list)
as
select '_',
       '_',
       '_',
       '_',
       '_',
       '_',
       '_',
       '_',
       '_',
       '_';

-- [18] route_summary()
-- -----------------------------------------------------------------------------
/* This view will give a summary of every route. This will include the routeID, 
the number of legs per route, the legs of the route in sequence, the total 
distance of the route, the number of flights on this route, the flightIDs of 
those flights by flight ID, and the sequence of airports visited by the route. */
-- -----------------------------------------------------------------------------
create or replace view route_summary
            (route, num_legs, leg_sequence, route_length,
             num_flights, flight_list, airport_sequence)
as
select '_', '_', '_', '_', '_', '_', '_';

-- [19] alternative_airports()
-- -----------------------------------------------------------------------------
/* This view displays airports that share the same city and state. It should 
specify the city, state, the number of airports shared, and the lists of the 
airport codes and airport names that are shared both by airport ID. */
-- -----------------------------------------------------------------------------
create or replace view alternative_airports
            (city, state, country, num_airports,
             airport_code_list, airport_name_list)
as
select '_', '_', '_', '_', '_', '_';
