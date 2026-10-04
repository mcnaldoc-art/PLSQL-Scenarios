-- ============================================================
-- ICT371 SCENARIO 3
-- STUDENT HOSTEL ROOM ALLOCATION
-- Student Number: YOUR_STUDENT_NUMBER
-- ============================================================

DROP PROCEDURE IF EXISTS allocate_room(IN INTEGER, IN VARCHAR);
DROP PROCEDURE IF EXISTS check_out(IN INTEGER);

DROP TABLE IF EXISTS allocations;
DROP TABLE IF EXISTS hostel_rooms;

-- ============================================================
-- 1. CREATE TABLES
-- ============================================================

CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(20) NOT NULL,
    available_bed_spaces INTEGER NOT NULL
        CHECK (available_bed_spaces >= 0)
);

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(30) NOT NULL,
    room_id INTEGER REFERENCES hostel_rooms(room_id),
    status VARCHAR(20) NOT NULL
);

INSERT INTO hostel_rooms (room_number, available_bed_spaces)
VALUES
('A101', 4),
('A102', 1),
('A103', 0);

-- ============================================================
-- 2. IF ELSIF ELSE
-- ============================================================

DO $$
DECLARE
    v_spaces INTEGER;
BEGIN
    SELECT available_bed_spaces
    INTO v_spaces
    FROM hostel_rooms
    WHERE room_id = 1;

    IF v_spaces = 0 THEN
        RAISE NOTICE 'Room is full.';
    ELSIF v_spaces = 1 THEN
        RAISE NOTICE 'Room has one space left.';
    ELSE
        RAISE NOTICE 'Room has several spaces available.';
    END IF;
END $$;

-- ============================================================
-- 3. WHILE AND NUMERIC FOR
-- ============================================================

DO $$
DECLARE
    inspection_day INTEGER := 1;
BEGIN
    WHILE inspection_day <= 3 LOOP
        RAISE NOTICE 'Hostel Inspection Day: %', inspection_day;
        inspection_day := inspection_day + 1;
    END LOOP;

    FOR room_check IN 1..3 LOOP
        RAISE NOTICE 'Room Check Number: %', room_check;
    END LOOP;
END $$;

-- ============================================================
-- 4. ALLOCATE ROOM PROCEDURE
-- ============================================================

CREATE OR REPLACE PROCEDURE allocate_room(
    p_room_id INTEGER,
    p_student_number VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_spaces INTEGER;
BEGIN
    IF p_student_number IS NULL OR TRIM(p_student_number) = '' THEN
        RAISE EXCEPTION 'Student number cannot be blank.';
    END IF;

    SELECT available_bed_spaces
    INTO v_spaces
    FROM hostel_rooms
    WHERE room_id = p_room_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Room does not exist.';
        RETURN;
    END IF;

    IF v_spaces > 0 THEN

        UPDATE hostel_rooms
        SET available_bed_spaces = available_bed_spaces - 1
        WHERE room_id = p_room_id;

        INSERT INTO allocations
            (student_number, room_id, status)
        VALUES
            (p_student_number, p_room_id, 'ALLOCATED');

        RAISE NOTICE 'Room successfully allocated.';

    ELSE
        RAISE NOTICE 'Allocation rejected. Room is full.';
    END IF;
END;
$$;

-- ============================================================
-- 5. TWO VALID + ONE FULL ROOM
-- ============================================================

CALL allocate_room(1, '202406887');
CALL allocate_room(2, '202400442');
CALL allocate_room(3, '202406887');

SELECT * FROM hostel_rooms;
SELECT * FROM allocations;

-- ============================================================
-- 6. CHECK OUT PROCEDURE
-- ============================================================

CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_room_id INTEGER;
    v_status VARCHAR(20);
BEGIN
    SELECT room_id, status
    INTO v_room_id, v_status
    FROM allocations
    WHERE allocation_id = p_allocation_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Allocation does not exist.';
        RETURN;
    END IF;

    IF v_status = 'ALLOCATED' THEN

        UPDATE hostel_rooms
        SET available_bed_spaces = available_bed_spaces + 1
        WHERE room_id = v_room_id;

        UPDATE allocations
        SET status = 'CHECKED_OUT'
        WHERE allocation_id = p_allocation_id;

        RAISE NOTICE 'Student checked out successfully.';

    ELSE
        RAISE NOTICE 'Allocation already completed. Bed space not restored.';
    END IF;
END;
$$;

CALL check_out(1);
CALL check_out(1);

-- ============================================================
-- 7. EXPLICIT CURSOR
-- ============================================================

DO $$
DECLARE
    room_cursor CURSOR FOR
        SELECT room_id, room_number, available_bed_spaces
        FROM hostel_rooms
        WHERE available_bed_spaces <= 1;

    v_room_id INTEGER;
    v_room_number VARCHAR(20);
    v_spaces INTEGER;
BEGIN
    OPEN room_cursor;

    LOOP
        FETCH room_cursor
        INTO v_room_id, v_room_number, v_spaces;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Room %, Available Spaces: %',
            v_room_number, v_spaces;
    END LOOP;

    CLOSE room_cursor;
END $$;

-- ============================================================
-- 8. BLANK STUDENT NUMBER EXCEPTION
-- ============================================================

DO $$
BEGIN
    BEGIN
        CALL allocate_room(1, '');

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Invalid student number handled: %', SQLERRM;
    END;
END $$;

-- ============================================================
-- 9. FINAL QUERIES
-- ============================================================

SELECT * FROM hostel_rooms ORDER BY room_id;

SELECT * FROM allocations ORDER BY allocation_id;