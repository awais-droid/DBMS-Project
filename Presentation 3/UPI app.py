from flask import Flask, render_template, request, redirect, url_for
import mysql.connector

app = Flask(__name__)

# ============================================================
# MYSQL CONFIGURATION
# ============================================================

DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "NotAwais$1405",
    "database": "municipal_waste_management",
    "port": 3306
}


def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)


# ============================================================
# DASHBOARD DATA
# ============================================================

def get_dashboard_data():

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    # Total residents
    cursor.execute("SELECT COUNT(*) AS total FROM Resident")
    residents = cursor.fetchone()["total"]

    # Total vehicles
    cursor.execute("SELECT COUNT(*) AS total FROM Vehicle")
    vehicles = cursor.fetchone()["total"]

    # Active vehicles
    cursor.execute("""
        SELECT COUNT(*) AS total
        FROM Vehicle
        WHERE Vehicle_Status = 'Active'
    """)
    active_vehicles = cursor.fetchone()["total"]

    # Recycling centers
    cursor.execute("SELECT COUNT(*) AS total FROM Recycling_Center")
    centers = cursor.fetchone()["total"]

    # Total collected waste
    cursor.execute("""
        SELECT COALESCE(SUM(Quantity_Kg), 0) AS total
        FROM Waste_Collection
        WHERE Collection_Status = 'Collected'
    """)
    waste = cursor.fetchone()["total"]

    # Pending complaints
    cursor.execute("""
        SELECT COUNT(*) AS total
        FROM Complaint
        WHERE Status = 'Pending'
    """)
    pending_complaints = cursor.fetchone()["total"]

    # Missed collections
    cursor.execute("""
        SELECT COUNT(*) AS total
        FROM Waste_Collection
        WHERE Collection_Status = 'Missed'
    """)
    missed_collections = cursor.fetchone()["total"]

    # Delayed collections
    cursor.execute("""
        SELECT COUNT(*) AS total
        FROM Waste_Collection
        WHERE Collection_Status = 'Delayed'
    """)
    delayed_collections = cursor.fetchone()["total"]

    # Collection status
    cursor.execute("""
        SELECT Collection_Status, COUNT(*) AS total
        FROM Waste_Collection
        GROUP BY Collection_Status
    """)
    collection_status = cursor.fetchall()

    # Complaint status
    cursor.execute("""
        SELECT Status, COUNT(*) AS total
        FROM Complaint
        GROUP BY Status
    """)
    complaint_status = cursor.fetchall()

    # Waste by type
    cursor.execute("""
        SELECT
            wt.Waste_Type_Name,
            COALESCE(SUM(wc.Quantity_Kg), 0) AS total
        FROM Waste_Type wt
        LEFT JOIN Waste_Collection wc
            ON wt.Waste_Type_ID = wc.Waste_Type_ID
        GROUP BY wt.Waste_Type_ID, wt.Waste_Type_Name
        HAVING total > 0
        ORDER BY total DESC
    """)
    waste_by_type = cursor.fetchall()

    # Waste processing
    cursor.execute("""
        SELECT
            COALESCE(SUM(Recyclable_Kg), 0) AS recyclable,
            COALESCE(SUM(Organic_Kg), 0) AS organic,
            COALESCE(SUM(Non_Recyclable_Kg), 0) AS non_recyclable
        FROM Waste_Processing
    """)
    processing = cursor.fetchone()

    # Waste by area
    cursor.execute("""
        SELECT
            a.Area_Name,
            COALESCE(SUM(wc.Quantity_Kg), 0) AS total
        FROM Area a
        JOIN Resident r
            ON a.Area_ID = r.Area_ID
        JOIN Waste_Collection wc
            ON r.Resident_ID = wc.Resident_ID
        GROUP BY a.Area_ID, a.Area_Name
        ORDER BY total DESC
        LIMIT 10
    """)
    waste_by_area = cursor.fetchall()

    cursor.close()
    db.close()

    return {
        "residents": residents,
        "vehicles": vehicles,
        "active_vehicles": active_vehicles,
        "centers": centers,
        "waste": waste,
        "pending_complaints": pending_complaints,
        "missed_collections": missed_collections,
        "delayed_collections": delayed_collections,
        "collection_status": collection_status,
        "complaint_status": complaint_status,
        "waste_by_type": waste_by_type,
        "processing": processing,
        "waste_by_area": waste_by_area
    }


# ============================================================
# DASHBOARD
# ============================================================

@app.route("/")
def home():

    data = get_dashboard_data()

    search_results = []
    search_query = ""

    return render_template(
        "index.html",
        **data,
        search_results=search_results,
        search_query=search_query
    )


