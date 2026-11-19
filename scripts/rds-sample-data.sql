CREATE DATABASE IF NOT EXISTS dr_project;
USE dr_project;
CREATE TABLE IF NOT EXISTS employees (
  employee_id INT PRIMARY KEY,
  employee_name VARCHAR(100),
  department VARCHAR(100),
  location VARCHAR(100)
);
INSERT INTO employees VALUES
 (1, 'Atharv',         'IT',                'Mumbai'),
 (2, 'Employee Two',   'Cloud Operations',  'Pune'),
 (3, 'Employee Three', 'DevOps',            'Singapore');
SELECT * FROM employees;
