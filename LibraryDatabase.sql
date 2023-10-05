
--Creating the Library Database
CREATE DATABASE LibraryDatabase

USE LibraryDatabase;
 GO

   
 -- Creating Member table
CREATE TABLE Members (
MemberID INT PRIMARY KEY IDENTITY(1,1),
FirstName NVARCHAR(50) NOT NULL,
LastName NVARCHAR(50) NOT NULL,
DateOfBirth DATE NOT NULL,
Email NVARCHAR(100) UNIQUE NULL,
Address NVARCHAR(100) NOT NULL,
PhoneNumber NVARCHAR(20) NULL,
StartDate DATE NOT NULL,
EndDate DATE NULL,
Username NVARCHAR(50) NOT NULL,
Password NVARCHAR(50) NOT NULL
);

-- Creating Items table
CREATE TABLE Items (
ItemID INT PRIMARY KEY IDENTITY(1,1),
ItemTitle NVARCHAR(100) NOT NULL,
ItemType INT NOT NULL,
Author NVARCHAR NOT NULL,
YearOfPublication INT NOT NULL,
DateAdded DATE NOT NULL,
CurrentStatus NVARCHAR(50),
ISBN NVARCHAR(20),
);

-- Creating Loans table
CREATE TABLE Loan (
LoanID INT PRIMARY KEY IDENTITY(1,1),
MemberID INT NOT NULL,
ItemID INT NOT NULL,
LoanDate DATE NOT NULL,
DueDate DATE NOT NULL,
ReturnDate DATE NULL,
CONSTRAINT FK_MemberID FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
CONSTRAINT FK_ItemID FOREIGN KEY (ItemID) REFERENCES Items(ItemID)
);

--Creating OverdueFines table
CREATE TABLE OverdueFines (
FineID INT PRIMARY KEY IDENTITY(1,1),
MemberID INT NOT NULL,
AmountOwed DECIMAL(10, 2) DEFAULT 0,
AmountRepaid DECIMAL(10, 2) DEFAULT 0, 
OutstandingBalance DECIMAL(10, 2) DEFAULT 0,
CONSTRAINT FK_MemberID_2 FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);

CREATE TABLE Repayments (
RepaymentID INT PRIMARY KEY IDENTITY(1,1),
FineID INT,
RepaymentDate DATE,
RepaymentAmount DECIMAL (10, 2),
RepaymentMethod NVARCHAR(50),
CONSTRAINT FK_FineID FOREIGN KEY (FineID) REFERENCES OverdueFines(FineID)
);

--Creating procedure for inserting new members
CREATE PROCEDURE InsertNewMember
@firstName NVARCHAR(50),
@lastName NVARCHAR(50),
@address NVARCHAR(100),
@dateOfBirth DATE,
@email NVARCHAR(50),
@phoneNumber NVARCHAR(20),
@username NVARCHAR(50),
@password NVARCHAR (50),
@startDate DATE,
@endDate DATE
AS
BEGIN TRANSACTION
BEGIN TRY
				--Insert member details
		INSERT INTO Member (FirstName, LastName, Address, DateOfBirth, Email, PhoneNumber,Username, Password, StartDate, EndDate)
		VALUES (@firstName, @lastName, @address, @dateOfBirth, @email, @phoneNumber, @username, @password, @startDate, @endDate)
		COMMIT TRANSACTION
END TRY
BEGIN CATCH
		--Looks like there was an error!
		IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
		DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
		SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity =
		ERROR_SEVERITY()
		RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH;

--Creating procedure for updated item status
CREATE PROCEDURE UpdatedItemStatus
@ItemID INT,
@NewStatus NVARCHAR(50)
AS
BEGIN TRANSACTION
BEGIN TRY
		UPDATE Items SET CurrentStatus = @NewStatus 
		WHERE ItemID = @ItemID
		COMMIT TRANSACTION
END TRY
BEGIN CATCH
				--Looks like there was an error!
		IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
		DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
		SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity =
		ERROR_SEVERITY()
		RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH;


--Creating procedure to calculateOverdueFines
CREATE PROCEDURE CalculateOverdueFines
AS
BEGIN TRANSACTION
BEGIN TRY
		UPDATE OverdueFines 
		SET AmountOwed = DATEDIFF(day, Loans.DueDate, GETDATE()) * 0.10
		FROM OverdueFines
		INNER JOIN Loans ON OverdueFines.MemberID = Loans.MemberID
		WHERE Loans.ReturnDtae IS NULL AND Loans.DueDate < GETDATE()
		COMMIT TRANSACTION
END TRY
BEGIN CATCH
				--Looks like there was an error!
		IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
		DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
		SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity =
		ERROR_SEVERITY()
		RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH;

--Creating procedure to generate loan report
CREATE PROCEDURE GenerateLoanReport
AS
BEGIN TRANSACTION
BEGIN TRY
		SELECT Members.FirstName, Members.LastName, Items.ItemTitle, Loans.LoanDate,
		Loans.DueDate, Loans.ReturnDate, Loans.LoanDate - Loans.DueDate AS DaysLate
		FROM Members
        INNER JOIN Loans ON Members.MemberID = Loans.MemeberID
		INNER JOIN Items ON Loans.ItemID = Items.ItemID
		COMMIT TRANSACTION
