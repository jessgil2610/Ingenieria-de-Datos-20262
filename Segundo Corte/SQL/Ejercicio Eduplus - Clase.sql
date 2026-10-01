/* CONSULTAS MULTITABLA SUBCONSULTAS Y FUNCIONES*/
/*Situación: “El Miercoles del gerente” */
/*Trabajas como desarrollador en TecnoAndes, una 
tienda de tecnología. 
El sistema de ventas guarda la información en 
cinco tablas: clientes, vendedores, productos, pedidos 
y detalle_pedido. 
El miercoles a las 8:00 el gerente te escribe por el chat:
1.	“¿Qué clientes han comprado? clientes pedido (FK de clientes)”
2.	“¿Qué productos compró cada cliente?” detalle_pedido 
3.	“¿Qué vendedor vendió más?”
4.	“¿Cuáles productos cuestan más que el promedio?”
5.	“¿Cuánto hemos vendido en total?”
6.	“¿Qué clientes se registraron y nunca compraron? Quiero llamarlos.”
Necesita todo antes de la reunión de las 10:00.*/

CREATE DATABASE IF NOT EXISTS ventas_join CHARACTER SET utf8mb4;
USE ventas_join;

CREATE TABLE clientes (
  id             INT AUTO_INCREMENT PRIMARY KEY,   -- PK: identifica a cada cliente
  nombre         VARCHAR(50)  NOT NULL,
  apellido       VARCHAR(50)  NOT NULL,
  email          VARCHAR(100) NOT NULL UNIQUE,
  ciudad         VARCHAR(50),
  fecha_registro DATE         NOT NULL
);

CREATE TABLE vendedores (
  id     INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  zona   VARCHAR(30)  NOT NULL
);

CREATE TABLE productos (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  nombre    VARCHAR(100)  NOT NULL,
  categoria VARCHAR(50)   NOT NULL,
  precio    DECIMAL(12,2) NOT NULL
);

CREATE TABLE pedidos (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  cliente_id  INT  NOT NULL,                        -- FK hacia clientes
  vendedor_id INT  NULL,                            -- FK opcional: venta online = NULL
  fecha       DATE NOT NULL,
  CONSTRAINT fk_pedidos_cliente  FOREIGN KEY (cliente_id)  REFERENCES clientes(id),
  CONSTRAINT fk_pedidos_vendedor FOREIGN KEY (vendedor_id) REFERENCES vendedores(id)
);

CREATE TABLE detalle_pedido (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  pedido_id       INT           NOT NULL,
  producto_id     INT           NOT NULL,
  cantidad        INT           NOT NULL,
  precio_unitario DECIMAL(12,2) NOT NULL,           -- precio al momento de la venta
  CONSTRAINT fk_detalle_pedido   FOREIGN KEY (pedido_id)   REFERENCES pedidos(id),
  CONSTRAINT fk_detalle_producto FOREIGN KEY (producto_id) REFERENCES productos(id)
);

INSERT INTO clientes (nombre, apellido, email, ciudad, fecha_registro) VALUES
  ('Ana',   'Torres',  'ana@correo.com',   'Bogotá',       '2025-01-15'),
  ('Luis',  'Pérez',   'luis@correo.com',  'Medellín',     '2025-03-02'),
  ('Marta', 'Gómez',   'marta@correo.com', 'Cali',         '2025-06-20'),
  ('Sofía', 'Ramírez', 'sofia@correo.com', 'Bogotá',       '2026-02-10'),    ('Diego', 'Castro',  'diego@correo.com', 'Barranquilla', '2026-05-05');  INSERT INTO vendedores (nombre, zona) VALUES
  ('Carlos Ruiz', 'Norte'),
  ('Diana León',  'Sur'),
  ('Laura Mesa',  'Centro');   

INSERT INTO productos (nombre, categoria, precio) VALUES
  ('Portátil 14"',        'Computadores', 2500000.00),
  ('Mouse inalámbrico',   'Accesorios',     60000.00),
  ('Monitor 24"',         'Pantallas',     700000.00),
  ('Teclado mecánico',    'Accesorios',    250000.00),
  ('Audífonos Bluetooth', 'Accesorios',    180000.00),
  ('Tablet 10"',          'Computadores', 1200000.00);  
  
  
