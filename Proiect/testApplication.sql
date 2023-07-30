DO $$
DECLARE
    _drugID INT;
    _conditionID INT;
    _doctorID INT;
    _patientID INT;
    _prescriptionID INT;
    _drug RECORD;
BEGIN
    -- Insert a new drug
    INSERT INTO Drugs(DrugName, Description) VALUES('Test Drug', 'This is a test drug.') RETURNING DrugID INTO _drugID;

    -- Insert a new condition
    INSERT INTO MedicalConditions(ConditionName, Description) VALUES('Test Condition', 'This is a test condition.') RETURNING ConditionID INTO _conditionID;

    -- Insert a new doctor
    INSERT INTO Doctors(FirstName, LastName, Specialization) VALUES('Test', 'Doctor', 'General Practice') RETURNING DoctorID INTO _doctorID;

    -- Insert a new patient
    INSERT INTO Patients(FirstName, LastName, DOB, Gender) VALUES('Test', 'Patient', '2000-01-01', 'Male') RETURNING PatientID INTO _patientID;

    -- Link the new drug and condition
    INSERT INTO ConditionsDrugs(ConditionID, DrugID) VALUES(_conditionID, _drugID);

    -- Insert a new prescription
    INSERT INTO Prescriptions(PrescriptionDate, PatientID, DoctorID) VALUES(CURRENT_DATE, _patientID, _doctorID) RETURNING PrescriptionID INTO _prescriptionID;

    -- Link the new prescription and drug
    INSERT INTO PrescriptionsDrugs(PrescriptionID, DrugID, Quantity) VALUES(_prescriptionID, _drugID, 1);

    -- Test get_drugs_for_condition function
    FOR _drug IN (SELECT * FROM get_drugs_for_condition(_conditionID))
    LOOP
        RAISE NOTICE 'Drug for condition %: %', _conditionID, _drug.drugname;
    END LOOP;

    -- Test get_prescriptions_count_for_doctor function
    RAISE NOTICE 'Prescriptions count for doctor %: %', _doctorID, get_prescriptions_count_for_doctor(_doctorID);

END;
$$ LANGUAGE plpgsql;

select * from conditionsdrugs;
select * from prescriptions;
select * from drugs;
select * from medicalconditions;
select * from doctors;
select * from patients;
select * from prescriptionsdrugs;

CALL import_data_from_json(CAST(pg_read_file('C:/Users/pinza/Desktop/data.json') AS JSON));



CALL empty_all_tables();
CALL assign_drugs_to_conditions_and_prescriptions();
CALL create_random_prescription();
CALL generate_random_doctor();
CALL generate_random_patient();
CALL generate_random_drug();
CALL generate_random_medical_condition();