END TRY
BEGIN CATCH
				--Looks like there was an error!
		IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
		DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
		SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity =
		ERROR_SEVERITY()
		RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH;


--Create or alter function for getting items on loan with due date less than 5 days
CREATE  OR ALTER FUNCTION GetItemsOnLoanWithDueDateLessThan5Days()
RETURNS TABLE 
AS
RETURN (
		SELECT Items.ItemID, Items.ItemTitle, Loan.MemberID, Loan.DueDate
		FROM Items
		INNER JOIN Loan ON Items.ItemID = Loan.ItemID
		WHERE Loan.ReturnDate IS NOT NULL AND Loan.DueDate < DATEADD(DAY, 5, GETDATE())
);

--Creating procedure for catalogue search by title
CREATE PROCEDURE SearchCatalogueByTitle
@title NVARCHAR(100)
AS
BEGIN TRANSACTION
BEGIN TRY
		SELECT ItemID, Title, AuthorFirstName, AuthorLastName, YearOfPublication, ItemTypeDescription
		FROM Item
		INNER JOIN Author ON Item.AuthorID = Author.AuthorID
		INNER JOIN ItemType ON Item.ItemTypeID = ItemType.ItemTypeID
		WHERE Title LIKE '%' + @title + '%'
		ORDER BY YearOfPublication DESC
		COMMIT TRANSACTION
END TRY
BEGIN CATCH
		--Looks like there was an error!
		IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
		DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
		SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity =
		ERROR_SEVERITY()
		RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH;


--Creating procedure for membership details update
CREATE PROCEDURE UpdateMemberDetails
@memberID INT,
@firstName NVARCHAR(50),
@lastName NVARCHAR(50),
@dateOfBirth DATE,
@email NVARCHAR(50),
@phoneNumber NVARCHAR(20),
@startDate DATE,
@endDate DATE,
@addressID INT,
@addressLine1 VARCHAR(50),
@addressLine2 VARCHAR(50),
@city VARCHAR(50),
@stateProvince VARCHAR(50),
@postalCode VARCHAR(50),
@country VARCHAR(50)
AS
BEGIN TRANSACTION
BEGIN TRY
		--update member details
		UPDATE Member
		SET FirstName = @firstName,
		LastName = @lastName,
		DateOfBirth = @dateOfBirth,
		Email = @email,
		PhoneNumber = @phoneNumber,
		StartDate = @startDate,
		EndDate = @endDate
		WHERE MemberID = @memberID
		--update address details
		UPDATE Address
		SET
		MemberID = @memberID,
		AddressLine1 = @addressLine1,
		AddressLine2 = @addressLine2,
		City = @city,
		StateProvince = @stateProvince,
		PostalCode = @postalCode,
		Country = @country
		WHERE AddressID = @addressID
		COMMIT TRANSACTION
END TRY
BEGIN CATCH
		--Looks like there was an error!
		IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
		DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
		SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity =
		ERROR_SEVERITY()
		RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH;

--Create or alter function for getting items on loan with due date less than 5 days
CREATE  OR ALTER FUNCTION GetItemsOnLoanWithDueDateLessThan5Days()
RETURNS TABLE 
AS
RETURN (
		SELECT Item.ItemID, Item.Title, Loan.MemberID, Loan.DueDate
		FROM Item
		INNER JOIN Loan ON Item.ItemID = Loan.ItemID
		WHERE Loan.ReturnDate IS NOT NULL AND Loan.DueDate < DATEADD(DAY, 5, GETDATE())
);

--Creating a view for loan history
CREATE VIEW LoanHistory AS
SELECT 
  Loan.LoanID,
  Member.FirstName + ' ' + Member.LastName AS MemberName,
  Item.Title AS ItemTitle,
  Loan.LoanDate,
  Loan.DueDate,
  Loan.ReturnDate,
  Fines.TotalFines,
  Fines.RepaidFines,
  Fines.OutstandingFines
FROM 
  Loan
  INNER JOIN Member ON Loan.MemberID = Member.MemberID
  INNER JOIN Item ON Loan.ItemID = Item.ItemID
  LEFT JOIN Fines ON Loan.LoanID = Fines.LoanID;

 --Creating a trigger for overdue status update
 CREATE TRIGGER UpdateStatusToOverdue
ON Loan
FOR UPDATE
AS
BEGIN
IF UPDATE(ReturnDate) -- Check if ReturnDate has been updated
BEGIN
UPDATE Status
SET Status = 'Overdue'
FROM inserted i -- the updated row(s)
INNER JOIN Loan l ON l.LoanID = i.LoanID
INNER JOIN Status s ON s.ItemID = l.ItemID
WHERE l.DueDate < i.ReturnDate -- Check if item is overdue
AND s.Status != 'Lost or Removed' -- Check if item is not already lost or removed
END
END;