INSERT INTO pedidos (cliente_id, vendedor_id, fecha) VALUES
  (1, 1,    '2026-07-05'),
  (2, 2,    '2026-07-18'),
  (1, 2,    '2026-08-02'),
  (3, 1,    '2026-08-15'),
  (2, 1,    '2026-09-01'),
  (3, null, '2026-09-10');   
  
  

INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
  (1, 1, 1, 2500000.00),
  (2, 2, 2,   60000.00),
  (3, 3, 2,  700000.00),
  (4, 4, 1,  250000.00),
  (5, 5, 1,  180000.00),
  (6, 2, 3,   60000.00),
  (7, 3, 1,  700000.00),
  (8, 1, 1, 2500000.00),
  (9, 5, 2,  180000.00),
  (10, 4, 2,  250000.00);
  
  /*consulta multitabla
  
  consulta que lee columnas en minimo dos o mas tablas en un solo proceso
  
  Una base bien diseñada (normalizada) no repite datos: 
  el pedido no guarda el nombre del cliente, solo su cliente_id
  PK - FK 
  SELECT t1.columna, t2.columna
FROM tabla1 t1                          -- t1 es un alias: nombre corto
JOIN tabla2 t2 ON t2.fk = t1.pk;        -- ON: cómo se relacionan las filas
  */
  select * from clientes;
  select * from vendedores;
  select * from detalle_pedido;
  select * from productos;
  select * from pedidos;
   describe pedidos;
  /*inner join devuelve solo las filas que tienen pareja en ambas tablas. 
  Es la intersección.
  ¿Qué clientes han hecho pedidos, y cuáles pedidos? */
  
  select c.nombre, c.apellido, p.id as pedido, p.fecha
  from clientes c
  inner join pedidos p on p.cliente_id=c.id
 order by p.id;
 
 /*left join todas las filas de la tabla izquierda y las que tengan relacion 
 con la derecha*/
 
 SELECT 
    c.nombre,
    COUNT(p.id) AS cantidad_pedidos
FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id
GROUP BY c.id, c.nombre
ORDER BY cantidad_pedidos DESC
LIMIT 1;

SELECT c.nombre, p.id AS pedido
FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id
ORDER BY c.id, p.id;

SELECT c.nombre, c.apellido
FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id
WHERE p.id IS NULL; 
  
SELECT 
    c.nombre,
    COUNT(p.id) AS cantidad_pedidos
FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id
GROUP BY c.id, c.nombre
ORDER BY cantidad_pedidos DESC;

/*right join todas las filas de la tabla derecha y las que tengan relacion 
 con la izquierda*/
 
SELECT p.id AS pedido, v.nombre AS vendedor
FROM pedidos p
RIGHT JOIN vendedores v ON v.id = p.vendedor_id
ORDER BY v.id, p.id;

/* multiples joins clientes → pedidos → detalle_pedido → productos
1. tabla principal clientes

*/

describe pedidos;
describe clientes;
describe detalle_pedido;
describe productos;
select c.nombre as cliente, p.id as pedido, pr.nombre as producto,
d.cantidad
from clientes c
join pedidos p on p.cliente_id=c.id
join detalle_pedido d on d.pedido_id=p.id
join productos pr on pr.id=d.producto_id
order by p.id,pr.nombre;

