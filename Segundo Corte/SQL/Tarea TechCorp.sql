/* LA GRAN EMPRESA DE LOS DATOS - TechCorp
   Base de datos de empleados con datos simulados (15 registros)
   Ingeniería de datos - MySQL */

-- 0. Estructura de la base de datos
create database TechCorp;
use TechCorp;

create table empleados(
idEmpleado int primary key auto_increment,
nombreEmpleado varchar(100) not null,
edadEmpleado int not null,
departamentoEmpleado varchar(60) not null,
salarioEmpleado decimal(10,2) not null,
fechaContratacion date not null
);

describe empleados;

-- 1. Inserción de datos simulados (15 registros)
-- el campo idEmpleado es autoincrement, por eso no se envía
insert into empleados (nombreEmpleado,edadEmpleado,departamentoEmpleado,salarioEmpleado,fechaContratacion)
values
('Ana Torres',28,'Ventas',3200,'2021-03-15'),
('Carlos Ramírez',35,'IT',5200,'2019-07-01'),
('Andrés Gómez',41,'Finanzas',6100,'2017-02-20'),
('Camila Rojas',30,'Marketing',3800,'2022-05-10'),
('Laura Martínez',26,'Ventas',2900,'2023-01-09'),
('Julián Herrera',38,'IT',4700,'2020-11-23'),
('Sofía Castro',33,'Recursos Humanos',4100,'2018-09-03'),
('Miguel Ángel Díaz',45,'Finanzas',7500,'2015-06-18'),
('Alejandra Vargas',31,'Ventas',3600,'2020-02-14'),
('Daniel Pardo',29,'IT',4300,'2021-08-30'),
('Valentina Mejía',36,'Marketing',4500,'2019-10-07'),
('Cristian Salazar',40,'Ventas',4200,'2016-04-25'),
('Paula Ortiz',24,'Recursos Humanos',2600,'2024-02-05'),
('Andrea Niño',34,'IT',5800,'2022-01-17'),
('Felipe Cárdenas',52,'Finanzas',6900,'2014-12-01');

-- consulta general para verificar la carga
select * from empleados;

-- 2. RETOS

-- Reto 1. Lista de empleados: nombres, edades y salarios
select nombreEmpleado as Nombre, edadEmpleado as Edad, salarioEmpleado as Salario
from empleados;

-- Reto 2. Altos ingresos: empleados que ganan más de $4,000
select nombreEmpleado as Nombre, salarioEmpleado as Salario
from empleados
where salarioEmpleado>4000
order by salarioEmpleado desc;

-- Reto 3. Fuerza de ventas: empleados del departamento de Ventas
select * from empleados
where departamentoEmpleado='Ventas';

-- Reto 4. Rango de edad: empleados entre 30 y 40 años
select nombreEmpleado as Nombre, edadEmpleado as Edad
from empleados
where edadEmpleado between 30 and 40
order by edadEmpleado asc;

-- Reto 5. Nuevas contrataciones: contratados después del año 2020
select nombreEmpleado as Nombre, fechaContratacion as Fecha_Contratacion
from empleados
where fechaContratacion>'2020-12-31'
order by fechaContratacion asc;

-- Reto 6. Distribución de empleados: cantidad de empleados por departamento
select departamentoEmpleado as Departamento,
count(*) as Cantidad
from empleados
group by departamentoEmpleado
order by Cantidad desc;

-- Reto 7. Análisis salarial: salario promedio de la empresa
select avg(salarioEmpleado) as PromedioSalario
from empleados;

-- Reto 8. Nombres selectivos: nombres que comienzan con "A" o "C"
select nombreEmpleado as Nombre, departamentoEmpleado as Departamento
from empleados
where nombreEmpleado like 'A%' or nombreEmpleado like 'C%'
order by nombreEmpleado asc;

-- Reto 9. Departamentos específicos: empleados que no pertenecen a IT
select * from empleados
where departamentoEmpleado<>'IT';

-- Reto 10. El mejor pagado: empleado con el salario más alto
select nombreEmpleado as Nombre, departamentoEmpleado as Departamento, salarioEmpleado as Salario
from empleados
order by salarioEmpleado desc
limit 1;

-- Verificación del salario máximo con función calculada
select max(salarioEmpleado) as SalarioMaximo
from empleados;