# ============================================================
# GLOBAL SEARCH
# ============================================================

@app.route("/search")
def search():

    query = request.args.get("q", "").strip()

    data = get_dashboard_data()

    results = []

    if query:

        db = get_db_connection()
        cursor = db.cursor(dictionary=True)

        search_value = f"%{query}%"

        # Residents
        cursor.execute("""
            SELECT
                'Resident' AS result_type,
                r.Name AS title,
                CONCAT(
                    'Area: ', COALESCE(a.Area_Name, 'Unknown'),
                    ' | Phone: ', COALESCE(r.Phone, 'N/A')
                ) AS details
            FROM Resident r
            LEFT JOIN Area a
                ON r.Area_ID = a.Area_ID
            WHERE r.Name LIKE %s
               OR r.Phone LIKE %s
               OR r.Email LIKE %s
               OR a.Area_Name LIKE %s
        """, (search_value, search_value, search_value, search_value))

        results.extend(cursor.fetchall())

        # Vehicles
        cursor.execute("""
            SELECT
                'Vehicle' AS result_type,
                v.Vehicle_Number AS title,
                CONCAT(
                    v.Vehicle_Type,
                    ' | Driver: ',
                    COALESCE(d.Driver_Name, 'N/A'),
                    ' | Status: ',
                    v.Vehicle_Status
                ) AS details
            FROM Vehicle v
            LEFT JOIN Driver d
                ON v.Driver_ID = d.Driver_ID
            WHERE v.Vehicle_Number LIKE %s
               OR v.Vehicle_Type LIKE %s
               OR d.Driver_Name LIKE %s
        """, (search_value, search_value, search_value))

        results.extend(cursor.fetchall())

        # Routes
        cursor.execute("""
            SELECT
                'Route' AS result_type,
                rt.Route_Name AS title,
                CONCAT(
                    'Area: ', COALESCE(a.Area_Name, 'N/A'),
                    ' | Schedule: ', rt.Collection_Schedule
                ) AS details
            FROM Route rt
            LEFT JOIN Area a
                ON rt.Area_ID = a.Area_ID
            WHERE rt.Route_Name LIKE %s
               OR rt.Collection_Schedule LIKE %s
               OR a.Area_Name LIKE %s
        """, (search_value, search_value, search_value))

        results.extend(cursor.fetchall())

        # Complaints
        cursor.execute("""
            SELECT
                'Complaint' AS result_type,
                c.Complaint_Type AS title,
                CONCAT(
                    'Resident: ', COALESCE(r.Name, 'N/A'),
                    ' | Status: ', c.Status,
                    ' | ', c.Description
                ) AS details
            FROM Complaint c
            LEFT JOIN Resident r
                ON c.Resident_ID = r.Resident_ID
            WHERE c.Complaint_Type LIKE %s
               OR c.Description LIKE %s
               OR c.Status LIKE %s
               OR r.Name LIKE %s
        """, (search_value, search_value, search_value, search_value))

        results.extend(cursor.fetchall())

        cursor.close()
        db.close()

    return render_template(
        "index.html",
        **data,
        search_results=results,
        search_query=query
    )


# ============================================================
# RESIDENTS
# ============================================================

@app.route("/residents")
def residents_page():

    search = request.args.get("search", "").strip()

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    if search:

        search_value = f"%{search}%"

        cursor.execute("""
            SELECT
                r.Resident_ID,
                r.Name,
                r.Phone,
                r.Email,
                r.Address,
                a.Area_Name,
                a.Pincode
            FROM Resident r
            LEFT JOIN Area a
                ON r.Area_ID = a.Area_ID
            WHERE r.Name LIKE %s
               OR r.Phone LIKE %s
               OR r.Email LIKE %s
               OR a.Area_Name LIKE %s
            ORDER BY r.Resident_ID
        """, (search_value, search_value, search_value, search_value))

    else:

        cursor.execute("""
            SELECT
                r.Resident_ID,
                r.Name,
                r.Phone,
                r.Email,
                r.Address,
                a.Area_Name,
                a.Pincode
            FROM Resident r
            LEFT JOIN Area a
                ON r.Area_ID = a.Area_ID
            ORDER BY r.Resident_ID
        """)

    residents = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template(
        "residents.html",
        residents=residents,
        search=search
    )


# ============================================================
# WASTE COLLECTION
# ============================================================