/* EduPlus es una plataforma colombiana de cursos en 
línea para desarrolladores. 
El equipo de producto prepara el tablero de indicadores 
del trimestre y te pide varias consultas 
sobre instructores, cursos, estudiantes e inscripciones. 
Algunos estudiantes reciben descuentos, 
así que el valor pagado puede ser menor que el precio del curso. 
La nota final queda en NULL mientras el curso no termina.
Puntos a resolver
Punto 1 — INNER JOIN (obligatorio en clase). Listar todos los cursos con su área, precio y el nombre de su instructor, ordenados por instructor y título.
Punto 2 — LEFT JOIN (obligatorio en clase). El área de mercadeo quiere escribir a los estudiantes registrados que no se han inscrito en ningún curso. Mostrar nombre, apellido y ciudad.
Punto 3 — Tres o más tablas (obligatorio en clase). Para cada inscripción: nombre completo del estudiante (en una sola columna), título del curso, nombre del instructor, fecha de inscripción y valor pagado, ordenado por fecha.
Punto 4 — Función de agregación (obligatorio en clase). Para cada curso con inscripciones: número de inscritos, ingresos (suma del valor pagado) y nota promedio redondeada a 1 decimal. Ordenar de mayor a menor ingreso. Extra: incluir también los cursos sin inscritos, mostrando 0 en ingresos.
Punto 5 — Subconsulta con IN o EXISTS (tarea). Encontrar los cursos que nadie ha comprado.
Punto 6 — Comparación con un promedio (tarea). Listar las inscripciones cuya nota final supera la nota promedio de la plataforma, con estudiante, curso y nota.
Punto 7 — JOIN + funciones + subconsulta (tarea). Mostrar, con el nombre completo en mayúsculas, a los estudiantes cuyo total pagado supera el promedio de gasto por estudiante (entre quienes se han inscrito), junto con cuántos cursos tomaron y cuánto pagaron.
Preguntas para explicar la solución (responder en comentarios)
1. En el punto 2, ¿qué pasaría si usaran INNER JOIN?
2. En el punto 4, ¿por qué “React avanzado” tiene nota promedio NULL? ¿Es un error?
3. En el punto 6, ¿AVG(nota_final) tiene en cuenta las inscripciones sin nota? ¿Cómo lo comprobarían?
4. En el punto 5, ¿por qué aquí NOT IN sí funciona pero en el ejemplo de los vendedores no?
5. ¿Qué parte de su solución cambiaría si la ejecutan en el otro motor?

*/

CREATE DATABASE IF NOT EXISTS eduplus CHARACTER SET utf8mb4;
USE eduplus;

CREATE TABLE instructores (
  id     INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  email  VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE cursos (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  titulo        VARCHAR(100)  NOT NULL,
  area          VARCHAR(50)   NOT NULL,
  precio        DECIMAL(10,2) NOT NULL,
  instructor_id INT           NOT NULL,
  CONSTRAINT fk_cursos_instructor FOREIGN KEY (instructor_id) REFERENCES instructores(id)
);

CREATE TABLE estudiantes (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  nombre   VARCHAR(50) NOT NULL,
  apellido VARCHAR(50) NOT NULL,
  ciudad   VARCHAR(50) NOT NULL
);

CREATE TABLE inscripciones (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  estudiante_id     INT           NOT NULL,
  curso_id          INT           NOT NULL,
  fecha_inscripcion DATE          NOT NULL,
  valor_pagado      DECIMAL(10,2) NOT NULL,
  nota_final        DECIMAL(3,1)  NULL,          -- NULL = curso en progreso
  CONSTRAINT fk_insc_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id),
  CONSTRAINT fk_insc_curso      FOREIGN KEY (curso_id)      REFERENCES cursos(id)
);


INSERT INTO instructores (nombre, email) VALUES
  ('Paula Herrera',   'paula@eduplus.co'),
  ('Andrés Quintero', 'andres@eduplus.co'),
  ('Camilo Vargas',   'camilo@eduplus.co');

INSERT INTO cursos (titulo, area, precio, instructor_id) VALUES
  ('SQL desde cero',       'Bases de datos', 200000.00, 1),
  ('Python para análisis', 'Programación',   350000.00, 2),
  ('Git y GitHub',         'Herramientas',   120000.00, 1),
  ('React avanzado',       'Programación',   450000.00, 2),
  ('Docker práctico',      'Herramientas',   300000.00, 1);

