-- ============================================================
-- SQL Full Reset Script: resetdb.sql
-- Project: COP4331 LAMP Stack (Contact Manager)
-- Description: Drops existing tables if present, recreates schema,
--              seeds users and contacts, and sets up user permissions.
-- ============================================================

-- Create and select database
CREATE DATABASE IF NOT EXISTS `ContactsAppDB`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE `ContactsAppDB`;

-- Drop existing tables to ensure a clean state
DROP TABLE IF EXISTS `Contacts`;
DROP TABLE IF EXISTS `Users`;
DROP TABLE IF EXISTS `Roles`;

-- Create Roles Table
CREATE TABLE `Roles` (
    `ID` INT NOT NULL AUTO_INCREMENT,
    `RoleName` VARCHAR(50) NOT NULL,

    PRIMARY KEY (ID),
    UNIQUE (RoleName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create Users Table
CREATE TABLE `Users` (
    `ID` INT NOT NULL AUTO_INCREMENT,
    `FirstName` VARCHAR(50) NOT NULL DEFAULT '',
    `LastName` VARCHAR(50) NOT NULL DEFAULT '',
    `Login` VARCHAR(50) NOT NULL DEFAULT '',
    `Password` VARCHAR(255) NOT NULL DEFAULT '',
    `RoleID` INT NOT NULL,
    `DateCreated` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `DateUpdated` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `IsActive` BOOLEAN NOT NULL DEFAULT TRUE,

    PRIMARY KEY (`ID`),
    INDEX `idx_users_login` (`Login`),

    FOREIGN KEY (RoleID) REFERENCES Roles(ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create Contacts Table
CREATE TABLE `Contacts` (
    `ID` INT NOT NULL AUTO_INCREMENT,
    `UserID` INT NOT NULL,
    `FirstName` VARCHAR(50) NOT NULL DEFAULT '',
    `LastName` VARCHAR(50) NOT NULL DEFAULT '',
    `Phone` VARCHAR(20),
    `Email` VARCHAR(255),
    `DateCreated` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `DateUpdated` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`ID`),
    INDEX `idx_contacts_userid` (`UserID`),
    
    CONSTRAINT `fk_contacts_user`
        FOREIGN KEY (`UserID`) REFERENCES `Users`(`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create Roles
INSERT INTO Roles (RoleName)
VALUES ('Admin'), ('User');

-- Seed Sample Users
-- passwords need to be hashed in future,
-- contact api dev for this later.
INSERT INTO `Users` (`FirstName`, `LastName`, `Login`, `Password`, RoleID) VALUES
('Application','Administrator', 'root', 'COP4331', (SELECT ID FROM Roles WHERE RoleName = 'Admin')),
('Rick', 'Leinecker', 'RickL', 'COP4331', (SELECT ID FROM Roles WHERE RoleName = 'User')),
('Sam', 'Hill', 'SamHAdmin', 'Test', (SELECT ID FROM Roles WHERE RoleName = 'Admin')),
('Ezra', 'Neri', 'EzraNAdmin', 'COP4331', (SELECT ID FROM Roles WHERE RoleName = 'Admin')),
('John', 'Aedo', 'JohnA', 'COP4331', (SELECT ID FROM Roles WHERE RoleName = 'User')),
('Ezra', 'Neri', 'EzraN', 'COP4331', (SELECT ID FROM Roles WHERE RoleName = 'User')),
('Sam', 'Hill', 'SamH', 'COP4331', (SELECT ID FROM Roles WHERE RoleName = 'User'));

-- Seed Sample Contacts for User 6 (EzraN)
INSERT INTO `Contacts` (`FirstName`,`LastName`, `UserID`) VALUES
('Graham','Davis', 6),
('Joshua','Sar-Shalom', 6),
('Elier', 'Aguilar', 6),
('Caleb','Kimondo', 6),
('John','Aedo', 6);

-- Seed Sample Contacts for User 5 (JohnA)
INSERT INTO `Contacts` (`FirstName`,`LastName`, `UserID`) VALUES
('Graham','Davis', 5),
('Joshua','Sar-Shalom', 5),
('Elier', 'Aguilar', 5),
('Caleb','Kimondo', 5),
('Ezra','Neri', 5);

-- Create Application Database User & Privileges
CREATE USER IF NOT EXISTS 'ContactsAppUser'@'localhost' IDENTIFIED BY 'WeLoveCOP4331!';
GRANT ALL PRIVILEGES ON `ContactsAppDB`.* TO 'ContactsAppUser'@'localhost';

CREATE USER IF NOT EXISTS 'ContactsAppUser'@'%' IDENTIFIED BY 'WeLoveCOP4331!';
GRANT ALL PRIVILEGES ON `ContactsAppDB`.* TO 'ContactsAppUser'@'%';

FLUSH PRIVILEGES;
