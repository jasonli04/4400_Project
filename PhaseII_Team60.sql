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


