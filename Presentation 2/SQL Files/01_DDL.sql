/* ============================================================
   MUNICIPAL WASTE COLLECTION AND RECYCLING MANAGEMENT SYSTEM
   Database Creation Script
   DBMS: MySQL
   ============================================================ */


/* ============================================================
   1. CREATE DATABASE
   Creates the database for the Municipal Waste Management System.
   ============================================================ */

CREATE DATABASE municipal_waste_management;


/* ============================================================
   2. SELECT DATABASE
   Selects the newly created database for further operations.
   ============================================================ */

USE municipal_waste_management;


/* ============================================================
   3. CREATE AREA TABLE
   Stores information about different geographical areas.
   ============================================================ */

CREATE TABLE Area (
    Area_ID INT PRIMARY KEY AUTO_INCREMENT,
    Area_Name VARCHAR(100) NOT NULL,
    Pincode VARCHAR(10) NOT NULL
);


/* ============================================================
   4. CREATE RESIDENT TABLE
   Stores information about residents.
   Area_ID is a foreign key referencing the Area table.
   ============================================================ */

CREATE TABLE Resident (
    Resident_ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Phone VARCHAR(15),
    Email VARCHAR(100),
    Address VARCHAR(255),
    Area_ID INT,

    FOREIGN KEY (Area_ID)
        REFERENCES Area(Area_ID)
);


/* ============================================================
   5. CREATE WASTE_TYPE TABLE
   Stores different types of waste handled by the system.
   ============================================================ */

CREATE TABLE Waste_Type (
    Waste_Type_ID INT PRIMARY KEY AUTO_INCREMENT,
    Waste_Type_Name VARCHAR(50) NOT NULL,
    Description VARCHAR(255)
);


/* ============================================================
   6. CREATE DRIVER TABLE
   Stores information about waste collection vehicle drivers.
   License_Number is UNIQUE to prevent duplicate licenses.
   ============================================================ */

CREATE TABLE Driver (
    Driver_ID INT PRIMARY KEY AUTO_INCREMENT,
    Driver_Name VARCHAR(100) NOT NULL,
    Phone VARCHAR(15),
    License_Number VARCHAR(50) UNIQUE
);


/* ============================================================
   7. CREATE VEHICLE TABLE
   Stores information about waste collection vehicles.
   Driver_ID connects each vehicle with its assigned driver.
   ============================================================ */

CREATE TABLE Vehicle (
    Vehicle_ID INT PRIMARY KEY AUTO_INCREMENT,
    Vehicle_Number VARCHAR(20) NOT NULL UNIQUE,
    Vehicle_Type VARCHAR(50),
    Capacity_Kg DECIMAL(10,2),
    Driver_ID INT,
    Vehicle_Status VARCHAR(30),

    FOREIGN KEY (Driver_ID)
        REFERENCES Driver(Driver_ID)
);


/* ============================================================
   8. CREATE ROUTE TABLE
   Stores waste collection routes.
   Each route is associated with an area and vehicle.
   ============================================================ */

CREATE TABLE Route (
    Route_ID INT PRIMARY KEY AUTO_INCREMENT,
    Route_Name VARCHAR(100) NOT NULL,
    Area_ID INT,
    Vehicle_ID INT,
    Collection_Schedule VARCHAR(100),

    FOREIGN KEY (Area_ID)
        REFERENCES Area(Area_ID),

    FOREIGN KEY (Vehicle_ID)
        REFERENCES Vehicle(Vehicle_ID)
);


/* ============================================================
   9. CREATE WASTE_COLLECTION TABLE
   Stores records of waste collected from residents.
   It connects residents, vehicles and waste types.
   ============================================================ */

CREATE TABLE Waste_Collection (
    Collection_ID INT PRIMARY KEY AUTO_INCREMENT,
    Resident_ID INT,
    Vehicle_ID INT,
    Collection_Date DATE NOT NULL,
    Waste_Type_ID INT,
    Quantity_Kg DECIMAL(10,2) NOT NULL,
    Collection_Status VARCHAR(30),

    FOREIGN KEY (Resident_ID)
        REFERENCES Resident(Resident_ID),

    FOREIGN KEY (Vehicle_ID)
        REFERENCES Vehicle(Vehicle_ID),

    FOREIGN KEY (Waste_Type_ID)
        REFERENCES Waste_Type(Waste_Type_ID)
);


/* ============================================================
   10. CREATE RECYCLING_CENTER TABLE
   Stores information about recycling and processing centers.
   ============================================================ */

CREATE TABLE Recycling_Center (
    Center_ID INT PRIMARY KEY AUTO_INCREMENT,
    Center_Name VARCHAR(100) NOT NULL,
    Location VARCHAR(255),
    Capacity_Kg DECIMAL(10,2),
    Contact_Number VARCHAR(15)
);


/* ============================================================
   11. CREATE WASTE_PROCESSING TABLE
   Stores information about how collected waste is processed.
   Waste can be divided into recyclable, organic and
   non-recyclable categories.
   ============================================================ */

CREATE TABLE Waste_Processing (
    Processing_ID INT PRIMARY KEY AUTO_INCREMENT,
    Collection_ID INT,
    Center_ID INT,
    Processing_Date DATE NOT NULL,
    Recyclable_Kg DECIMAL(10,2),
    Organic_Kg DECIMAL(10,2),
    Non_Recyclable_Kg DECIMAL(10,2),

    FOREIGN KEY (Collection_ID)
        REFERENCES Waste_Collection(Collection_ID),

    FOREIGN KEY (Center_ID)
        REFERENCES Recycling_Center(Center_ID)
);


/* ============================================================
   12. CREATE COMPLAINT TABLE
   Stores complaints submitted by residents.
   Resident_ID connects each complaint to the resident
   who submitted it.
   ============================================================ */

CREATE TABLE Complaint (
    Complaint_ID INT PRIMARY KEY AUTO_INCREMENT,
    Resident_ID INT,
    Complaint_Date DATE NOT NULL,
    Complaint_Type VARCHAR(100),
    Description VARCHAR(500),
    Status VARCHAR(30),

    FOREIGN KEY (Resident_ID)
        REFERENCES Resident(Resident_ID)
);
