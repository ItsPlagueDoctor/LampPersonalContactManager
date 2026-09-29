-- ============================================================
-- SQL Schema Script: create_tables.sql
-- Project: COP4331 LAMP Stack (Contact Manager)
-- Description: Creates the ContactsAppDB database, Users table,
--              Contacts table, and grants user permissions.
-- ============================================================

-- 1. Create and select the database
CREATE DATABASE IF NOT EXISTS `ContactsAppDB`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE `ContactsAppDB`;

--- Create Roles Table
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

-- 4. Create Application Database User & Grant Permissions
-- Note: Replace password if desired for custom deployments.
CREATE USER IF NOT EXISTS 'ContactsAppUser'@'localhost' IDENTIFIED BY 'WeLoveCOP4331!';
GRANT ALL PRIVILEGES ON `ContactsAppDB`.* TO 'ContactsAppUser'@'localhost';

-- Also allow connection from any host (useful for Docker containerization)
CREATE USER IF NOT EXISTS 'ContactsAppUser'@'%' IDENTIFIED BY 'WeLoveCOP4331!';
GRANT ALL PRIVILEGES ON `ContactsAppDB`.* TO 'ContactsAppUser'@'%';

FLUSH PRIVILEGES;
