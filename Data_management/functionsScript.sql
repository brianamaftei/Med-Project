CREATE OR REPLACE FUNCTION get_drugs_for_condition(_conditionID INT)
    RETURNS TABLE
            (
                DrugID   INT,
                DrugName VARCHAR
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT d.DrugID, d.DrugName
        FROM Drugs d
                 INNER JOIN ConditionsDrugs cd ON d.DrugID = cd.DrugID
        WHERE cd.ConditionID = _conditionID;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE insert_prescription(_prescriptionDate DATE, _patientID INT, _doctorID INT, _drugs INT[])
    LANGUAGE plpgsql AS
$$
DECLARE
    _prescriptionID INT;
    _drug           INT;
BEGIN
    INSERT INTO Prescriptions(PrescriptionDate, PatientID, DoctorID)
    VALUES (_prescriptionDate, _patientID, _doctorID)
    RETURNING PrescriptionID INTO _prescriptionID;

    FOREACH _drug IN ARRAY _drugs
        LOOP
            INSERT INTO PrescriptionsDrugs(PrescriptionID, DrugID, Quantity) VALUES (_prescriptionID, _drug, 1);
        END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION get_prescriptions_count_for_doctor(_doctorID INT) RETURNS INT AS
$$
DECLARE
    _count INT;
BEGIN
    SELECT COUNT(*) INTO _count FROM Prescriptions WHERE DoctorID = _doctorID;
    RETURN _count;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE import_data_from_json(json_data JSON)
    LANGUAGE plpgsql AS
$$
DECLARE
    _record record;
BEGIN
    FOR _record IN SELECT * FROM json_to_recordset(json_data -> 'drugs') AS x(drugname text, description text)
        LOOP
            INSERT INTO Drugs(DrugName, Description)
            VALUES (_record.drugname, _record.description);
        END LOOP;

    FOR _record IN SELECT * FROM json_to_recordset(json_data -> 'conditions') AS x(conditionname text, description text)
        LOOP
            INSERT INTO MedicalConditions(ConditionName, Description)
            VALUES (_record.conditionname, _record.description);
        END LOOP;

    FOR _record IN SELECT *
                   FROM json_to_recordset(json_data -> 'doctors') AS x(firstname text, lastname text, specialization text)
        LOOP
            INSERT INTO Doctors(FirstName, LastName, Specialization)
            VALUES (_record.firstname, _record.lastname, _record.specialization);
        END LOOP;

    FOR _record IN SELECT *
                   FROM json_to_recordset(json_data -> 'patients') AS x(firstname text, lastname text, dob date, gender text)
        LOOP
            INSERT INTO Patients(FirstName, LastName, DOB, Gender)
            VALUES (_record.firstname, _record.lastname, _record.dob, _record.gender);
        END LOOP;

END;
$$;

CREATE OR REPLACE PROCEDURE assign_drugs_to_conditions_and_prescriptions()
    LANGUAGE plpgsql AS
$$
DECLARE
    _conditionDrugs RECORD;
    _prescriptions  RECORD;
BEGIN
    FOR _conditionDrugs IN
        SELECT c.ConditionID, d.DrugID
        FROM MedicalConditions c,
             Drugs d
        WHERE c.ConditionID >= 1
          AND d.DrugID >= 1
        ORDER BY RANDOM()
        LIMIT 10
        LOOP
            BEGIN
                INSERT INTO ConditionsDrugs (ConditionID, DrugID)
                VALUES (_conditionDrugs.ConditionID, _conditionDrugs.DrugID);
            EXCEPTION
                WHEN unique_violation THEN
                    CONTINUE;
            END;
        END LOOP;

    FOR _prescriptions IN
        SELECT p.PrescriptionID, d.DrugID
        FROM Prescriptions p,
             Drugs d
        WHERE p.PatientID >= 1
          AND d.DrugID >= 1
        ORDER BY RANDOM()
        LIMIT 10
        LOOP
            BEGIN
                INSERT INTO PrescriptionsDrugs (PrescriptionID, DrugID, Quantity)
                VALUES (_prescriptions.PrescriptionID, _prescriptions.DrugID, 1);
            EXCEPTION
                WHEN unique_violation THEN
                    CONTINUE;
            END;
        END LOOP;


END;
$$;

CREATE OR REPLACE PROCEDURE create_random_prescription()
    LANGUAGE plpgsql AS
$$
DECLARE
    _patientID      INT;
    _doctorID       INT;
    _prescriptionID INT;
    _drug           RECORD;
BEGIN
    SELECT PatientID
    INTO _patientID
    FROM Patients
    ORDER BY RANDOM()
    LIMIT 1;

    SELECT DoctorID
    INTO _doctorID
    FROM Doctors
    ORDER BY RANDOM()
    LIMIT 1;

    INSERT INTO Prescriptions (PrescriptionDate, PatientID, DoctorID)
    VALUES (CURRENT_DATE, _patientID, _doctorID)
    RETURNING PrescriptionID INTO _prescriptionID;

    FOR _drug IN
        SELECT DrugID
        FROM Drugs
        ORDER BY RANDOM()
        LIMIT 3
        LOOP
            INSERT INTO PrescriptionsDrugs (PrescriptionID, DrugID, Quantity)
            VALUES (_prescriptionID, _drug.DrugID, 1);
        END LOOP;


    RAISE NOTICE 'Created prescription with ID: %', _prescriptionID;
END;
$$;

CREATE OR REPLACE PROCEDURE empty_all_tables()
    LANGUAGE plpgsql AS
$$
BEGIN
    TRUNCATE TABLE PrescriptionsDrugs cascade;
    TRUNCATE TABLE ConditionsDrugs cascade;
    TRUNCATE TABLE Prescriptions cascade;
    TRUNCATE TABLE MedicalConditions cascade;
    TRUNCATE TABLE Drugs cascade;
    TRUNCATE TABLE Doctors cascade;
    TRUNCATE TABLE Patients cascade;

    ALTER SEQUENCE Prescriptions_PrescriptionID_seq RESTART WITH 1;
    ALTER SEQUENCE MedicalConditions_ConditionID_seq RESTART WITH 1;
    ALTER SEQUENCE Drugs_DrugID_seq RESTART WITH 1;
    ALTER SEQUENCE Doctors_DoctorID_seq RESTART WITH 1;
    ALTER SEQUENCE Patients_PatientID_seq RESTART WITH 1;

    RAISE NOTICE 'All tables have been emptied.';
END;
$$;

CREATE OR REPLACE PROCEDURE generate_random_doctor()
    LANGUAGE plpgsql AS
$$
DECLARE
    _doctorID INT;
BEGIN
    INSERT INTO Doctors (FirstName, LastName, Specialization)
    SELECT LEFT(MD5(RANDOM()::text), 6),
           LEFT(MD5(RANDOM()::text), 6),
           LEFT(MD5(RANDOM()::text), 12)
    RETURNING DoctorID INTO _doctorID;

    RAISE NOTICE 'Generated doctor with ID: %', _doctorID;
END;
$$;

CREATE OR REPLACE PROCEDURE generate_random_patient() LANGUAGE plpgsql AS $$
DECLARE
    _patientID INT;
BEGIN
    INSERT INTO Patients (FirstName, LastName, DOB, Gender)
    SELECT
        LEFT(MD5(RANDOM()::text), 6),
        LEFT(MD5(RANDOM()::text), 6),
        (CURRENT_DATE - (RANDOM() * INTERVAL '100 years'))::date,
        CASE WHEN RANDOM() < 0.5 THEN 'Male' ELSE 'Female' END
    RETURNING PatientID INTO _patientID;

    RAISE NOTICE 'Generated patient with ID: %', _patientID;
END;
$$;


CREATE OR REPLACE PROCEDURE generate_random_drug()
    LANGUAGE plpgsql AS
$$
DECLARE
    _drugID INT;
BEGIN
    INSERT INTO Drugs (DrugName, Description)
    SELECT LEFT(MD5(RANDOM()::text), 10),
           LEFT(MD5(RANDOM()::text), 20)
    RETURNING DrugID INTO _drugID;

    RAISE NOTICE 'Generated drug with ID: %', _drugID;
END;
$$;
CREATE OR REPLACE PROCEDURE generate_random_medical_condition()
    LANGUAGE plpgsql AS
$$
DECLARE
    _conditionID INT;
BEGIN
    INSERT INTO MedicalConditions (ConditionName, Description)
    SELECT LEFT(MD5(RANDOM()::text), 8),
           LEFT(MD5(RANDOM()::text), 30)
    RETURNING ConditionID INTO _conditionID;

    RAISE NOTICE 'Generated medical condition with ID: %', _conditionID;
END;
$$;