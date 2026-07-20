CREATE DATABASE IF NOT EXISTS railway;
USE railway;
CREATE TABLE user (
 userID INT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(100) NOT NULL,
 email VARCHAR(100) NOT NULL UNIQUE,
 phone VARCHAR(15) NOT NULL,
 password VARCHAR(255) NOT NULL
);
CREATE TABLE vehicle (
 vehicleNo VARCHAR(20) PRIMARY KEY,
 userID INT NOT NULL,
 vehicleType VARCHAR(50) NOT NULL,
 model VARCHAR(50),
 color VARCHAR(30),
 FOREIGN KEY (userID) REFERENCES user(userID)
 ON DELETE CASCADE
 ON UPDATE CASCADE);
 CREATE TABLE parking_slot (
 slotID INT AUTO_INCREMENT PRIMARY KEY,
 slotLabel VARCHAR(20) NOT NULL,
 status VARCHAR(20) NOT NULL DEFAULT 'Available',
 type VARCHAR(30) NOT NULL,
 rate DECIMAL(10,2) NOT NULL
);
CREATE TABLE booking (
 bookingID INT AUTO_INCREMENT PRIMARY KEY,
 slotID INT NOT NULL,
 vehicleNo VARCHAR(20) NOT NULL,
 startTime DATETIME NOT NULL,
 endTime DATETIME,
 bookingStatus VARCHAR(20) NOT NULL DEFAULT 'Active',
 FOREIGN KEY (slotID) REFERENCES parking_slot(slotID)
 ON DELETE CASCADE
 ON UPDATE CASCADE,
 FOREIGN KEY (vehicleNo) REFERENCES vehicle(vehicleNo)
 ON DELETE CASCADE
 ON UPDATE CASCADE
);
CREATE TABLE payment (
 paymentID INT AUTO_INCREMENT PRIMARY KEY,
 bookingID INT NOT NULL,
 amount DECIMAL(10,2) NOT NULL,
 method VARCHAR(30) NOT NULL,
 paymentStatus VARCHAR(20) NOT NULL DEFAULT 'Pending',
 timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (bookingID) REFERENCES booking(bookingID)
 ON DELETE CASCADE
 ON UPDATE CASCADE
);
CREATE TABLE admin (
 adminID INT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(100) NOT NULL,
 email VARCHAR(100) NOT NULL UNIQUE,
 password VARCHAR(255) NOT NULL,
 role VARCHAR(50) NOT NULL DEFAULT 'Manager'
);
INSERT INTO user (name, email, phone, password) VALUES
('Rahul Sharma', 'rahul@email.com', '9876543210', 'rahul@123'),
('Priya Verma', 'priya@email.com', '9876543211', 'priya@456'),
('Amit Kumar', 'amit@email.com', '9876543212', 'amit@789'),
('Sneha Reddy', 'sneha@email.com', '9876543213', 'sneha@321'),
('Vikram Singh', 'vikram@email.com', '9876543214', 'vikram@654');

INSERT INTO vehicle (vehicleNo, userID, vehicleType, model, color) VALUES
('KA01AB1234', 1, 'Four-Wheeler', 'Maruti Swift', 'White'),
('KA01CD5678', 1, 'Two-Wheeler', 'Honda Activa', 'Black'),
('KA02EF9012', 2, 'Four-Wheeler', 'Hyundai i20', 'Silver'),
('KA03GH3456', 3, 'Two-Wheeler', 'TVS Jupiter', 'Blue'),
('KA04IJ7890', 4, 'Four-Wheeler', 'Tata Nexon', 'Red'),
('KA05KL2345', 5, 'Two-Wheeler', 'Bajaj Pulsar', 'Black');

INSERT INTO parking_slot (slotLabel, status, type, rate) VALUES
('A1', 'Available', 'Four-Wheeler', 50.00),
('A2', 'Available', 'Four-Wheeler', 50.00),
('A3', 'Occupied', 'Four-Wheeler', 50.00),
('B1', 'Available', 'Two-Wheeler', 20.00),
('B2', 'Available', 'Two-Wheeler', 20.00),
('B3', 'Occupied', 'Two-Wheeler', 20.00),
('C1', 'Available', 'Heavy Vehicle', 100.00),
('C2', 'Reserved', 'Heavy Vehicle', 100.00);

INSERT INTO booking (slotID, vehicleNo, startTime, endTime, bookingStatus) VALUES
(1, 'KA01AB1234', '2025-06-01 09:00:00', '2025-06-01 12:00:00', 'Completed'),
(4, 'KA01CD5678', '2025-06-01 10:00:00', '2025-06-01 11:30:00', 'Completed'),
(2, 'KA02EF9012', '2025-06-02 08:00:00', '2025-06-02 14:00:00', 'Completed'),
(5, 'KA03GH3456', '2025-06-02 09:30:00', NULL, 'Active'),
(3, 'KA04IJ7890', '2025-06-03 07:00:00', '2025-06-03 10:00:00', 'Completed'),
(1, 'KA05KL2345', '2025-06-03 11:00:00', NULL, 'Active');

