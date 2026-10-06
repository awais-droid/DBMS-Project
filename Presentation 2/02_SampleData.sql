/* ============================================================
   MUNICIPAL WASTE COLLECTION AND RECYCLING MANAGEMENT SYSTEM
   SAMPLE DATA
   First 5 records for each table
   ============================================================ */

USE municipal_waste_management;


/* ============================================================
   1. AREA TABLE
   Stores the geographical areas covered by the system.
   ============================================================ */

INSERT INTO Area (Area_Name, Pincode) VALUES
('Miyapur', '500049'),
('Kukatpally', '500072'),
('Bachupally', '500090'),
('Nizampet', '500090'),
('Pragathi Nagar', '500090');


/* ============================================================
   2. RESIDENT TABLE
   Stores information about residents and their areas.
   Area_ID refers to the Area table.
   ============================================================ */

INSERT INTO Resident
(Name, Phone, Email, Address, Area_ID)
VALUES
('Aarav Sharma', '9876543210', 'aarav@gmail.com', 'Miyapur Main Road', 1),
('Aisha Khan', '9876543211', 'aisha@gmail.com', 'Kukatpally Housing Board', 2),
('Rahul Reddy', '9876543212', 'rahul@gmail.com', 'Bachupally Main Road', 3),
('Sneha Rao', '9876543213', 'sneha@gmail.com', 'Nizampet Road', 4),
('Vikram Singh', '9876543214', 'vikram@gmail.com', 'Pragathi Nagar', 5);


/* ============================================================
   3. WASTE_TYPE TABLE
   Stores different categories of waste.
   ============================================================ */

INSERT INTO Waste_Type
(Waste_Type_Name, Description)
VALUES
('Food Waste', 'Waste generated from leftover food and kitchen activities'),
('Garden Waste', 'Leaves, grass and other garden waste'),
('Paper Waste', 'Used paper and paper products'),
('Cardboard', 'Used cardboard boxes and packaging'),
('Plastic Bottles', 'Discarded plastic bottles');


/* ============================================================
   4. DRIVER TABLE
   Stores waste collection driver information.
   License numbers are unique.
   ============================================================ */

INSERT INTO Driver
(Driver_Name, Phone, License_Number)
VALUES
('Ramesh Kumar', '9876500001', 'TS09DL1001'),
('Suresh Reddy', '9876500002', 'TS09DL1002'),
('Mahesh Yadav', '9876500003', 'TS09DL1003'),
('Naveen Kumar', '9876500004', 'TS09DL1004'),
('Ravi Teja', '9876500005', 'TS09DL1005');


/* ============================================================
   5. VEHICLE TABLE
   Stores waste collection vehicle information.
   Driver_ID refers to the Driver table.
   ============================================================ */

INSERT INTO Vehicle
(Vehicle_Number, Vehicle_Type, Capacity_Kg, Driver_ID, Vehicle_Status)
VALUES
('TS09EA1001', 'Mini Tipper', 500.00, 1, 'Active'),
('TS09EA1002', 'Garbage Truck', 1000.00, 2, 'Active'),
('TS09EA1003', 'Compactor Truck', 1500.00, 3, 'Active'),
('TS09EA1004', 'Recycling Truck', 800.00, 4, 'Active'),
('TS09EA1005', 'Mini Tipper', 500.00, 5, 'Maintenance');


/* ============================================================
   6. ROUTE TABLE
   Stores waste collection routes and schedules.
   Area_ID and Vehicle_ID are foreign keys.
   ============================================================ */

INSERT INTO Route
(Route_Name, Area_ID, Vehicle_ID, Collection_Schedule)
VALUES
('Miyapur Residential Route', 1, 1, 'Daily 06:00 AM'),
('Kukatpally Main Route', 2, 2, 'Daily 06:30 AM'),
('Bachupally Residential Route', 3, 3, 'Daily 07:00 AM'),
('Nizampet Main Route', 4, 4, 'Daily 07:30 AM'),
('Pragathi Nagar Route', 5, 5, 'Daily 08:00 AM');


/* ============================================================
   7. WASTE_COLLECTION TABLE
   Records waste collected from residents.
   Resident_ID, Vehicle_ID and Waste_Type_ID are foreign keys.
   ============================================================ */

INSERT INTO Waste_Collection
(Resident_ID, Vehicle_ID, Collection_Date,
 Waste_Type_ID, Quantity_Kg, Collection_Status)
VALUES
(1, 1, '2026-09-01', 1, 3.50, 'Collected'),
(2, 2, '2026-09-02', 2, 4.20, 'Collected'),
(3, 3, '2026-09-03', 3, 2.80, 'Collected'),
(4, 4, '2026-09-04', 4, 5.10, 'Delayed'),
(5, 5, '2026-09-05', 5, 3.90, 'Collected');


/* ============================================================
   8. RECYCLING_CENTER TABLE
   Stores information about recycling centers.
   ============================================================ */

INSERT INTO Recycling_Center
(Center_Name, Location, Capacity_Kg, Contact_Number)
VALUES
('Miyapur Recycling Center', 'Miyapur, Hyderabad', 5000.00, '9000000001'),
('Kukatpally Recycling Center', 'Kukatpally, Hyderabad', 6000.00, '9000000002'),
('Bachupally Recycling Center', 'Bachupally, Hyderabad', 4500.00, '9000000003'),
('Nizampet Recycling Center', 'Nizampet, Hyderabad', 5500.00, '9000000004'),
('Pragathi Nagar Recycling Center', 'Pragathi Nagar, Hyderabad', 4000.00, '9000000005');


/* ============================================================
   9. WASTE_PROCESSING TABLE
   Stores the processing details of collected waste.
   The processed quantity is divided into recyclable,
   organic and non-recyclable waste.
   ============================================================ */

INSERT INTO Waste_Processing
(Collection_ID, Center_ID, Processing_Date,
 Recyclable_Kg, Organic_Kg, Non_Recyclable_Kg)
VALUES
(1, 1, '2026-09-01', 1.00, 2.00, 0.50),
(2, 2, '2026-09-02', 1.20, 2.50, 0.50),
(3, 3, '2026-09-03', 1.00, 1.30, 0.50),
(4, 4, '2026-09-04', 2.00, 2.00, 1.00),
(5, 5, '2026-09-05', 1.50, 1.80, 0.60);


/* ============================================================
   10. COMPLAINT TABLE
   Stores complaints submitted by residents.
   ============================================================ */

INSERT INTO Complaint
(Resident_ID, Complaint_Date, Complaint_Type,
 Description, Status)
VALUES
(1, '2026-09-01', 'Missed Collection',
 'Waste was not collected from the residence.',
 'Resolved'),

(2, '2026-09-02', 'Delayed Collection',
 'Waste collection was delayed.',
 'Pending'),

(3, '2026-09-03', 'Vehicle Issue',
 'Collection vehicle did not arrive on time.',
 'Under Investigation'),

(4, '2026-09-04', 'Waste Overflow',
 'Waste bins were overflowing in the area.',
 'Resolved'),

(5, '2026-09-05', 'Missed Collection',
 'Scheduled waste collection was missed.',
 'Pending');
