package org.example;

import java.sql.*;
import java.util.Scanner;

public class Main {
    private static final String DB_URL = "jdbc:postgresql://localhost:5432/pharmacy";
    private static final String DB_USER = "postgres";
    private static final String DB_PASSWORD = "password";


    public static void main(String[] args) {
        try (Connection connection = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            System.out.println("Connected to the database");

            Scanner scanner = new Scanner(System.in);

            boolean exit = false;
            System.out.println("Enter a digit to execute a command (0 to exit):");
            System.out.println("1. Assign Drugs to Conditions and Prescriptions");
            System.out.println("2. Create Random Prescription");
            System.out.println("3. Empty All Tables");
            System.out.println("4. Generate Random Doctor");
            System.out.println("5. Generate Random Patient");
            System.out.println("6. Generate Random Drug");
            System.out.println("7. Generate Random Medical Condition");
            System.out.println("8. SELECT from conditionsdrugs");
            System.out.println("9. SELECT from prescriptions");
            System.out.println("10. SELECT from drugs");
            System.out.println("11. SELECT from medicalconditions");
            System.out.println("12. SELECT from doctors");
            System.out.println("13. SELECT from patients");
            System.out.println("14. SELECT from prescriptionsdrugs");
            System.out.println("0. Exit");
            System.out.println();

            while (!exit) {

                int input = scanner.nextInt();

                switch (input) {
                    case 0 -> exit = true;
                    case 1 -> callProcedure(connection, "assign_drugs_to_conditions_and_prescriptions");
                    case 2 -> callProcedure(connection, "create_random_prescription");
                    case 3 -> callProcedure(connection, "empty_all_tables");
                    case 4 -> callProcedure(connection, "generate_random_doctor");
                    case 5 -> callProcedure(connection, "generate_random_patient");
                    case 6 -> callProcedure(connection, "generate_random_drug");
                    case 7 -> callProcedure(connection, "generate_random_medical_condition");
                    case 8 -> executeSelect(connection, "SELECT * FROM conditionsdrugs");
                    case 9 -> executeSelect(connection, "SELECT * FROM prescriptions");
                    case 10 -> executeSelect(connection, "SELECT * FROM drugs");
                    case 11 -> executeSelect(connection, "SELECT * FROM medicalconditions");
                    case 12 -> executeSelect(connection, "SELECT * FROM doctors");
                    case 13 -> executeSelect(connection, "SELECT * FROM patients");
                    case 14 -> executeSelect(connection, "SELECT * FROM prescriptionsdrugs");
                    default -> System.out.println("Invalid input. Please try again.");
                }
            }

            scanner.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private static void callProcedure(Connection connection, String procedureName) throws SQLException {
        try (CallableStatement statement = connection.prepareCall("CALL " + procedureName + "()")) {
            statement.execute();
            System.out.println("Called procedure: " + procedureName);
        }
    }

    private static void executeSelect(Connection connection, String query) throws SQLException {
        try (Statement statement = connection.createStatement()) {
            ResultSet resultSet = statement.executeQuery(query);
            ResultSetMetaData metaData = resultSet.getMetaData();
            int columnCount = metaData.getColumnCount();

            for (int i = 1; i <= columnCount; i++) {
                System.out.print(metaData.getColumnName(i) + "\t");
            }
            System.out.println();

            while (resultSet.next()) {
                for (int i = 1; i <= columnCount; i++) {
                    System.out.print(resultSet.getString(i) + "\t");
                }
                System.out.println();
            }

            resultSet.close();
        }
    }
}
