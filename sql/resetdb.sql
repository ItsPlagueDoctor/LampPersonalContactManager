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
INSERT INTO `Users` (`FirstName`, `LastName`, `Login`, `Password`, RoleID) VALUES
('Corey', 'Pittman', 'CoreyP', '$2y$12$HbF.pz64xftezcW3eE9P8e0aSrm9hsfIv0cD6YXVYGRWStePIceoS', (SELECT ID FROM Roles WHERE RoleName = 'User')),
('Application','Administrator', 'root', '$2y$12$1pVoZlAAuBo.OELvC4p6pO07FPTAYeBAZLZKIh7UyKffY.9yweABu', (SELECT ID FROM Roles WHERE RoleName = 'Admin')),
('Graham', 'Davis', 'GrahamD', '$2y$12$6kvKQwOYg2xoNVllnzCK2OYehYax6RfK5qLRophrQZzSTPDL0IBxK', (SELECT ID FROM Roles WHERE RoleName = 'User')),
('Ezra', 'Neri', 'EzraNAdmin', '$2y$12$o/.GD3Ce59rs2maG9Yn2G.bIRtl7LwcbasrJOCnNK.0JRnSE2ovpu', (SELECT ID FROM Roles WHERE RoleName = 'Admin')),
('Elier', 'Aguilar', 'ElierA', '$2y$12$Qs9ROPIz8k0z1GRJRn/Exu16vEdw.rWyeK7MgDM.Z7joMjmLfSiC6', (SELECT ID FROM Roles WHERE RoleName = 'User'));


-- Seed Sample Contacts for User 3 (GrahamD)
INSERT INTO `Contacts` (`FirstName`,`LastName`, `UserID`) VALUES
('Graham','Davis', 3),
('Joshua','Sar-Shalom', 3),
('Elier', 'Aguilar', 3),
('Caleb','Kimondo', 3),
('John','Aedo', 3);

-- Seed Sample Contacts for User 5 (ElierA)
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
