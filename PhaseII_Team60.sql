-- CS4400: Introduction to Database Systems (Spring 2025)
-- Phase II: Create Table & Insert Statements [v0] Monday, February 3, 2025 @ 17:00 EST
-- Team 60
-- Keerthi Kaashyap (kkaashyap3)
-- Jason Li (jli3317)
-- Anish Lodh (alodh3)
-- Aidan Wu (awu359)
-- Directions:
-- Please follow all instructions for Phase II as listed on Canvas.
-- Fill in the team number and names and GT usernames for all members above.
-- Create Table statements must be manually written, not taken from an SQL Dump file.
-- This file must run without error for credit.
/* This is a standard preamble for most of our scripts. The intent is to establish
a consistent environment for the database behavior. */
set
global transaction isolation level serializable;
set
global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set
SQL_SAFE_UPDATES = 0;
set
@thisDatabase = 'airline_management';
drop
database if exists airline_management;
create
database if not exists airline_management;
use
airline_management;
-- Define the database structures
/* You must enter your tables definitions, along with your primary, unique and
foreign key
declarations, and data insertion statements here. You may sequence them in any
order that
works for you. When executed, your statements must create a functional database
that contains
all of the data, and supports as many of the constraints as reasonably possible. */

/*
Airline
airlineID, revenue
*/
create table Airline
(
    revenue   int UNSIGNED NOT NULL,
    airlineID varchar(32) NOT NULL, -- Assumed max length of airline ID is 32 characters
    PRIMARY KEY (airlineID)
);

/*
Airport
airportID, name, city, state, country, locID [FK7]
FK7: locID → Location(locID)
*/
create table Airport
(
    airportID    char(3)     NOT NULL,
    airport_name varchar(64) NOT NULL,
    city         varchar(64) NOT NULL,
    state        varchar(64) NOT NULL,
    country      varchar(64) NOT NULL,
    PRIMARY KEY (airportID),
    FOREIGN KEY (locID) REFERENCES Location (locID) ON UPDATE CASCADE ON DELETE SET NULL
);

/*
Leg
legID, distance, arrivalAirportID [FK11], departureAirportID [FK12]
*/
create table Leg
(
    legID    varchar(8) NOT NULL,
    distance int UNSIGNED NOT NULL,
    FOREIGN KEY (arrivalAirportID) REFERENCES Airport (airportID) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (departureAirportID) REFERENCES Airport (airportID) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (legID),
    check (legID like 'leg_%' and length(legID) > 4) # Assume all legIDs start with 'leg_'
);

/*
Route
routeID
*/
create table Route
(
    routeID varchar(64) NOT NULL,
    PRIMARY KEY (routeID)
);

/*
Person
personID, first, last, locID [FK13]
*/
create table Person
(
    personID   varchar(8)  NOT NULL,
    first_name varchar(32) NOT NULL,
    last_name  varchar(32) NOT NULL,
    FOREIGN KEY (locID) REFERENCES Location (locID) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (personID),
    check (personID like 'p%'),
    check (first_name regexp '^[A-Za-z]+$' and last_name regexp '^[A-Za-z]+$'
)
    );

/*
Pilot
personID [FK17], taxID, flightID [FK14], experience
*/
create table Pilot
(
    taxID      char(11),
    experience int UNSIGNED,
    check (taxID IS NULL OR taxID REGEXP '^[0-9]{3}-[0-9]{2}-[0-9]{4}$'
) ,
    FOREIGN KEY (personID) REFERENCES Person (personID) ON UPDATE RESTRICT ON DELETE CASCADE,
    FOREIGN KEY (flightID) REFERENCES Flight (flightID) ON UPDATE CASCADE ON DELETE SET NULL,
	PRIMARY KEY (personID)
);

/*
License (multivalued attribute)
licenseID, personID [FK3]
*/
create table License
(
    licenseID varchar(32) NOT NULL,
    FOREIGN KEY (personID) REFERENCES Person (personID) ON UPDATE RESTRICT ON DELETE CASCADE,
    PRIMARY KEY (licenseID, personID)
);

/*
Passenger
personID [FK16], funds, miles
*/
create table Passenger
(
    funds int UNSIGNED NOT NULL,
    miles int UNSIGNED NOT NULL,
    FOREIGN KEY (personID) REFERENCES Person (personID) ON UPDATE RESTRICT ON DELETE CASCADE,
    PRIMARY KEY (personID)
);

/*
Vacation (Multivalued attribute)
vacationID, personID [FK2], destination, sequence
*/
create table Vacation
(
    vacationID  int UNSIGNED NOT NULL,
    destination char(3),
    sequence    int UNSIGNED,
    FOREIGN KEY (personID) REFERENCES Person (personID) ON UPDATE RESTRICT ON DELETE CASCADE,
    PRIMARY KEY (vacationID, personID)
);

/*
Location
locID
*/
create table Location
(
    locID varchar(64) NOT NULL,
    check (locID like 'plane_%' or locID like 'port_%'),
    PRIMARY KEY (locID)
);

/*
Airplane
tail_num, airlineID [FK1], seat_cap, speed, locID [FK6], flightID [FK15], progress, status, next_time
*/
create table Airplane
(
    tail_num        char(6) NOT NULL,
    seat_cap        int UNSIGNED NOT NULL,
    speed           int UNSIGNED NOT NULL,
    progress        int UNSIGNED NOT NULL,
    airplane_status ENUM ('on_ground', 'in_flight') NOT NULL,
    next_time       time    NOT NULL,
    check (tail_num REGEXP '^[n]{1}[0-9]{3}[a-z]{2}$'
) ,
    FOREIGN KEY (airlineID) REFERENCES Airline (airlineID) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (locID) REFERENCES Location (locID) ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (flightID) REFERENCES Flight (flightID) ON UPDATE CASCADE ON DELETE SET NULL,
    PRIMARY KEY (tail_num, airlineID)
);

/*
Airbus
(tail_num, airlineID) [FK4], variant
*/
create table Airbus
(
    neo bool NOT NULL,
    FOREIGN KEY (tail_num, airlineID) REFERENCES Airplane (tail_num, airlineID) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (tail_num, airlineID)
);

/*
Boeing
(tail_num, airlineID) [FK5], model, maintained
*/
create table Boeing
(
    model int UNSIGNED NOT NULL,
    check (model % 10 = 7 and model between 700 and 799
) ,
    maintained bool NOT NULL,
    FOREIGN KEY (tail_num, airlineID) REFERENCES Airplane (tail_num, airlineID)  ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (tail_num, airlineID)
);

/*
Flight
flightID, cost, routeID [FK10]
*/
create table Flight
(
    flightID char(5) NOT NULL,
    cost     int UNSIGNED NOT NULL,
    CHECK (flightID = taxID REGEXP '^[a-z]{2}_[0-9]{2}$'
) ,
    FOREIGN KEY (routeID) REFERENCES Route (routeID) ON UPDATE CASCADE ON DELETE RESTRICT,
    PRIMARY KEY (flightID)
);

/*
Contains
legID [FK8], routeID [FK9], sequence
*/
create table RouteLegContains
(
    sequence int UNSIGNED NOT NULL,
    FOREIGN KEY (routeID) REFERENCES Route (routeID) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (legID) REFERENCES Leg (legID) ON UPDATE CASCADE ON DELETE RESTRICT,
    PRIMARY KEY (legID, routeID)
);