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
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;
set @thisDatabase = 'airline_management';
drop database if exists airline_management;
create database if not exists airline_management;
use airline_management;

-- Define the database structures
/* You must enter your tables definitions, along with your primary, unique and
foreign key
declarations, and data insertion statements here. You may sequence them in any
order that
works for you. When executed, your statements must create a functional database
that contains
all of the data, and supports as many of the constraints as reasonably possible. */

/*
Location
locID
*/
DROP TABLE IF EXISTS Location;
create table Location
(
    locID varchar(64) NOT NULL,
    check (locID like 'plane_%' or locID like 'port_%'),
    PRIMARY KEY (locID)
);

/*
Airline
airlineID, revenue
*/
DROP TABLE IF EXISTS Airline;
create table Airline
(
    airlineID varchar(32) NOT NULL, -- Assumed max length of airline ID is 32 characters
    revenue   int UNSIGNED NOT NULL,
    PRIMARY KEY (airlineID)
);

/*
Airport
airportID, name, city, state, country, locID [FK7]
FK7: locID → Location(locID)
*/
DROP TABLE IF EXISTS Airport;
create table Airport
(
    airportID    char(3)     NOT NULL,
    airport_name varchar(64) NOT NULL,
    city         varchar(64) NOT NULL,
    state        varchar(64) NOT NULL,
    country      char(3)     NOT NULL,
    locID        varchar(64),
    PRIMARY KEY (airportID),
    FOREIGN KEY (locID) REFERENCES Location (locID) ON UPDATE CASCADE ON DELETE SET NULL
);

/*
Leg
legID, distance, arrivalAirportID [FK11], departureAirportID [FK12]
*/
DROP TABLE IF EXISTS Leg;
create table Leg
(
    legID              varchar(8) NOT NULL,
    distance           int UNSIGNED NOT NULL,
    arrivalAirportID   char(3)    NOT NULL,
    departureAirportID char(3)    NOT NULL,
	check (legID like 'leg_%' and length(legID) > 4), # Assume all legIDs start with 'leg_'
    FOREIGN KEY (arrivalAirportID) REFERENCES Airport (airportID) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (departureAirportID) REFERENCES Airport (airportID) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (legID)
);

/*
Route
routeID
*/
DROP TABLE IF EXISTS Route;
create table Route
(
    routeID varchar(64) NOT NULL,
    PRIMARY KEY (routeID)
);

/*
Contains
legID [FK8], routeID [FK9], sequence
*/
DROP TABLE IF EXISTS RouteLegContains;
create table RouteLegContains
(
    legID    varchar(8)  NOT NULL,
    routeID  varchar(64) NOT NULL,
    FOREIGN KEY (legID) REFERENCES Leg (legID) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (routeID) REFERENCES Route (routeID) ON UPDATE CASCADE ON DELETE CASCADE,
    sequence int UNSIGNED NOT NULL,
    PRIMARY KEY (legID, routeID)
);

/*
Person
personID, first, last, locID [FK13]
*/
DROP TABLE IF EXISTS Person;
create table Person
(
    personID   varchar(8)  NOT NULL,
    first_name varchar(32) NOT NULL,
    last_name  varchar(32) NOT NULL,
    locID      varchar(64) NOT NULL,
    check (personID like 'p%'),
    check (
		first_name regexp '^[A-Za-z]+$' and last_name regexp '^[A-Za-z]+$'
	),
    FOREIGN KEY (locID) REFERENCES Location (locID) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (personID)
);

/*
Flight
flightID, cost, routeID [FK10]
*/
DROP TABLE IF EXISTS Flight;
create table Flight
(
    flightID char(5) NOT NULL,
    cost     int UNSIGNED NOT NULL,
    CHECK (
		flightID REGEXP '^[a-z]{2}_[0-9]{2}$'
	),
    routeID varchar(64) NOT NULL,
    FOREIGN KEY (routeID) REFERENCES Route (routeID) ON UPDATE CASCADE ON DELETE RESTRICT,
    PRIMARY KEY (flightID)
);