-- Inserting sample data into Member table
INSERT INTO Member (FirstName, LastName, DateOfBirth, Gender, Email, PhoneNumber, StartDate, EndDate)
VALUES ('John', 'Doe', '1990-01-01', 'male', 'johndoe@example.com', '12345678910', '2023-04-10', NULL),
('Jane', 'Doe', '1995-02-15', 'female', 'janedoe@example.com', '13345678910', '2022-08-10', '2023-01-01'),
('Alex', 'Cole', '1991-01-01', 'male', 'alexcole@example.com','44245678910', '2023-02-10', NULL),
('Kate', 'Cole', '1996-02-15', 'female', 'katecole@example.com', '12445678910', '2022-09-10', '2023-01-01');

-- Inserting sample data into Address table
INSERT INTO Address (MemberID, AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country)
VALUES (3, '123 Maine St', NULL, 'Thistown', 'CA', '12345', 'USA'),
(4, '456 Olk St', 'Apt 6B', 'Whichtown', 'NY', '57790', 'USA'),
(5, '64 Eccles New Road', NULL, 'Salford', 'Greater Manchester', 'M5 4WT', 'United Kingdom'),
(6, '3 Greenside St', 'Openshaw', 'Manchester', 'Greater Manchester', 'M11 2FZ', 'United Kingdom');

-- Inserting sample data into Login table
INSERT INTO Login (MemberID, Username, Password, LastLoginDate)
VALUES (3, 'johndoe', 'password123', '2023-04-20 10:00:00'),
(4, 'janedoe', 'abc123', NULL),
(5, 'alexcole', 'password234', '2023-04-21 10:00:00'),
(6, 'katecole', 'abc234', NULL);

-- Inserting sample data into Author table
INSERT INTO Author (AuthorFirstName, AuthorLastName)
VALUES ('Stephen', 'King'),
('J.K.', 'Rowling'),
('Barack', 'Obama'),
('Donal', 'Trump');

-- Inserting sample data into ItemType table
INSERT INTO ItemType (ItemTypeDescription)
VALUES ('Book'),
('DVD');

-- Inserting sample data into Item table
INSERT INTO Item (Title, AuthorID, ItemTypeID, YearOfPublication, ISBN)
VALUES ('The Shining', 1, 1, 1977, '9780385121675'),
('Harry Potter and the Philosopher''s Stone', 2, 1, 1997, '9780747532743'),
('The Shawshank Redemption', 1, 2, 1994, NULL),
('We Will Win', 3, 1, 1977, '8780385121675'),
('Take Your Country Back', 4, 1, 1998, '8780747532743'),
('We Reign', 3, 2, 1995, NULL);

-- Inserting sample data into Status table
INSERT INTO Status (ItemID, Status, DateAdded, LostOrRemovedDate)
VALUES (1, 'Available', '2023-04-20', NULL),
(2, 'Checked Out', '2023-04-20', NULL),
(3, 'Lost', '2022-06-01', '2022-08-01'),
(4, 'Available', '2023-04-21', NULL),
(5, 'Checked Out', '2023-04-21', NULL),
(6, 'Lost', '2022-06-02', '2022-08-02');

-- Inserting sample data into Loan table
INSERT INTO Loan (MemberID, ItemID, LoanDate, DueDate, ReturnDate)
VALUES (3, 2, '2023-04-20', '2023-05-20', NULL),
(4, 1, '2023-04-19', '2023-05-19', '2023-05-10'),
(5, 2, '2023-04-21', '2023-05-21', NULL),
(6, 1, '2023-04-20', '2023-05-20', '2023-05-11');

-- Inserting sample data into Fines table
INSERT INTO Fines (LoanID, TotalFines, RepaidFines)
VALUES (2, 10.00, 5.00),
(3, 5.00, 2.50),
(4, 11.00, 6.00),
(5, 6.00, 3.00);


-- Insert sample data into FinePayments table
INSERT INTO FinePayments (FineID, PaymentDate, PaymentAmount, PaymentMethod)
VALUES (3, '2023-05-01 12:00:00', 5.00, 'Cash'),
(4, '2023-05-05 13:00:00', 2.50, 'Card'),
(5, '2023-05-12 15:30:00', 1.00, 'Cash'),
(5, '2023-05-02 12:00:00', 6.00, 'Cash'),
(6, '2023-05-06 13:00:00', 3.00, 'Card'),
(6, '2023-05-13 15:30:00', 1.00, 'Cash');

-
--Viewing members with their associated adresses. 
SELECT * 
FROM MEMBER 
INNER JOIN ADDRESS
ON Member.MemberID = Address.MemberID

--Update member's detail (Alex Cole) whose email and his associated address has changed
BEGIN TRANSACTION

UPDATE Member
SET FirstName = 'Alex',
LastName = 'Cole',
Email = 'alexcole123@example.com'
WHERE MemberID = 3

UPDATE Address
SET AddressLine1 = '64 Eccles New Road',
AddressLine2 = NULL,
City = 'Salford',
StateProvince = 'Greater Manchester',
PostalCode = 'M5 4WT',
Country = 'United Kingdom'
WHERE MemberID = 3

COMMIT TRANSACTION

--To return a full list of all items currently on loan which have a due date of less than five days from the current date 
SELECT * FROM GetItemsOnLoanWithDueDateLessThan5Days()