INSERT INTO payment (bookingID, amount, method, paymentStatus, timestamp) VALUES
(1, 150.00, 'Card', 'Paid', '2025-06-01 12:05:00'),
(2, 30.00, 'Cash', 'Paid', '2025-06-01 11:35:00'),
(3, 300.00, 'Online', 'Paid', '2025-06-02 14:10:00'),
(5, 150.00, 'Card', 'Paid', '2025-06-03 10:05:00');

INSERT INTO admin (name, email, password, role) VALUES
('Admin One', 'admin1@parking.com', 'admin@123', 'Super Admin'),
('Admin Two', 'admin2@parking.com', 'admin@456', 'Manager');






CREATE TRIGGER after_booking_insert
AFTER INSERT ON booking
FOR EACH ROW
BEGIN
 UPDATE parking_slot
 SET status = 'Occupied'
 WHERE slotID = NEW.slotID
END //
DELIMITER ;
DELIMITER //
DELIMITER //

CREATE TRIGGER before_booking_insert
BEFORE INSERT ON booking
FOR EACH ROW
BEGIN
    DECLARE slotStatus VARCHAR(20);

    SELECT status
    INTO slotStatus
    FROM parking_slot
    WHERE slotID = NEW.slotID;

    IF slotStatus = 'Occupied' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: This parking slot is already occupied.';
    END IF;
END //

DELIMITER ;
DELIMITER //

CREATE PROCEDURE RegisterUser(
    IN p_name VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_phone VARCHAR(15),
    IN p_password VARCHAR(255)
)
BEGIN
    INSERT INTO user (name, email, phone, password)
    VALUES (p_name, p_email, p_phone, p_password);
END //

DELIMITER ;
CALL RegisterUser('Arun Das', 'arun@email.com', '9876543215', 'arun@999');
DELIMITER //
CREATE PROCEDURE CreateBooking(
	 IN p_slotID INT,
	 IN p_vehicleNo VARCHAR(20),
	 IN p_startTime DATETIME
)
BEGIN
 INSERT INTO booking (slotID, vehicleNo, startTime, bookingStatus)
 VALUES (p_slotID, p_vehicleNo, p_startTime, 'Active');
END //
DELIMITER ;
CALL CreateBooking(2, 'KA02EF9012', '2025-06-04 08:00:00');

DELIMITER //
CREATE PROCEDURE CompleteBooking(
	 IN p_bookingID INT,
	 IN p_method VARCHAR(30)
)
BEGIN
	 DECLARE p_slotID INT;
	 DECLARE p_startTime DATETIME;
	 DECLARE p_endTime DATETIME;
	 DECLARE p_rate DECIMAL(10,2);
	 DECLARE p_hours INT;
	 DECLARE p_amount DECIMAL(10,2);
	 SET p_endTime = NOW();
	 SELECT b.slotID, b.startTime, ps.rate
	 INTO p_slotID, p_startTime, p_rate
	 FROM booking b
	 JOIN parking_slot ps ON b.slotID = ps.slotID
	 WHERE b.bookingID = p_bookingID;
	 SET p_hours = CEIL(TIMESTAMPDIFF(MINUTE, p_startTime, p_endTime) / 60);
	 SET p_amount = p_hours * p_rate;
	 UPDATE booking
	 SET bookingStatus = 'Completed', endTime = p_endTime
	 WHERE bookingID = p_bookingID;
	 INSERT INTO payment (bookingID, amount, method, paymentStatus, timestamp)
	 VALUES (p_bookingID, p_amount, p_method, 'Paid', p_endTime);
END //
DELIMITER ;

CALL CompleteBooking(4, 'Online');
DELIMITER //
CREATE PROCEDURE GetAvailableSlots(
	IN p_type VARCHAR(30)
)
BEGIN
	 SELECT slotID, slotLabel, type, rate
	 FROM parking_slot
	 WHERE status = 'Available' AND type = p_type;
END //
DELIMITER ;
CALL GetAvailableSlots('Four-Wheeler');

CREATE VIEW active_bookings AS

CREATE VIEW payment_summary AS


CREATE VIEW slot_occupancy AS
SELECT type,
	 COUNT(*) AS totalSlots,
	 SUM(CASE WHEN status = 'Available' THEN 1 ELSE 0 END) AS availableSlots,
	 SUM(CASE WHEN status = 'Occupied' THEN 1 ELSE 0 END) AS occupiedSlots,
	 SUM(CASE WHEN status = 'Reserved' THEN 1 ELSE 0 END) AS reservedSlots
FROM parking_slot
GROUP BY type;