/*
Pilot
personID [FK17], taxID, flightID [FK14], experience
*/
DROP TABLE IF EXISTS Pilot;
create table Pilot
(
    taxID      char(11),
    experience int UNSIGNED,
    check (
		taxID IS NULL OR taxID REGEXP '^[0-9]{3}-[0-9]{2}-[0-9]{4}$'
	) ,
    personID   varchar(8)  NOT NULL,
    flightID char(5),
    FOREIGN KEY (personID) REFERENCES Person (personID) ON UPDATE RESTRICT ON DELETE CASCADE,
    FOREIGN KEY (flightID) REFERENCES Flight (flightID) ON UPDATE CASCADE ON DELETE SET NULL,
	PRIMARY KEY (personID)
);

/*
License (multivalued attribute)
licenseID, personID [FK3]
*/
DROP TABLE IF EXISTS License;
create table License
(
    licenseID varchar(32) NOT NULL,
    personID  varchar(8)  NOT NULL,
    FOREIGN KEY (personID) REFERENCES Person (personID) ON UPDATE RESTRICT ON DELETE CASCADE,
    PRIMARY KEY (licenseID, personID)
);

/*
Passenger
personID [FK16], funds, miles
*/
DROP TABLE IF EXISTS Passenger;
create table Passenger
(
    funds    int UNSIGNED NOT NULL,
    miles    int UNSIGNED NOT NULL,
    personID varchar(8) NOT NULL,
    FOREIGN KEY (personID) REFERENCES Person (personID) ON UPDATE RESTRICT ON DELETE CASCADE,
    PRIMARY KEY (personID)
);

/*
Vacation (Multivalued attribute)
vacationID, destination, sequence, personID [FK2]
*/
DROP TABLE IF EXISTS Vacation;
create table Vacation
(
    vacationID  int        UNSIGNED NOT NULL AUTO_INCREMENT,
    destination char(3)    NOT NULL,
    sequence    int 	   UNSIGNED,
    personID    varchar(8) NOT NULL,
    FOREIGN KEY (personID) REFERENCES Person (personID) ON UPDATE RESTRICT ON DELETE CASCADE,
    PRIMARY KEY (vacationID)
);

/*
Airplane
tail_num, airlineID [FK1], seat_cap, speed, locID [FK6], flightID [FK15], progress, status, next_time
*/
DROP TABLE IF EXISTS Airplane;
create table Airplane
(
    tail_num        char(6) NOT NULL,
    seat_cap        int UNSIGNED NOT NULL,
    speed           int UNSIGNED NOT NULL,
    progress        int UNSIGNED,
    airplane_status ENUM ('on_ground', 'in_flight') DEFAULT 'on_ground' NOT NULL,
    next_time       time,
    check (
		tail_num REGEXP '^[n]{1}[0-9]{3}[a-z]{2}$'
	) ,
    airlineID varchar(32) NOT NULL,
    locID varchar(64),
    flightID char(5),
    FOREIGN KEY (airlineID) REFERENCES Airline (airlineID) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (locID) REFERENCES Location (locID) ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (flightID) REFERENCES Flight (flightID) ON UPDATE CASCADE ON DELETE SET NULL,
    PRIMARY KEY (tail_num, airlineID)
);

/*
Airbus
(tail_num, airlineID) [FK4], neo
*/
DROP TABLE IF EXISTS Airbus;
create table Airbus
(
    tail_num  char(6)     NOT NULL,
    airlineID varchar(32) NOT NULL,
    neo       bool        NOT NULL,
	FOREIGN KEY (tail_num, airlineID) REFERENCES Airplane (tail_num, airlineID) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (tail_num, airlineID)
);

/*
Boeing
(tail_num, airlineID) [FK5], model, maintained
*/
DROP TABLE IF EXISTS Boeing;
create table Boeing
(
    model int UNSIGNED NOT NULL,
    check (
		model % 10 = 7 and model between 700 and 799
	),
    maintained bool NOT NULL,
    tail_num        char(6) NOT NULL,
    airlineID varchar(32) NOT NULL,
    FOREIGN KEY (tail_num, airlineID) REFERENCES Airplane (tail_num, airlineID)  ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (tail_num, airlineID)
);

-- Insert Statements
INSERT into Location (locID)
values ('port_1'),
       ('port_2'),
       ('port_3'),
       ('port_10'),
       ('port_17'),
       ('plane_1'),
       ('plane_5'),
       ('plane_8'),
       ('plane_13'),
       ('plane_20'),
       ('port_12'),
       ('port_14'),
       ('port_15'),
       ('port_20'),
       ('port_4'),
       ('port_16'),
       ('port_11'),
       ('port_23'),
       ('port_7'),
       ('port_6'),
       ('port_13'),
       ('port_21'),
       ('port_18'),
       ('port_22'),
       ('plane_6'),
       ('plane_18'),
       ('plane_7'),
       ('plane_2'),
       ('plane_3'),
       ('plane_4'),
       ('port_24'),
       ('plane_10'),
       ('port_25');

