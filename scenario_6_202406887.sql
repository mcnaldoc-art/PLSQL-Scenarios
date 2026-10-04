
-- ICT371 SCENARIO 6
-- UNIVERSITY EVENT SEAT BOOKING


DROP PROCEDURE IF EXISTS book_seats(IN INTEGER, IN VARCHAR, IN INTEGER);
DROP PROCEDURE IF EXISTS cancel_booking(IN INTEGER);

DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS events;


-- 1. CREATE TABLES


CREATE TABLE events (
    event_id SERIAL PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    available_seats INTEGER NOT NULL
        CHECK (available_seats >= 0)
);

CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    event_id INTEGER REFERENCES events(event_id),
    student_number VARCHAR(30) NOT NULL,
    number_of_seats INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL
);

INSERT INTO events (event_name, available_seats)
VALUES
('ICT Conference', 50),
('Tech Innovation Day', 10),
('Student Awards Night', 0);


-- 2. IF ELSIF ELSE


DO $$
DECLARE
    v_seats INTEGER;
BEGIN
    SELECT available_seats
    INTO v_seats
    FROM events
    WHERE event_id = 1;

    IF v_seats = 0 THEN
        RAISE NOTICE 'Event is full.';
    ELSIF v_seats <= 10 THEN
        RAISE NOTICE 'Event is nearly full.';
    ELSE
        RAISE NOTICE 'Event has plenty of seats.';
    END IF;
END $$;


-- 3. WHILE AND NUMERIC FOR


DO $$
DECLARE
    reminder_day INTEGER := 1;
BEGIN
    WHILE reminder_day <= 3 LOOP
        RAISE NOTICE 'Booking Reminder Day: %', reminder_day;
        reminder_day := reminder_day + 1;
    END LOOP;

    FOR entrance_check IN 1..3 LOOP
        RAISE NOTICE 'Entrance Check Number: %', entrance_check;
    END LOOP;
END $$;

--
-- 4. BOOK SEATS PROCEDURE


CREATE OR REPLACE PROCEDURE book_seats(
    p_event_id INTEGER,
    p_student_number VARCHAR,
    p_number_of_seats INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INTEGER;
BEGIN
    IF p_number_of_seats <= 0 THEN
        RAISE EXCEPTION 'Number of seats must be greater than zero.';
    END IF;

    SELECT available_seats
    INTO v_available
    FROM events
    WHERE event_id = p_event_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Event does not exist.';
        RETURN;
    END IF;

    IF v_available >= p_number_of_seats THEN

        UPDATE events
        SET available_seats =
            available_seats - p_number_of_seats
        WHERE event_id = p_event_id;

        INSERT INTO bookings
            (event_id, student_number, number_of_seats, status)
        VALUES
            (p_event_id, p_student_number, p_number_of_seats, 'BOOKED');

        RAISE NOTICE 'Seats successfully booked.';

    ELSE
        RAISE NOTICE
            'Booking rejected. Only % seats are available.',
            v_available;
    END IF;
END;
$$;


-- 5. TWO VALID + ONE EXCEEDING


CALL book_seats(1, '202406887', 5);
CALL book_seats(2, '202400442', 3);
CALL book_seats(3, '202407887', 5);

SELECT * FROM events;
SELECT * FROM bookings;


-- 6. CANCEL BOOKING PROCEDURE


CREATE OR REPLACE PROCEDURE cancel_booking(
    p_booking_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_event_id INTEGER;
    v_seats INTEGER;
    v_status VARCHAR(20);
BEGIN
    SELECT event_id, number_of_seats, status
    INTO v_event_id, v_seats, v_status
    FROM bookings
    WHERE booking_id = p_booking_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Booking does not exist.';
        RETURN;
    END IF;

    IF v_status = 'BOOKED' THEN

        UPDATE events
        SET available_seats = available_seats + v_seats
        WHERE event_id = v_event_id;

        UPDATE bookings
        SET status = 'CANCELLED'
        WHERE booking_id = p_booking_id;

        RAISE NOTICE 'Booking cancelled successfully.';

    ELSE
        RAISE NOTICE
            'Booking already cancelled. Seats not restored again.';
    END IF;
END;
$$;

CALL cancel_booking(1);
CALL cancel_booking(1);


-- 7. EXPLICIT CURSOR


DO $$
DECLARE
    event_cursor CURSOR FOR
        SELECT event_id, event_name, available_seats
        FROM events
        WHERE available_seats <= 10;

    v_id INTEGER;
    v_name VARCHAR(100);
    v_seats INTEGER;
BEGIN
    OPEN event_cursor;

    LOOP
        FETCH event_cursor
        INTO v_id, v_name, v_seats;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Event: %, Available Seats: %',
            v_name, v_seats;
    END LOOP;

    CLOSE event_cursor;
END $$;


-- 8. ZERO SEATS EXCEPTION


DO $$
BEGIN
    BEGIN
        CALL book_seats(1, 'STU004', 0);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Invalid seat quantity handled: %', SQLERRM;
    END;
END $$;


-- 9. FINAL QUERIES


SELECT * FROM events ORDER BY event_id;

SELECT * FROM bookings ORDER BY booking_id;