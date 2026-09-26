-- ============================================================
-- SQL Seed Script: seed_data.sql
-- Project: COP4331 LAMP Stack (Contact Manager)
-- Description: Populates ContactManagerDB with initial Users & Contacts.
-- ============================================================

USE `ContactManagerDB`;

-- Seed Sample Users
INSERT INTO `Users` (`FirstName`, `LastName`, `Login`, `Password`, RoleID) VALUES
('Corey', 'Pittman', 'CoreyP', '$2y$12$HbF.pz64xftezcW3eE9P8e0aSrm9hsfIv0cD6YXVYGRWStePIceoS', (SELECT ID FROM Roles WHERE RoleName = 'User'));
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