INSERT into Airline (airlineID, revenue)
values ('Delta', 53000),
       ('United', 48000),
       ('British Airways', 24000),
       ('Lufthansa', 35000),
       ('Air_France', 29000),
       ('KLM', 29000),
       ('Ryanair', 10000),
       ('Japan Airlines', 9000),
       ('China Southern Airlines', 14000),
       ('Korean Air Lines', 10000),
       ('American', 52000);

INSERT into Airport (airportID, airport_name, city, state, country, locID)
values ('ATL', 'Atlanta Hartsfield_Jackson International', 'Atlanta', 'Georgia',
        'USA', 'port_1'),
       ('DXB', 'Dubai International', 'Dubai', 'Al Garhoud', 'UAE', 'port_2'),
       ('HND', 'Tokyo International Haneda', 'Ota City', 'Tokyo', 'JPN',
        'port_3'),
       ('LHR', 'London Heathrow', 'London', 'England', 'GBR', 'port_4'),
       ('IST', 'Istanbul International', 'Arnavutkoy', 'Istanbul ', 'TUR',
        NULL),
       ('DFW', 'Dallas_Fort Worth International', 'Dallas', 'Texas', 'USA',
        'port_6'),
       ('CAN', 'Guangzhou International', 'Guangzhou', 'Guangdong', 'CHN',
        'port_7'),
       ('DEN', 'Denver International', 'Denver', 'Colorado', 'USA', NULL),
       ('LAX', 'Los Angeles International', 'Los Angeles', 'California', 'USA',
        NULL),
       ('ORD', 'O_Hare International', 'Chicago', 'Illinois', 'USA', 'port_10'),
       ('AMS', 'Amsterdam Schipol International', 'Amsterdam', 'Haarlemmermeer',
        'NLD', 'port_11'),
       ('CDG', 'Paris Charles de Gaulle', 'Roissy_en_France', 'Paris', 'FRA',
        'port_12'),
       ('FRA', 'Frankfurt International', 'Frankfurt', 'Frankfurt_Rhine_Main',
        'DEU', 'port_13'),
       ('MAD', 'Madrid Adolfo Suarez_Barajas', 'Madrid', 'Barajas', 'ESP',
        'port_14'),
       ('BCN', 'Barcelona International', 'Barcelona', 'Catalonia', 'ESP',
        'port_15'),
       ('FCO', 'Rome Fiumicino', 'Fiumicino', 'Lazio', 'ITA', 'port_16'),
       ('LGW', 'London Gatwick', 'London', 'England', 'GBR', 'port_17'),
       ('MUC', 'Munich International', 'Munich', 'Bavaria', 'DEU', 'port_18'),
       ('MDW', 'Chicago Midway International', 'Chicago', 'Illinois', 'USA',
        NULL),
       ('IAH', 'George Bush Intercontinental', 'Houston', 'Texas', 'USA',
        'port_20'),
       ('HOU', 'William P_Hobby International', 'Houston', 'Texas', 'USA',
        'port_21'),
       ('NRT', 'Narita International', 'Narita', 'Chiba', 'JPN', 'port_22'),
       ('BER', 'Berlin Brandenburg Willy Brandt International', 'Berlin',
        'Schonefeld', 'DEU', 'port_23'),
       ('ICN', 'Incheon International Airport', 'Seoul', 'Jung_gu', 'KOR',
        'port_24'),
       ('PVG', 'Shanghai Pudong International Airport', 'Shanghai', 'Pudong',
        'CHN', 'port_25');