@app.route("/collection")
def collection_page():

    status = request.args.get("status", "All")

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    if status == "All":

        cursor.execute("""
            SELECT
                wc.Collection_ID,
                r.Name AS Resident_Name,
                a.Area_Name,
                wt.Waste_Type_Name,
                v.Vehicle_Number,
                d.Driver_Name,
                wc.Collection_Date,
                wc.Quantity_Kg,
                wc.Collection_Status
            FROM Waste_Collection wc
            JOIN Resident r
                ON wc.Resident_ID = r.Resident_ID
            JOIN Area a
                ON r.Area_ID = a.Area_ID
            JOIN Waste_Type wt
                ON wc.Waste_Type_ID = wt.Waste_Type_ID
            JOIN Vehicle v
                ON wc.Vehicle_ID = v.Vehicle_ID
            JOIN Driver d
                ON v.Driver_ID = d.Driver_ID
            ORDER BY wc.Collection_ID
        """)

    else:

        cursor.execute("""
            SELECT
                wc.Collection_ID,
                r.Name AS Resident_Name,
                a.Area_Name,
                wt.Waste_Type_Name,
                v.Vehicle_Number,
                d.Driver_Name,
                wc.Collection_Date,
                wc.Quantity_Kg,
                wc.Collection_Status
            FROM Waste_Collection wc
            JOIN Resident r
                ON wc.Resident_ID = r.Resident_ID
            JOIN Area a
                ON r.Area_ID = a.Area_ID
            JOIN Waste_Type wt
                ON wc.Waste_Type_ID = wt.Waste_Type_ID
            JOIN Vehicle v
                ON wc.Vehicle_ID = v.Vehicle_ID
            JOIN Driver d
                ON v.Driver_ID = d.Driver_ID
            WHERE wc.Collection_Status = %s
            ORDER BY wc.Collection_ID
        """, (status,))

    collections = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template(
        "collection.html",
        collections=collections,
        selected_status=status
    )


# ============================================================
# VEHICLES
# ============================================================

@app.route("/vehicles")
def vehicles_page():

    status = request.args.get("status", "All")

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    if status == "All":

        cursor.execute("""
            SELECT
                v.Vehicle_ID,
                v.Vehicle_Number,
                v.Vehicle_Type,
                v.Capacity_Kg,
                d.Driver_Name,
                d.Phone,
                v.Vehicle_Status
            FROM Vehicle v
            LEFT JOIN Driver d
                ON v.Driver_ID = d.Driver_ID
            ORDER BY v.Vehicle_ID
        """)

    else:

        cursor.execute("""
            SELECT
                v.Vehicle_ID,
                v.Vehicle_Number,
                v.Vehicle_Type,
                v.Capacity_Kg,
                d.Driver_Name,
                d.Phone,
                v.Vehicle_Status
            FROM Vehicle v
            LEFT JOIN Driver d
                ON v.Driver_ID = d.Driver_ID
            WHERE v.Vehicle_Status = %s
            ORDER BY v.Vehicle_ID
        """, (status,))

    vehicles = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template(
        "vehicles.html",
        vehicles=vehicles,
        selected_status=status
    )


# ============================================================
# ROUTES
# ============================================================

@app.route("/routes")
def routes_page():

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    cursor.execute("""
        SELECT
            rt.Route_ID,
            rt.Route_Name,
            a.Area_Name,
            v.Vehicle_Number,
            d.Driver_Name,
            rt.Collection_Schedule
        FROM Route rt
        LEFT JOIN Area a
            ON rt.Area_ID = a.Area_ID
        LEFT JOIN Vehicle v
            ON rt.Vehicle_ID = v.Vehicle_ID
        LEFT JOIN Driver d
            ON v.Driver_ID = d.Driver_ID
        ORDER BY rt.Route_ID
    """)

    routes = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template("routes.html", routes=routes)


# ============================================================
# RECYCLING CENTERS
# ============================================================

@app.route("/recycling-centers")
def recycling_centers_page():

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    cursor.execute("""
        SELECT
            Center_ID,
            Center_Name,
            Location,
            Capacity_Kg,
            Contact_Number
        FROM Recycling_Center
        ORDER BY Center_ID
    """)

    centers = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template(
        "recycling_centers.html",
        centers=centers
    )


# ============================================================
# COMPLAINTS
# ============================================================

@app.route("/complaints")
def complaints_page():

    status = request.args.get("status", "All")

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    if status == "All":

        cursor.execute("""
            SELECT
                c.Complaint_ID,
                r.Name AS Resident_Name,
                a.Area_Name,
                c.Complaint_Date,
                c.Complaint_Type,
                c.Description,
                c.Status
            FROM Complaint c
            JOIN Resident r
                ON c.Resident_ID = r.Resident_ID
            LEFT JOIN Area a
                ON r.Area_ID = a.Area_ID
            ORDER BY c.Complaint_ID
        """)

    else:

        cursor.execute("""
            SELECT
                c.Complaint_ID,
                r.Name AS Resident_Name,
                a.Area_Name,
                c.Complaint_Date,
                c.Complaint_Type,
                c.Description,
                c.Status
            FROM Complaint c
            JOIN Resident r
                ON c.Resident_ID = r.Resident_ID
            LEFT JOIN Area a
                ON r.Area_ID = a.Area_ID
            WHERE c.Status = %s
            ORDER BY c.Complaint_ID
        """, (status,))

    complaints = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template(
        "complaints.html",
        complaints=complaints,
        selected_status=status
    )