INSERT INTO estudiantes (nombre, apellido, ciudad) VALUES
  ('Valeria',  'Ortiz',  'Bogotá'),
  ('Samuel',   'Rojas',  'Medellín'),
  ('Isabella', 'Cruz',   'Cali'),
  ('Tomás',    'Pineda', 'Bogotá'),
  ('Juliana',  'Soto',   'Pereira'),
  ('Martín',   'López',  'Cali');

INSERT INTO inscripciones (estudiante_id, curso_id, fecha_inscripcion, valor_pagado, nota_final) VALUES
  (1, 1, '2026-06-01', 200000.00, 4.5),
  (1, 2, '2026-06-10', 350000.00, 4.0),
  (2, 1, '2026-06-05', 180000.00, 3.8),
  (2, 4, '2026-07-01', 450000.00, NULL),
  (3, 2, '2026-07-15', 315000.00, 4.8),
  (3, 3, '2026-07-20', 120000.00, 4.2),
  (4, 1, '2026-08-01', 200000.00, NULL),
  (4, 3, '2026-08-03', 120000.00, 3.5),
  (4, 4, '2026-08-10', 450000.00, NULL);


USE eduplus;

/* Punto 1 - INNER JOIN
   Cursos con su área, precio e instructor, ordenados por instructor y título */
SELECT i.nombre AS instructor,
       c.titulo,
       c.area,
       c.precio
FROM cursos c
INNER JOIN instructores i ON i.id = c.instructor_id
ORDER BY i.nombre, c.titulo;

/* Punto 2 - LEFT JOIN
   Estudiantes registrados que no se han inscrito en ningún curso */
SELECT e.nombre,
       e.apellido,
       e.ciudad
FROM estudiantes e
LEFT JOIN inscripciones ins ON ins.estudiante_id = e.id
WHERE ins.id IS NULL;

/* Punto 3 - Tres o más tablas
   Detalle de cada inscripción, ordenado por fecha */
SELECT CONCAT(e.nombre, ' ', e.apellido) AS estudiante,
       c.titulo                          AS curso,
       i.nombre                          AS instructor,
       ins.fecha_inscripcion,
       ins.valor_pagado
FROM inscripciones ins
JOIN estudiantes  e ON e.id = ins.estudiante_id
JOIN cursos       c ON c.id = ins.curso_id
JOIN instructores i ON i.id = c.instructor_id
ORDER BY ins.fecha_inscripcion;


-- Subconsultas
-- Select dentro de otra consulta (otro select)
-- La consulta interna responde una pregunta y la pregunta le sirve a la consulta externa
/*
 	-- Producto que tiene un precio mayor al precio promedio
	select nombre, precio
	from productos
	where precio > (select avg(precio) as promedio from productos)
	order by precio desc;
	
	-- Producto más caro
	select nombre, precio
	from productos
	where precio = (select max(precio) from productos)
	order by precio desc;
	
	-- Subquery returns more than 1 row
	* Se usa IN devuelve una lista de valores
	
	-- Clientes que tienen al menos 1 pedido
	
	select nombre, apellido
	from clientes
	where if in (select cliente_id from pedidos);
	
	-- Productos que nunca se han vendido
	
	select nombre
	from producto
	where id not in (select producto_id from detalle_pedido);
	
	
	select nombre
	from vendedores
	where id not in (select vendedor_id from pedidos)
	
	* Exist
	* no exist
	
	-- Vendedor que no tiene pedidos
	
	select v.nombre
	from vendedores v
	where not exist
	(select 1
	from pedidios p 
	where p.vendedor_id=v.id);
*/

 	-- curso que tiene un precio mayor al promedio
select titulo, precio
from cursos
where precio > (select avg(precio) as promedio from cursos)
order by precio desc;

-- Curso que nadie ha tomado
-- con not in
select titulo
from cursos
where id not in (select curso_id from inscripciones);

-- Con not exists

select c.titulo 
from cursos c 
where not exists (
    select 1 
    from inscripciones i 
    where i.curso_id = c.id
);

