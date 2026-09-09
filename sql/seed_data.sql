-- ============================================================
-- SQL Seed Script: seed_data.sql
-- Project: COP4331 LAMP Stack (Contact Manager)
-- Description: Populates ContactManagerDB with initial Users & Contacts.
-- ============================================================

USE `ContactManagerDB`;

-- Seed Sample Users
INSERT INTO `Users` (`FirstName`, `LastName`, `Login`, `Password`) VALUES
('Rick', 'Leinecker', 'RickL', 'COP4331'),
('Sam', 'Hill', 'SamH', 'Test'),
('Ezra', 'Neri', 'EzraN', 'COP4331'),
('John', 'Aedo', 'JohnA', 'COP4331');

-- Seed Sample Colors for User 3 (EzraN)
INSERT INTO `Contacts` (`FirstName`,`LastName`, `UserID`) VALUES
('Graham','Davis', 1),
('Joshua','Sar-Shalom', 1),
('Elier', 'Aguilar', 1),
('Caleb','Kimondo' 1),
('John','Aedo' 1);

-- Seed Sample Colors for User 4 (JohnA)
INSERT INTO `Colors` (`FirstName`,`LastName`, `UserID`) VALUES
('Graham','Davis', 1),
('Joshua','Sar-Shalom', 1),
('Elier', 'Aguilar', 1),
('Caleb','Kimondo' 1),
('Ezra','Neri' 1);
