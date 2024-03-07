CREATE TABLE Drugs
(
    DrugID      serial PRIMARY KEY,
    DrugName    VARCHAR(100),
    Description TEXT
);
CREATE TABLE Doctors (
    DoctorID serial PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Specialization VARCHAR(100)
);
CREATE TABLE Patients (
    PatientID serial PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    DOB DATE,
    Gender VARCHAR(10)
);
CREATE TABLE MedicalConditions
(
    ConditionID   serial PRIMARY KEY,
    ConditionName VARCHAR(100),
    Description   TEXT
);
CREATE TABLE Prescriptions
(
    PrescriptionID   serial PRIMARY KEY,
    PrescriptionDate DATE,
    PatientID        int REFERENCES Doctors(DoctorID),
    DoctorID         int REFERENCES Patients(PatientID),
    Note             TEXT
);
CREATE TABLE ConditionsDrugs
(
    ConditionID int REFERENCES MedicalConditions (ConditionID),
    DrugID      int REFERENCES Drugs (DrugID),
    PRIMARY KEY (ConditionID, DrugID)
);
CREATE TABLE PrescriptionsDrugs
(
    PrescriptionID int REFERENCES Prescriptions (PrescriptionID),
    DrugID         int REFERENCES Drugs (DrugID),
    Quantity       int,
    PRIMARY KEY (PrescriptionID, DrugID)
);