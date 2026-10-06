-- =====================================================================
-- Project 31: SQL Queries and Views for Reporting
-- Municipal Waste Collection and Recycling Management System
-- =====================================================================

USE municipal_waste_management;


-- =====================================================================
-- QUERY 1: Display each area with the total number of residents
-- and the total quantity of waste collected from that area.
-- =====================================================================

SELECT
    a.Area_ID,
    a.Area_Name,
    COUNT(DISTINCT r.Resident_ID) AS Total_Residents,
    COALESCE(SUM(wc.Quantity_Kg), 0) AS Total_Waste_Kg
FROM Area a
LEFT JOIN Resident r
    ON a.Area_ID = r.Area_ID
LEFT JOIN Waste_Collection wc
    ON r.Resident_ID = wc.Resident_ID
GROUP BY
    a.Area_ID,
    a.Area_Name
ORDER BY Total_Waste_Kg DESC;


-- =====================================================================
-- QUERY 2: Display waste types whose total collected quantity is
-- greater than the average quantity collected across all waste types.
-- =====================================================================

SELECT
    wt.Waste_Type_ID,
    wt.Waste_Type_Name,
    SUM(wc.Quantity_Kg) AS Total_Quantity_Kg
FROM Waste_Type wt
JOIN Waste_Collection wc
    ON wt.Waste_Type_ID = wc.Waste_Type_ID
GROUP BY
    wt.Waste_Type_ID,
    wt.Waste_Type_Name
HAVING SUM(wc.Quantity_Kg) > (
    SELECT AVG(total_quantity)
    FROM (
        SELECT SUM(Quantity_Kg) AS total_quantity
        FROM Waste_Collection
        GROUP BY Waste_Type_ID
    ) AS waste_totals
)
ORDER BY Total_Quantity_Kg DESC;


-- =====================================================================
-- QUERY 3: Display drivers who have handled more waste than the
-- average quantity handled by all drivers.
-- =====================================================================

SELECT
    d.Driver_ID,
    d.Driver_Name,
    SUM(wc.Quantity_Kg) AS Total_Waste_Handled_Kg
FROM Driver d
JOIN Vehicle v
    ON d.Driver_ID = v.Driver_ID
JOIN Waste_Collection wc
    ON v.Vehicle_ID = wc.Vehicle_ID
GROUP BY
    d.Driver_ID,
    d.Driver_Name
HAVING SUM(wc.Quantity_Kg) > (
    SELECT AVG(driver_total)
    FROM (
        SELECT SUM(wc2.Quantity_Kg) AS driver_total
        FROM Driver d2
        JOIN Vehicle v2
            ON d2.Driver_ID = v2.Driver_ID
        JOIN Waste_Collection wc2
            ON v2.Vehicle_ID = wc2.Vehicle_ID
        GROUP BY d2.Driver_ID
    ) AS driver_totals
)
ORDER BY Total_Waste_Handled_Kg DESC;


-- =====================================================================
-- QUERY 4: Display the top 5 residents based on the total quantity
-- of waste collected from them.
-- =====================================================================

SELECT
    r.Resident_ID,
    r.Name AS Resident_Name,
    a.Area_Name,
    SUM(wc.Quantity_Kg) AS Total_Waste_Kg
FROM Resident r
JOIN Area a
    ON r.Area_ID = a.Area_ID
JOIN Waste_Collection wc
    ON r.Resident_ID = wc.Resident_ID
GROUP BY
    r.Resident_ID,
    r.Name,
    a.Area_Name
ORDER BY Total_Waste_Kg DESC
LIMIT 5;


-- =====================================================================
-- QUERY 5: Display areas where at least one waste collection was
-- delayed or missed.
-- =====================================================================

SELECT DISTINCT
    a.Area_ID,
    a.Area_Name,
    a.Pincode
FROM Area a
JOIN Resident r
    ON a.Area_ID = r.Area_ID
JOIN Waste_Collection wc
    ON r.Resident_ID = wc.Resident_ID
WHERE wc.Collection_Status IN ('Delayed', 'Missed')
ORDER BY a.Area_ID;


-- =====================================================================
-- QUERY 6: Display the percentage of collected, delayed and missed
-- waste collection records.
-- =====================================================================