INSERT into Leg (legID, distance, departureAirportID, arrivalAirportID)
values ('leg_33', 4400, 'ICN', 'LHR'),
       ('leg_34', 5900, 'ICN', 'LAX'),
       ('leg_35', 3700, 'CDG', 'ORD'),
       ('leg_36', 100, 'NRT', 'HND'),
       ('leg_37', 500, 'PVG', 'ICN'),
       ('leg_38', 6500, 'LAX', 'PVG'),
       ('leg_4', 600, 'ATL', 'ORD'),
       ('leg_2', 3900, 'ATL', 'AMS'),
       ('leg_1', 400, 'AMS', 'BER'),
       ('leg_31', 3700, 'ORD', 'CDG'),
       ('leg_14', 400, 'CDG', 'MUC'),
       ('leg_3', 3700, 'ATL', 'LHR'),
       ('leg_22', 600, 'LHR', 'BER'),
       ('leg_23', 500, 'LHR', 'MUC'),
       ('leg_29', 400, 'MUC', 'FCO'),
       ('leg_16', 800, 'FCO', 'MAD'),
       ('leg_25', 600, 'MAD', 'CDG'),
       ('leg_13', 200, 'CDG', 'LHR'),
       ('leg_5', 500, 'BCN', 'CDG'),
       ('leg_27', 300, 'MUC', 'BER'),
       ('leg_8', 600, 'BER', 'LGW'),
       ('leg_21', 600, 'LGW', 'BER'),
       ('leg_9', 300, 'BER', 'MUC'),
       ('leg_28', 400, 'MUC', 'CDG'),
       ('leg_11', 500, 'CDG', 'BCN'),
       ('leg_6', 300, 'BCN', 'MAD'),
       ('leg_26', 800, 'MAD', 'FCO'),
       ('leg_30', 200, 'MUC', 'FRA'),
       ('leg_17', 300, 'FRA', 'BER'),
       ('leg_7', 4700, 'BER', 'CAN'),
       ('leg_10', 1600, 'CAN', 'HND'),
       ('leg_18', 100, 'HND', 'NRT'),
       ('leg_24', 300, 'MAD', 'BCN'),
       ('leg_12', 600, 'CDG', 'FCO'),
       ('leg_15', 200, 'DFW', 'IAH'),
       ('leg_20', 100, 'IAH', 'HOU'),
       ('leg_19', 300, 'HOU', 'DFW'),
       ('leg_32', 6800, 'DFW', 'ICN');

INSERT into Route (routeID)
values ('americas_hub_exchange'),
       ('americas_one'),
       ('americas_three'),
       ('americas_two'),
       ('big_europe_loop'),
       ('euro_north'),
       ('euro_south'),
       ('germany_local'),
       ('pacific_rim_tour'),
       ('south_euro_loop'),
       ('texas_local'),
       ('korea_direct');

INSERT into RouteLegContains (legID, routeID, sequence)
values ('leg_4', 'americas_hub_exchange', 1),
       ('leg_2', 'americas_one', 1),
       ('leg_1', 'americas_one', 2),
       ('leg_31', 'americas_three', 1),
       ('leg_14', 'americas_three', 2),
       ('leg_3', 'americas_two', 1),
       ('leg_22', 'americas_two', 2),
       ('leg_23', 'big_europe_loop', 1),
       ('leg_29', 'big_europe_loop', 2),
       ('leg_16', 'big_europe_loop', 3),
       ('leg_25', 'big_europe_loop', 4),
       ('leg_13', 'big_europe_loop', 5),
       ('leg_16', 'euro_north', 1),
       ('leg_24', 'euro_north', 2),
       ('leg_5', 'euro_north', 3),
       ('leg_14', 'euro_north', 4),
       ('leg_27', 'euro_north', 5),
       ('leg_8', 'euro_north', 6),
       ('leg_21', 'euro_south', 1),
       ('leg_9', 'euro_south', 2),
       ('leg_28', 'euro_south', 3),
       ('leg_11', 'euro_south', 4),
       ('leg_6', 'euro_south', 5),
       ('leg_26', 'euro_south', 6),
       ('leg_9', 'germany_local', 1),
       ('leg_30', 'germany_local', 2),
       ('leg_17', 'germany_local', 3),
       ('leg_7', 'pacific_rim_tour', 1),
       ('leg_10', 'pacific_rim_tour', 2),
       ('leg_18', 'pacific_rim_tour', 3),
       ('leg_16', 'south_euro_loop', 1),
       ('leg_24', 'south_euro_loop', 2),
       ('leg_5', 'south_euro_loop', 3),
       ('leg_12', 'south_euro_loop', 4),
       ('leg_15', 'texas_local', 1),
       ('leg_20', 'texas_local', 2),
       ('leg_19', 'texas_local', 3),
       ('leg_32', 'korea_direct', 1);

