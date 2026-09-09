-- ============================================================
-- SQL Full Reset Script: resetdb.sql
-- Project: COP4331 LAMP Stack (Contact Manager)
-- Description: Drops existing tables if present, recreates schema,
--              seeds users and colors, and sets up user permissions.
-- ============================================================

-- Create and select database
CREATE DATABASE IF NOT EXISTS `ContactManagerDB`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE `ContactManagerDB`;

-- Drop existing tables to ensure a clean state
DROP TABLE IF EXISTS `Contacts`;
DROP TABLE IF EXISTS `Users`;

-- Create Users Table
CREATE TABLE `Users` (
    `ID` INT NOT NULL AUTO_INCREMENT,
    `FirstName` VARCHAR(50) NOT NULL DEFAULT '',
    `LastName` VARCHAR(50) NOT NULL DEFAULT '',
    `Login` VARCHAR(50) NOT NULL DEFAULT '',
    `Password` VARCHAR(50) NOT NULL DEFAULT '',
    PRIMARY KEY (`ID`),
    INDEX `idx_users_login` (`Login`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create Contacts Table
CREATE TABLE `Contacts` (
    `ID` INT NOT NULL AUTO_INCREMENT,
    `UserID` INT NOT NULL DEFAULT 0,
    `FirstName` VARCHAR(50) NOT NULL DEFAULT '',
    `LastName` VARCHAR(50) NOT NULL DEFAULT '',
    `Phone` VARCHAR(20),
    `Email` VARCHAR(255),
    PRIMARY KEY (`ID`),
    INDEX `idx_contacts_userid` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed Sample Users
INSERT INTO `Users` (`FirstName`, `LastName`, `Login`, `Password`) VALUES
('Rick', 'Leinecker', 'RickL', 'COP4331'),
('Sam', 'Hill', 'SamH', 'Test'),
('Ezra', 'Neri', 'EzraN', 'COP4331'),
('John', 'Aedo', 'JohnA', 'COP4331');

-- Seed Sample Contacts for User 3 (EzraN)
INSERT INTO `Contacts` (`FirstName`,`LastName`, `UserID`) VALUES
('Graham','Davis', 3),
('Joshua','Sar-Shalom', 3),
('Elier', 'Aguilar', 3),
('Caleb','Kimondo', 3),
('John','Aedo', 3);

-- Seed Sample Contacts for User 4 (JohnA)
INSERT INTO `Contacts` (`FirstName`,`LastName`, `UserID`) VALUES
('Graham','Davis', 4),
('Joshua','Sar-Shalom', 4),
('Elier', 'Aguilar', 4),
('Caleb','Kimondo', 4),
('Ezra','Neri', 4);

-- Create Application Database User & Privileges
CREATE USER IF NOT EXISTS 'ContactManagerUser'@'localhost' IDENTIFIED BY 'WeLoveCOP4331!';
GRANT ALL PRIVILEGES ON `ContactManagerDB`.* TO 'ContactManagerUser'@'localhost';

CREATE USER IF NOT EXISTS 'ContactManagerUser'@'%' IDENTIFIED BY 'WeLoveCOP4331!';
GRANT ALL PRIVILEGES ON `ContactManagerDB`.* TO 'ContactManagerUser'@'%';

FLUSH PRIVILEGES;