SELECT
    Collection_Status,
    COUNT(*) AS Total_Collections,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM Waste_Collection),
        2
    ) AS Percentage
FROM Waste_Collection
GROUP BY Collection_Status
ORDER BY Percentage DESC;


-- =====================================================================
-- QUERY 7: Display vehicles that have not been used for any waste
-- collection.
-- =====================================================================

SELECT
    v.Vehicle_ID,
    v.Vehicle_Number,
    v.Vehicle_Type,
    v.Vehicle_Status
FROM Vehicle v
WHERE NOT EXISTS (
    SELECT 1
    FROM Waste_Collection wc
    WHERE wc.Vehicle_ID = v.Vehicle_ID
)
ORDER BY v.Vehicle_ID;


-- =====================================================================
-- QUERY 8: Display recycling centers that have processed more
-- recyclable waste than the average recyclable waste processed
-- across all recycling centers.
-- =====================================================================

SELECT
    rc.Center_ID,
    rc.Center_Name,
    SUM(wp.Recyclable_Kg) AS Total_Recyclable_Kg
FROM Recycling_Center rc
JOIN Waste_Processing wp
    ON rc.Center_ID = wp.Center_ID
GROUP BY
    rc.Center_ID,
    rc.Center_Name
HAVING SUM(wp.Recyclable_Kg) > (
    SELECT AVG(center_recyclable)
    FROM (
        SELECT SUM(Recyclable_Kg) AS center_recyclable
        FROM Waste_Processing
        GROUP BY Center_ID
    ) AS center_totals
)
ORDER BY Total_Recyclable_Kg DESC;


-- =====================================================================
-- QUERY 9: Display residents who have both submitted a complaint
-- and had at least one waste collection marked as delayed or missed.
-- =====================================================================

SELECT
    r.Resident_ID,
    r.Name AS Resident_Name,
    a.Area_Name,
    COUNT(DISTINCT c.Complaint_ID) AS Total_Complaints,
    COUNT(DISTINCT wc.Collection_ID) AS Problematic_Collections
FROM Resident r
JOIN Area a
    ON r.Area_ID = a.Area_ID
JOIN Complaint c
    ON r.Resident_ID = c.Resident_ID
JOIN Waste_Collection wc
    ON r.Resident_ID = wc.Resident_ID
WHERE wc.Collection_Status IN ('Delayed', 'Missed')
GROUP BY
    r.Resident_ID,
    r.Name,
    a.Area_Name
ORDER BY Total_Complaints DESC;


-- =====================================================================
-- QUERY 10: Display a complete performance summary for each driver,
-- including vehicle, total collections, total waste handled and
-- number of delayed or missed collections.
-- =====================================================================

SELECT
    d.Driver_ID,
    d.Driver_Name,
    v.Vehicle_Number,
    v.Vehicle_Type,

    COUNT(wc.Collection_ID) AS Total_Collections,

    COALESCE(SUM(wc.Quantity_Kg), 0) AS Total_Waste_Kg,

    SUM(
        CASE
            WHEN wc.Collection_Status = 'Delayed'
            THEN 1
            ELSE 0
        END
    ) AS Delayed_Collections,

    SUM(
        CASE
            WHEN wc.Collection_Status = 'Missed'
            THEN 1
            ELSE 0
        END
    ) AS Missed_Collections

FROM Driver d
LEFT JOIN Vehicle v
    ON d.Driver_ID = v.Driver_ID
LEFT JOIN Waste_Collection wc
    ON v.Vehicle_ID = wc.Vehicle_ID

GROUP BY
    d.Driver_ID,
    d.Driver_Name,
    v.Vehicle_Number,
    v.Vehicle_Type

ORDER BY Total_Waste_Kg DESC;

-- =====================================================================
-- VIEW 1: Resident Waste Collection Summary
-- Shows each resident's area, number of collections and total waste.
-- =====================================================================

CREATE OR REPLACE VIEW Resident_Waste_Summary AS
SELECT
    r.Resident_ID,
    r.Name AS Resident_Name,
    a.Area_Name,
    COUNT(wc.Collection_ID) AS Total_Collections,
    COALESCE(SUM(wc.Quantity_Kg), 0) AS Total_Waste_Kg,
    COALESCE(AVG(wc.Quantity_Kg), 0) AS Average_Waste_Kg