# ============================================================
# REPORTS
# ============================================================

@app.route("/reports")
def reports_page():

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    # Waste by type
    cursor.execute("""
        SELECT
            wt.Waste_Type_Name,
            COUNT(wc.Collection_ID) AS Collection_Count,
            COALESCE(SUM(wc.Quantity_Kg), 0) AS Total_Kg
        FROM Waste_Type wt
        LEFT JOIN Waste_Collection wc
            ON wt.Waste_Type_ID = wc.Waste_Type_ID
        GROUP BY wt.Waste_Type_ID, wt.Waste_Type_Name
        ORDER BY Total_Kg DESC
    """)

    waste_report = cursor.fetchall()

    # Collection status
    cursor.execute("""
        SELECT
            Collection_Status,
            COUNT(*) AS Total
        FROM Waste_Collection
        GROUP BY Collection_Status
    """)

    status_report = cursor.fetchall()

    # Complaint status
    cursor.execute("""
        SELECT
            Status,
            COUNT(*) AS Total
        FROM Complaint
        GROUP BY Status
    """)

    complaint_report = cursor.fetchall()

    # Processing
    cursor.execute("""
        SELECT
            COALESCE(SUM(Recyclable_Kg), 0) AS recyclable,
            COALESCE(SUM(Organic_Kg), 0) AS organic,
            COALESCE(SUM(Non_Recyclable_Kg), 0) AS non_recyclable
        FROM Waste_Processing
    """)

    processing = cursor.fetchone()

    # Area report
    cursor.execute("""
        SELECT
            a.Area_Name,
            COALESCE(SUM(wc.Quantity_Kg), 0) AS Total_Kg
        FROM Area a
        JOIN Resident r
            ON a.Area_ID = r.Area_ID
        JOIN Waste_Collection wc
            ON r.Resident_ID = wc.Resident_ID
        GROUP BY a.Area_ID, a.Area_Name
        ORDER BY Total_Kg DESC
    """)

    area_report = cursor.fetchall()

    cursor.close()
    db.close()

    return render_template(
        "reports.html",
        waste_report=waste_report,
        status_report=status_report,
        complaint_report=complaint_report,
        processing=processing,
        area_report=area_report
    )


# ============================================================
# START APPLICATION
# ============================================================

# ============================================================
# ADD RESIDENT
# ============================================================

@app.route("/add_resident", methods=["POST"])
def add_resident():
    name = request.form.get("name")
    phone = request.form.get("phone")
    email = request.form.get("email")
    address = request.form.get("address")
    area_id = request.form.get("area_id")

    db = get_db_connection()
    cursor = db.cursor()

    cursor.execute("""
        INSERT INTO Resident
        (Name, Phone, Email, Address, Area_ID)
        VALUES (%s, %s, %s, %s, %s)
    """, (name, phone, email, address, area_id))

    db.commit()
    cursor.close()
    db.close()

    return redirect(url_for("residents_page"))


# ============================================================
# DELETE RESIDENT
# ============================================================

@app.route("/delete_resident/<int:resident_id>", methods=["POST"])
def delete_resident(resident_id):

    db = get_db_connection()
    cursor = db.cursor()

    try:
        # Delete processing records connected to this resident's
        # collection records first
        cursor.execute("""
            DELETE FROM Waste_Processing
            WHERE Collection_ID IN (
                SELECT Collection_ID
                FROM Waste_Collection
                WHERE Resident_ID = %s
            )
        """, (resident_id,))

        # Delete waste collection records
        cursor.execute("""
            DELETE FROM Waste_Collection
            WHERE Resident_ID = %s
        """, (resident_id,))

        # Delete complaints
        cursor.execute("""
            DELETE FROM Complaint
            WHERE Resident_ID = %s
        """, (resident_id,))

        # Finally delete the resident
        cursor.execute("""
            DELETE FROM Resident
            WHERE Resident_ID = %s
        """, (resident_id,))

        db.commit()

    except Exception as e:
        db.rollback()
        print("DELETE ERROR:", e)

    finally:
        cursor.close()
        db.close()

    return redirect(url_for("residents_page"))

if __name__ == "__main__":
    app.run(debug=True)
