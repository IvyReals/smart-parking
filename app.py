from flask import Flask, render_template, request, redirect
import mysql.connector
from datetime import datetime, timedelta

app = Flask(__name__)

# ------------------------------------
# DATABASE CONNECTION
# ------------------------------------

db = mysql.connector.connect(
    host="tokaido.proxy.rlwy.net",
    port=17593,
    user="root",
    password="PHLxNnqEHsdvOmMJZrqTwewDkgZwPUEB",
    database="railway"
)
cursor = db.cursor(dictionary=True)

# ------------------------------------
# HOME
# ------------------------------------

@app.route("/")
def home():
    return render_template("login.html")

# ------------------------------------
# DASHBOARD
# ------------------------------------

@app.route("/dashboard")
def dashboard():

    cursor.execute("SELECT COUNT(*) total FROM user")
    users = cursor.fetchone()["total"]

    cursor.execute("SELECT COUNT(*) total FROM vehicle")
    vehicles = cursor.fetchone()["total"]

    cursor.execute("SELECT COUNT(*) total FROM parking_slot")
    slots = cursor.fetchone()["total"]

    cursor.execute("""
        SELECT COUNT(*) total
        FROM booking
        WHERE bookingStatus='Active'
    """)
    bookings = cursor.fetchone()["total"]

    cursor.execute("""
        SELECT IFNULL(SUM(amount),0) revenue
        FROM payment
        WHERE paymentStatus='Paid'
    """)
    revenue = cursor.fetchone()["revenue"]

    return render_template(
        "dashboard.html",
        users=users,
        vehicles=vehicles,
        slots=slots,
        bookings=bookings,
        revenue=revenue
    )

# ------------------------------------
# USERS
# ------------------------------------

@app.route("/users")
def users():

    cursor.execute("""
        SELECT *
        FROM user
        ORDER BY userID
    """)

    users = cursor.fetchall()

    return render_template(
        "users.html",
        users=users
    )

@app.route("/add_user", methods=["POST"])
def add_user():

    name = request.form["name"]
    email = request.form["email"]
    phone = request.form["phone"]
    password = request.form["password"]

    cursor.execute("""

        INSERT INTO user
        (name,email,phone,password)

        VALUES
        (%s,%s,%s,%s)

    """,(name,email,phone,password))

    db.commit()

    return redirect("/users")

# ------------------------------------
# VEHICLES
# ------------------------------------

@app.route("/vehicles")
def vehicles():

    cursor.execute("""

        SELECT
        vehicle.*,
        user.name

        FROM vehicle

        JOIN user

        ON vehicle.userID=user.userID

        ORDER BY vehicle.vehicleNo

    """)

    vehicles = cursor.fetchall()

    return render_template(
        "vehicles.html",
        vehicles=vehicles
    )

@app.route("/add_vehicle",methods=["POST"])
def add_vehicle():

    vehicleNo=request.form["vehicleNo"]
    userID=request.form["userID"]
    vehicleType=request.form["vehicleType"]
    model=request.form["model"]
    color=request.form["color"]

    cursor.execute("""

        INSERT INTO vehicle

        (
        vehicleNo,
        userID,
        vehicleType,
        model,
        color
        )

        VALUES
        (%s,%s,%s,%s,%s)

    """,(vehicleNo,userID,vehicleType,model,color))

    db.commit()

    return redirect("/vehicles")
# ------------------------------------
# PARKING SLOTS
# ------------------------------------

@app.route("/slots")
def slots():

    cursor.execute("""

        SELECT
        *
        FROM parking_slot
        ORDER BY slotLabel

    """)

    slots = cursor.fetchall()

    return render_template(
        "slots.html",
        slots=slots
    )

# ------------------------------------
# BOOK SLOT
# ------------------------------------