FROM Resident r
LEFT JOIN Area a
    ON r.Area_ID = a.Area_ID
LEFT JOIN Waste_Collection wc
    ON r.Resident_ID = wc.Resident_ID
GROUP BY
    r.Resident_ID,
    r.Name,
    a.Area_Name;


-- Display the view
SELECT * FROM Resident_Waste_Summary;


-- =====================================================================
-- VIEW 2: Driver Performance Summary
-- Shows the performance of each driver and their assigned vehicle.
-- =====================================================================

CREATE OR REPLACE VIEW Driver_Performance AS
SELECT
    d.Driver_ID,
    d.Driver_Name,
    v.Vehicle_Number,
    v.Vehicle_Type,
    COUNT(wc.Collection_ID) AS Total_Collections,
    COALESCE(SUM(wc.Quantity_Kg), 0) AS Total_Waste_Kg
FROM Driver d
LEFT JOIN Vehicle v
    ON d.Driver_ID = v.Driver_ID
LEFT JOIN Waste_Collection wc
    ON v.Vehicle_ID = wc.Vehicle_ID
GROUP BY
    d.Driver_ID,
    d.Driver_Name,
    v.Vehicle_Number,
    v.Vehicle_Type;


-- Display the view
SELECT * FROM Driver_Performance;


-- =====================================================================
-- VIEW 3: Area Waste Collection Summary
-- Provides waste collection statistics for each area.
-- =====================================================================

CREATE OR REPLACE VIEW Area_Waste_Summary AS
SELECT
    a.Area_ID,
    a.Area_Name,
    a.Pincode,
    COUNT(wc.Collection_ID) AS Total_Collections,
    COALESCE(SUM(wc.Quantity_Kg), 0) AS Total_Waste_Kg,

    SUM(
        CASE
            WHEN wc.Collection_Status = 'Collected'
            THEN 1
            ELSE 0
        END
    ) AS Successful_Collections,

    SUM(
        CASE
            WHEN wc.Collection_Status IN ('Delayed', 'Missed')
            THEN 1
            ELSE 0
        END
    ) AS Problematic_Collections

FROM Area a
LEFT JOIN Resident r
    ON a.Area_ID = r.Area_ID
LEFT JOIN Waste_Collection wc
    ON r.Resident_ID = wc.Resident_ID

GROUP BY
    a.Area_ID,
    a.Area_Name,
    a.Pincode;


-- Display the view
SELECT * FROM Area_Waste_Summary;


-- =====================================================================
-- VIEW 4: Complaint Details
-- Combines complaint, resident and area information.
-- =====================================================================

CREATE OR REPLACE VIEW Complaint_Details AS
SELECT
    c.Complaint_ID,
    r.Resident_ID,
    r.Name AS Resident_Name,
    a.Area_Name,
    c.Complaint_Date,
    c.Complaint_Type,
    c.Description,
    c.Status
FROM Complaint c
JOIN Resident r
    ON c.Resident_ID = r.Resident_ID
JOIN Area a
    ON r.Area_ID = a.Area_ID;


-- Display the view
SELECT * FROM Complaint_Details;


-- =====================================================================
-- VIEW 5: Waste Processing Summary
-- Shows processed waste and the corresponding recycling center.
-- =====================================================================

CREATE OR REPLACE VIEW Waste_Processing_Summary AS
SELECT
    wp.Processing_ID,
    wp.Collection_ID,
    rc.Center_Name,
    rc.Location,
    wp.Processing_Date,
    wp.Recyclable_Kg,
    wp.Organic_Kg,
    wp.Non_Recyclable_Kg,

    (
        COALESCE(wp.Recyclable_Kg, 0) +
        COALESCE(wp.Organic_Kg, 0) +
        COALESCE(wp.Non_Recyclable_Kg, 0)
    ) AS Total_Processed_Kg

FROM Waste_Processing wp
JOIN Recycling_Center rc
    ON wp.Center_ID = rc.Center_ID;


-- Display the view
SELECT * FROM Waste_Processing_Summary;