/*
-- Usando from - Es más rapido una subconsulta que una consulta multitabla (tiempos de ejecución)
-- Consulta de tabla derivada
-- La tabla temporal debe llevar un alias o no se genera

-- ej. Cuanto vale en promedio un pedido y cual es el mayor

select round(avg(t.total_pedido), 2) as promedio_por_pedido,
max(t.total_pedido) as pedido_mayor
from (select pedido_id, SUM(cantidad*precio_unitario) as total_pedido
from detalle_pedidio
group by pedido_id) as t;

select * from pedidos;
select * from detalle_pedido; 

select c.nombre ,(select count(*)
	from pedidos p 
	where p.cliente_id=c.id) as cantidad_pedidos
from clientes c
order by c.id;

 */

-- Hacer el 4 y el 7 de eduplus

USE eduplus;

/* Punto 4 - Función de agregación
   Para cada curso: inscritos, ingresos y nota promedio (1 decimal)
   LEFT JOIN para incluir también los cursos sin inscritos (ingresos en 0) */
SELECT c.titulo,
       COUNT(ins.id)                 AS inscritos,
       COALESCE(SUM(ins.valor_pagado), 0) AS ingresos,
       ROUND(AVG(ins.nota_final), 1) AS nota_promedio
FROM cursos c
LEFT JOIN inscripciones ins ON ins.curso_id = c.id
GROUP BY c.id, c.titulo
ORDER BY ingresos DESC;

/* Punto 7 - JOIN + funciones + subconsulta
   Estudiantes cuyo gasto total supera el promedio de gasto por estudiante
   (promedio calculado solo entre quienes se han inscrito) */
SELECT UPPER(CONCAT(e.nombre, ' ', e.apellido)) AS estudiante,
       COUNT(ins.id)        AS cursos_tomados,
       SUM(ins.valor_pagado) AS total_pagado
FROM estudiantes e
JOIN inscripciones ins ON ins.estudiante_id = e.id
GROUP BY e.id, e.nombre, e.apellido
HAVING SUM(ins.valor_pagado) > (
    SELECT AVG(total_est.total)
    FROM (
        SELECT SUM(valor_pagado) AS total
        FROM inscripciones
        GROUP BY estudiante_id
    ) AS total_est
);

--- ============================================================

USE eduplus;

/* ===================== VISTA ===================== */

-- Crear v_ingresos_por_curso con inscritos, ingresos y nota promedio por curso, incluyendo los cursos sin inscritos
CREATE OR REPLACE VIEW v_ingresos_por_curso AS
SELECT c.id AS curso_id,
       c.titulo,
       COUNT(ins.id)                       AS inscritos,
       COALESCE(SUM(ins.valor_pagado), 0)  AS ingresos,
       ROUND(AVG(ins.nota_final), 1)       AS nota_promedio
FROM cursos c
LEFT JOIN inscripciones ins ON ins.curso_id = c.id
GROUP BY c.id, c.titulo;


SELECT * FROM v_ingresos_por_curso ORDER BY ingresos DESC;

/* ============== PROCEDIMIENTO ALMACENADO ============== */
-- Crear sp_inscribir_estudiante que registre una inscripción nueva, valide que el estudiante y el curso existan, y devuelva el id de la inscripción creada.

DELIMITER //
CREATE PROCEDURE sp_inscribir_estudiante(
    IN  p_estudiante_id   INT,
    IN  p_curso_id        INT,
    IN  p_valor_pagado    DECIMAL(10,2),
    OUT p_inscripcion_id  INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM estudiantes WHERE id = p_estudiante_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estudiante no existe';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM cursos WHERE id = p_curso_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El curso no existe';
    END IF;

    INSERT INTO inscripciones (estudiante_id, curso_id, fecha_inscripcion, valor_pagado, nota_final)
    VALUES (p_estudiante_id, p_curso_id, CURDATE(), p_valor_pagado, NULL);

    SET p_inscripcion_id = LAST_INSERT_ID();
END //
DELIMITER ;


CALL sp_inscribir_estudiante(5, 1, 200000, @id);
SELECT @id AS nueva_inscripcion;