@app.route("/book_slot", methods=["POST"])
def book_slot():
    
    slotID = request.form["slotID"]
    vehicleNo = request.form["vehicleNo"]
    duration = int(request.form["duration"])
    arrival = request.form["arrival"]

    startTime = datetime.strptime(
        arrival,
        "%Y-%m-%dT%H:%M"
    )
    

    endTime = startTime + timedelta(hours=duration)

    # -----------------------------
    # Check Slot
    # -----------------------------

    cursor.execute("""

    SELECT status,type,rate

    FROM parking_slot

    WHERE slotID=%s

    """,(slotID,))

    slot = cursor.fetchone()

    if slot["type"] != vehicleType:
        return f"This slot is only for {slot['type']}."

    # -----------------------------
    # Booking
    # -----------------------------

    cursor.execute("""

        INSERT INTO booking

        (
        slotID,
        vehicleNo,
        startTime,
        endTime,
        bookingStatus
        )

        VALUES

        (
        %s,
        %s,
        %s,
        %s,
        'Active'
        )

    """,

    (
        slotID,
        vehicleNo,
        startTime,
        endTime
    ))

    db.commit()

    bookingID = cursor.lastrowid

    # -----------------------------
    # Payment
    # -----------------------------

    amount = float(slot["rate"]) * duration

    cursor.execute("""

        INSERT INTO payment

        (
        bookingID,
        amount,
        method,
        paymentStatus
        )

        VALUES

        (
        %s,
        %s,
        'UPI',
        'Paid'
        )

    """,

    (
        bookingID,
        amount
    ))

    db.commit()

    # -----------------------------
    # Occupy Slot
    # -----------------------------

    cursor.execute("""

        UPDATE parking_slot

        SET status='Occupied'

        WHERE slotID=%s 

    """,(slotID,))

    db.commit()

    return redirect("/bookings")

# ------------------------------------
# RELEASE SLOT
# ------------------------------------

@app.route("/release/<int:id>")
def release(id):

    cursor.execute("""

        SELECT slotID

        FROM booking

        WHERE bookingID=%s

    """,(id,))

    booking = cursor.fetchone()

    if booking:

        cursor.execute("""

            UPDATE booking

            SET bookingStatus='Completed'

            WHERE bookingID=%s

        """,(id,))

        cursor.execute("""

            UPDATE parking_slot

            SET status='Available'

            WHERE slotID=%s

        """,(booking["slotID"],))

        db.commit()

    return redirect("/bookings")
# ------------------------------------
# BOOKINGS
# ------------------------------------

@app.route("/bookings")
def bookings():

    cursor.execute("""

        SELECT

        booking.bookingID,

        vehicle.vehicleNo,

        parking_slot.slotLabel,

        booking.startTime,

        booking.endTime,

        booking.bookingStatus,

        payment.amount,

        payment.paymentStatus

        FROM booking

        JOIN vehicle

        ON booking.vehicleNo = vehicle.vehicleNo

        JOIN parking_slot

        ON booking.slotID = parking_slot.slotID

        LEFT JOIN payment

        ON booking.bookingID = payment.bookingID

        ORDER BY booking.bookingID DESC

    """)

    bookings = cursor.fetchall()

    return render_template(
        "bookings.html",
        bookings=bookings
    )

# ------------------------------------
# PAYMENTS
# ------------------------------------

@app.route("/payments")
def payments():

    cursor.execute("""

        SELECT

        payment.paymentID,

        payment.bookingID,

        vehicle.vehicleNo,

        parking_slot.slotLabel,

        payment.amount,

        payment.method,

        payment.paymentStatus,

        payment.timestamp

        FROM payment

        JOIN booking

        ON payment.bookingID = booking.bookingID

        JOIN vehicle

        ON booking.vehicleNo = vehicle.vehicleNo

        JOIN parking_slot

        ON booking.slotID = parking_slot.slotID

        ORDER BY payment.paymentID DESC

    """)

    payments = cursor.fetchall()

    return render_template(
        "payments.html",
        payments=payments
    )

# ------------------------------------
# DELETE USER
# ------------------------------------

@app.route("/delete_user/<int:id>")
def delete_user(id):

    cursor.execute(
        "DELETE FROM user WHERE userID=%s",
        (id,)
    )

    db.commit()

    return redirect("/users")

# ------------------------------------
# DELETE VEHICLE
# ------------------------------------

@app.route("/delete_vehicle/<vehicleNo>")
def delete_vehicle(vehicleNo):

    cursor.execute(
        "DELETE FROM vehicle WHERE vehicleNo=%s",
        (vehicleNo,)
    )

    db.commit()

    return redirect("/vehicles")

# ------------------------------------
# RUN
# ------------------------------------

if __name__ == "__main__":

    app.run(
        debug=True
    )
