

DROP PROCEDURE IF EXISTS dispense_medicine(IN INTEGER, IN VARCHAR, IN INTEGER);
DROP PROCEDURE IF EXISTS reverse_dispensing(IN INTEGER);

DROP TABLE IF EXISTS dispensing_records;
DROP TABLE IF EXISTS medicines;



CREATE TABLE medicines (
    medicine_id SERIAL PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL,
    stock_quantity INTEGER NOT NULL
        CHECK (stock_quantity >= 0)
);

CREATE TABLE dispensing_records (
    record_id SERIAL PRIMARY KEY,
    medicine_id INTEGER REFERENCES medicines(medicine_id),
    student_number VARCHAR(30) NOT NULL,
    quantity INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL
);

INSERT INTO medicines (medicine_name, stock_quantity)
VALUES
('Paracetamol', 20),
('Amoxicillin', 5),
('Ibuprofen', 2);



DO $$
DECLARE
    v_stock INTEGER;
BEGIN
    SELECT stock_quantity
    INTO v_stock
    FROM medicines
    WHERE medicine_id = 1;

    IF v_stock = 0 THEN
        RAISE NOTICE 'Medicine is out of stock.';
    ELSIF v_stock <= 5 THEN
        RAISE NOTICE 'Medicine is low on stock.';
    ELSE
        RAISE NOTICE 'Medicine is sufficiently stocked.';
    END IF;
END $$;



DO $$
DECLARE
    review_day INTEGER := 1;
BEGIN
    WHILE review_day <= 3 LOOP
        RAISE NOTICE 'Stock Review Day: %', review_day;
        review_day := review_day + 1;
    END LOOP;

    FOR shelf_number IN 1..3 LOOP
        RAISE NOTICE 'Shelf Inspection Number: %', shelf_number;
    END LOOP;
END $$;



CREATE OR REPLACE PROCEDURE dispense_medicine(
    p_medicine_id INTEGER,
    p_student_number VARCHAR,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock INTEGER;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Dispensing quantity must be greater than zero.';
    END IF;

    SELECT stock_quantity
    INTO v_stock
    FROM medicines
    WHERE medicine_id = p_medicine_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Medicine does not exist.';
        RETURN;
    END IF;

    IF v_stock >= p_quantity THEN

        UPDATE medicines
        SET stock_quantity = stock_quantity - p_quantity
        WHERE medicine_id = p_medicine_id;

        INSERT INTO dispensing_records
            (medicine_id, student_number, quantity, status)
        VALUES
            (p_medicine_id, p_student_number, p_quantity, 'DISPENSED');

        RAISE NOTICE 'Medicine successfully dispensed.';

    ELSE
        RAISE NOTICE
            'Dispensing rejected. Only % units available.',
            v_stock;
    END IF;
END;
$$;



CALL dispense_medicine(1, '202400442', 5);
CALL dispense_medicine(2, '202406887', 2);
CALL dispense_medicine(3, '202406888', 10);

SELECT * FROM medicines;
SELECT * FROM dispensing_records;



CREATE OR REPLACE PROCEDURE reverse_dispensing(
    p_record_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_medicine_id INTEGER;
    v_quantity INTEGER;
    v_status VARCHAR(20);
BEGIN
    SELECT medicine_id, quantity, status
    INTO v_medicine_id, v_quantity, v_status
    FROM dispensing_records
    WHERE record_id = p_record_id;

    IF NOT FOUND THEN
        RAISE NOTICE 'Dispensing record does not exist.';
        RETURN;
    END IF;

    IF v_status = 'DISPENSED' THEN

        UPDATE medicines
        SET stock_quantity = stock_quantity + v_quantity
        WHERE medicine_id = v_medicine_id;

        UPDATE dispensing_records
        SET status = 'REVERSED'
        WHERE record_id = p_record_id;

        RAISE NOTICE 'Dispensing successfully reversed.';

    ELSE
        RAISE NOTICE
            'Record has already been reversed. Stock not restored again.';
    END IF;
END;
$$;

CALL reverse_dispensing(1);
CALL reverse_dispensing(1);



DO $$
DECLARE
    medicine_cursor CURSOR FOR
        SELECT medicine_id, medicine_name, stock_quantity
        FROM medicines
        WHERE stock_quantity < 5;

    v_id INTEGER;
    v_name VARCHAR(100);
    v_stock INTEGER;
BEGIN
    OPEN medicine_cursor;

    LOOP
        FETCH medicine_cursor
        INTO v_id, v_name, v_stock;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Medicine: %, Stock: %',
            v_name, v_stock;
    END LOOP;

    CLOSE medicine_cursor;
END $$;



DO $$
BEGIN
    BEGIN
        CALL dispense_medicine(1, 'STU004', -2);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Invalid negative quantity handled: %', SQLERRM;
    END;
END $$;



SELECT * FROM medicines ORDER BY medicine_id;

SELECT * FROM dispensing_records ORDER BY record_id;