INSERT into Person (personID, first_name, last_name, locID)
values ('p1', 'Jeanne', 'Nelson', 'port_1'),
       ('p2', 'Roxanne', 'Byrd', 'port_1'),
       ('p11', 'Sandra', 'Cruz', 'port_3'),
       ('p13', 'Bryant', 'Figueroa', 'port_3'),
       ('p14', 'Dana', 'Perry', 'port_3'),
       ('p15', 'Matt', 'Hunt', 'port_10'),
       ('p16', 'Edna', 'Brown', 'port_10'),
       ('p12', 'Dan', 'Ball', 'port_3'),
       ('p17', 'Ruby', 'Burgess', 'plane_3'),
       ('p18', 'Esther', 'Pittman', 'plane_10'),
       ('p19', 'Doug', 'Fowler', 'port_17'),
       ('p8', 'Bennie', 'Palmer', 'port_2'),
       ('p20', 'Thomas', 'Olson', 'port_17'),
       ('p21', 'Mona', 'Harrison', 'plane_1'),
       ('p22', 'Arlene', 'Massey', 'plane_1'),
       ('p23', 'Judith', 'Patrick', 'plane_1'),
       ('p24', 'Reginald', 'Rhodes', 'plane_5'),
       ('p25', 'Vincent', 'Garcia', 'plane_5'),
       ('p26', 'Cheryl', 'Moore', 'plane_5'),
       ('p27', 'Michael', 'Rivera', 'plane_8'),
       ('p28', 'Luther', 'Matthews', 'plane_8'),
       ('p29', 'Moses', 'Parks', 'plane_13'),
       ('p3', 'Tanya', 'Nguyen', 'port_1'),
       ('p30', 'Ora', 'Steele', 'plane_13'),
       ('p31', 'Antonio', 'Flores', 'plane_13'),
       ('p32', 'Glenn', 'Ross', 'plane_13'),
       ('p33', 'Irma', 'Thomas', 'plane_20'),
       ('p34', 'Ann', 'Maldonado', 'plane_20'),
       ('p35', 'Jeffrey', 'Cruz', 'port_12'),
       ('p36', 'Sonya', 'Price', 'port_12'),
       ('p37', 'Tracy', 'Hale', 'port_12'),
       ('p38', 'Albert', 'Simmons', 'port_14'),
       ('p39', 'Karen', 'Terry', 'port_15'),
       ('p4', 'Kendra', 'Jacobs', 'port_1'),
       ('p40', 'Glen', 'Kelley', 'port_20'),
       ('p41', 'Brooke', 'Little', 'port_3'),
       ('p42', 'Daryl', 'Nguyen', 'port_4'),
       ('p43', 'Judy', 'Willis', 'port_14'),
       ('p44', 'Marco', 'Klein', 'port_15'),
       ('p45', 'Angelica', 'Hampton', 'port_16'),
       ('p5', 'Jeff', 'Burton', 'port_1'),
       ('p6', 'Randal', 'Parks', 'port_1'),
       ('p10', 'Lawrence', 'Morgan', 'port_3'),
       ('p7', 'Sonya', 'Owens', 'port_2'),
       ('p9', 'Marlene', 'Warner', 'port_3'),
       ('p46', 'Janice', 'White', 'plane_10');

INSERT into Flight (flightID, routeID, cost)
values ('dl_10', 'americas_one', 200),
       ('un_38', 'americas_three', 200),
       ('ba_61', 'americas_two', 200),
       ('lf_20', 'euro_north', 300),
       ('km_16', 'euro_south', 400),
       ('ba_51', 'big_europe_loop', 100),
       ('ja_35', 'pacific_rim_tour', 300),
       ('ry_34', 'germany_local', 100),
       ('aa_12', 'americas_hub_exchange', 150),
       ('dl_42', 'texas_local', 220),
       ('ke_64', 'korea_direct', 500),
       ('lf_67', 'euro_north', 900);

INSERT into Pilot (personID, flightID, taxID, experience)
values ('p1', 'dl_10', '330-12-6907', '31'),
       ('p2', 'dl_10', '842-88-1257', '9'),
       ('p11', 'km_16', '369-22-9505', '22'),
       ('p13', 'km_16', '513-40-4168', '24'),
       ('p14', 'km_16', '454-71-7847', '13'),
       ('p15', 'ja_35', '153-47-8101', '30'),
       ('p16', 'ja_35', '598-47-5172', '28'),
       ('p12', 'ry_34', '680-92-5329', '24'),
       ('p17', 'dl_42', '865-71-6800', '36'),
       ('p18', 'lf_67', '250-86-2784', '23'),
       ('p19', NULL, '386-39-7881', '2'),
       ('p8', 'ry_34', '701-38-2179', '12'),
       ('p20', NULL, '522-44-3098', '28'),
       ('p3', 'un_38', '750-24-7616', '11'),
       ('p4', 'un_38', '776-21-8098', '24'),
       ('p5', 'ba_61', '933-93-2165', '27'),
       ('p6', 'ba_61', '707-84-4555', '38'),
       ('p10', 'lf_20', '769-60-1266', '15'),
       ('p7', 'lf_20', '450-25-5617', '13'),
       ('p9', 'lf_20', '936-44-6941', '13');

INSERT into License (licenseID, personID)
values ('airbus', 'p1'),
       ('airbus', 'p2'),
       ('boeing', 'p2'),
       ('airbus', 'p11'),
       ('boeing', 'p11'),
       ('airbus', 'p13'),
       ('airbus', 'p14'),
       ('airbus', 'p15'),
       ('boeing', 'p15'),
       ('general', 'p15'),
       ('airbus', 'p16'),
       ('boeing', 'p12'),
       ('airbus', 'p17'),
       ('boeing', 'p17'),
       ('airbus', 'p18'),
       ('airbus', 'p19'),
       ('boeing', 'p8'),
       ('airbus', 'p20'),
       ('airbus', 'p3'),
       ('airbus', 'p4'),
       ('boeing', 'p4'),
       ('airbus', 'p5'),
       ('airbus', 'p6'),
       ('boeing', 'p6'),
       ('airbus', 'p10'),
       ('airbus', 'p7'),
       ('airbus', 'p9'),
       ('boeing', 'p9'),
       ('general', 'p9');

INSERT into Passenger (personID, funds, miles)
values ('p21', 700, 771),
       ('p22', 200, 374),
       ('p23', 400, 414),
       ('p24', 500, 292),
       ('p25', 300, 390),
       ('p26', 600, 302),
       ('p27', 400, 470),
       ('p28', 400, 208),
       ('p29', 700, 292),
       ('p30', 500, 686),
       ('p31', 400, 547),
       ('p32', 500, 257),
       ('p33', 600, 564),
       ('p34', 200, 211),
       ('p35', 500, 233),
       ('p36', 400, 293),
       ('p37', 700, 552),
       ('p38', 700, 812),
       ('p39', 400, 541),
       ('p40', 700, 441),
       ('p41', 300, 875),
       ('p42', 500, 691),
       ('p43', 300, 572),
       ('p44', 500, 572),
       ('p45', 500, 663),
       ('p46', 5000, 690);

INSERT into Vacation (destination, personID, sequence)
values ('AMS', 'p21', 1),
       ('AMS', 'p22', 1),
       ('BER', 'p23', 1),
       ('MUC', 'p24', 1),
       ('CDG', 'p24', 2),
       ('MUC', 'p25', 1),
       ('MUC', 'p26', 1),
       ('BER', 'p27', 1),
       ('LGW', 'p28', 1),
       ('FCO', 'p29', 1),
       ('LHR', 'p29', 2),
       ('FCO', 'p30', 1),
       ('MAD', 'p30', 2),
       ('FCO', 'p31', 1),
       ('FCO', 'p32', 1),
       ('CAN', 'p33', 1),
       ('HND', 'p34', 1),
       ('LGW', 'p35', 1),
       ('FCO', 'p36', 1),
       ('FCO', 'p37', 1),
       ('LGW', 'p37', 2),
       ('CDG', 'p37', 3),
       ('MUC', 'p38', 1),
       ('MUC', 'p39', 1),
       ('HND', 'p40', 1),
       ('LGW', 'p46', 1);

INSERT into Airplane (tail_num, airlineID, seat_cap, speed, progress,
                      airplane_status, next_time, locID, flightID)
values ('n106js', 'Delta', 4, 800, 1, 'in_flight', '8:00:00', 'plane_1',
        'dl_10'),
       ('n110jn', 'Delta', 5, 800, 0, 'on_ground', '13:45:00', 'plane_3',
        'dl_42'),
       ('n127js', 'Delta', 4, 600, NULL, 'on_ground', NULL, NULL, NULL),
       ('n330ss', 'United', 4, 800, NULL, 'on_ground', NULL, NULL, NULL),
       ('n380sd', 'United', 5, 400, 2, 'in_flight', '14:30:00', 'plane_5',
        'un_38'),
       ('n616lt', 'British Airways', 7, 600, 0, 'on_ground', '9:30:00',
        'plane_6', 'ba_61'),
       ('n517ly', 'British Airways', 4, 600, 0, 'on_ground', '11:30:00',
        'plane_7', 'ba_51'),
       ('n620la', 'Lufthansa', 4, 800, 3, 'in_flight', '11:00:00', 'plane_8',
        'lf_20'),
       ('n401fj', 'Lufthansa', 4, 300, NULL, 'on_ground', NULL, NULL, NULL),
       ('n653fk', 'Lufthansa', 6, 600, 6, 'on_ground', '21:23:00', 'plane_10',
        'lf_67'),
       ('n118fm', 'Air_France', 4, 400, NULL, 'on_ground', NULL, NULL, NULL),
       ('n815pw', 'Air_France', 3, 400, NULL, 'on_ground', NULL, NULL, NULL),
       ('n161fk', 'KLM', 4, 600, 6, 'in_flight', '14:00:00', 'plane_13',
        'km_16'),
       ('n337as', 'KLM', 5, 400, NULL, 'on_ground', NULL, NULL, NULL),
       ('n256ap', 'KLM', 4, 300, NULL, 'on_ground', NULL, NULL, NULL),
       ('n156sq', 'Ryanair', 8, 600, NULL, 'on_ground', NULL, NULL, NULL),
       ('n451fi', 'Ryanair', 5, 600, NULL, 'on_ground', NULL, NULL, NULL),
       ('n341eb', 'Ryanair', 4, 400, 0, 'on_ground', '15:00:00', 'plane_18',
        'ry_34'),
       ('n353kz', 'Ryanair', 4, 400, NULL, 'on_ground', NULL, NULL, NULL),
       ('n305fv', 'Japan Airlines', 6, 400, 1, 'in_flight', '9:30:00',
        'plane_20', 'ja_35'),
       ('n443wu', 'Japan Airlines', 4, 800, NULL, 'on_ground', NULL, NULL,
        NULL),
       ('n454gq', 'China Southern Airlines', 3, 400, NULL, 'on_ground', NULL,
        NULL, NULL),
       ('n249yk', 'China Southern Airlines', 4, 400, NULL, 'on_ground', NULL,
        NULL, NULL),
       ('n180co', 'Korean Air Lines', 5, 600, 0, 'on_ground', '16:00:00',
        'plane_4', 'ke_64'),
       ('n448cs', 'American', 4, 400, NULL, 'on_ground', NULL, NULL, NULL),
       ('n225sb', 'American', 8, 800, NULL, 'on_ground', NULL, NULL, NULL),
       ('n553qn', 'American', 5, 800, 1, 'on_ground', '12:15:00', 'plane_2',
        'aa_12');

INSERT into Airbus (tail_num, airlineID, neo)
values ('n106js', 'Delta', FALSE),
       ('n110jn', 'Delta', FALSE),
       ('n127js', 'Delta', TRUE),
       ('n330ss', 'United', FALSE),
       ('n380sd', 'United', FALSE),
       ('n616lt', 'British Airways', FALSE),
       ('n517ly', 'British Airways', FALSE),
       ('n620la', 'Lufthansa', TRUE),
       ('n653fk', 'Lufthansa', FALSE),
       ('n815pw', 'Air_France', FALSE),
       ('n161fk', 'KLM', TRUE),
       ('n337as', 'KLM', FALSE),
       ('n156sq', 'Ryanair', FALSE),
       ('n451fi', 'Ryanair', TRUE),
       ('n305fv', 'Japan Airlines', FALSE),
       ('n443wu', 'Japan Airlines', TRUE),
       ('n180co', 'Korean Air Lines', FALSE),
       ('n225sb', 'American', FALSE),
       ('n553qn', 'American', FALSE);

INSERT into Boeing (tail_num, airlineID, model, maintained)
values ('n118fm', 'Air_France', 777, FALSE),
       ('n256ap', 'KLM', 737, FALSE),
       ('n341eb', 'Ryanair', 737, TRUE),
       ('n353kz', 'Ryanair', 737, TRUE),
       ('n249yk', 'China Southern Airlines', 787, FALSE),
       ('n448cs', 'American', 787, TRUE);



