-- =============== Ejercicio Clase TRIGGERS

CREATE DATABASE IF NOT EXISTS biblioteca_db;
USE biblioteca_db;

CREATE TABLE socios (
  id     INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  email  VARCHAR(100) NOT NULL UNIQUE,
  activo BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE libros (
  id                     INT AUTO_INCREMENT PRIMARY KEY,
  titulo                 VARCHAR(150) NOT NULL,
  autor                  VARCHAR(100) NOT NULL,
  ejemplares_totales     INT NOT NULL CHECK (ejemplares_totales >= 0),
  ejemplares_disponibles INT NOT NULL CHECK (ejemplares_disponibles >= 0)
);

CREATE TABLE prestamos (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  socio_id         INT  NOT NULL,
  libro_id         INT  NOT NULL,
  fecha_prestamo   DATE NOT NULL,
  fecha_limite     DATE NOT NULL,
  fecha_devolucion DATE NULL,
  CONSTRAINT fk_prestamos_socio FOREIGN KEY (socio_id) REFERENCES socios(id),
  CONSTRAINT fk_prestamos_libro FOREIGN KEY (libro_id) REFERENCES libros(id)
);

CREATE TABLE historial_prestamos (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  prestamo_id INT          NOT NULL,
  accion      VARCHAR(20)  NOT NULL,
  detalle     VARCHAR(255),
  usuario     VARCHAR(100) NOT NULL,
  fecha       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_historial_prestamo FOREIGN KEY (prestamo_id) REFERENCES prestamos(id)
);


-- Punto 1: Vista
create or replace view v_prestamos_vencidos as
select p.id as prestamo_id, s.nombre as socio, s.email, l.titulo, p.fecha_limite,
datediff(current_date, p.fecha_limite) as dias_retraso
from prestamos p
join socios s on s.id =p.socio_id
join libros l on l.id =p.libro_id
where p.fecha_devolucion is null and p.fecha_limite<current_date;

select * from v_prestamos_vencidos;

-- Punto 2: Procedimientos almacenados
drop procedure if exists sp_prestar_libro;

create procedure sp_prestar_libro(
	in p_socio_id int,
	in p_libro_id int,
	in p_dias int,
	out p_prestamo_id int)
begin
	
	


-- Datos de prueba (funcionan igual en ambos motores)
-- Las fechas son relativas al día en que se ejecuta el script, para que siempre haya préstamos vencidos.

INSERT INTO socios (nombre, email, activo) VALUES
  ('Camila Rojas',   'camila@correo.com',    TRUE),
  ('Andrés Díaz',    'andres@correo.com',    TRUE),
  ('Valentina Ríos', 'valentina@correo.com', FALSE),   -- inactiva
  ('Mateo Castro',   'mateo@correo.com',     TRUE);    -- ya tiene 3 préstamos activos

INSERT INTO libros (titulo, autor, ejemplares_totales, ejemplares_disponibles) VALUES
  ('Cien años de soledad',          'Gabriel García Márquez',   3, 2),
  ('Clean Code',                    'Robert C. Martin',         2, 0),   -- agotado
  ('Fundamentos de bases de datos', 'Abraham Silberschatz',     4, 3),
  ('El principito',                 'Antoine de Saint-Exupéry', 2, 2);

INSERT INTO prestamos (socio_id, libro_id, fecha_prestamo, fecha_limite, fecha_devolucion) VALUES
  (1, 1, CURRENT_DATE - INTERVAL '40' DAY, CURRENT_DATE - INTERVAL '26' DAY, CURRENT_DATE - INTERVAL '27' DAY), -- devuelto
  (2, 2, CURRENT_DATE - INTERVAL '20' DAY, CURRENT_DATE - INTERVAL '6' DAY,  NULL),  -- vencido hace 6 días
  (4, 2, CURRENT_DATE - INTERVAL '18' DAY, CURRENT_DATE - INTERVAL '4' DAY,  NULL),  -- vencido hace 4 días
  (4, 1, CURRENT_DATE - INTERVAL '5' DAY,  CURRENT_DATE + INTERVAL '9' DAY,  NULL),  -- al día
  (4, 3, CURRENT_DATE - INTERVAL '2' DAY,  CURRENT_DATE + INTERVAL '12' DAY, NULL);  -- al día
  
  USE biblioteca_db;

/* ===================== R1 - VISTA ===================== */

CREATE OR REPLACE VIEW v_prestamos_vencidos AS
SELECT p.id                              AS prestamo_id,
       s.nombre                          AS socio,
       s.email,
       l.titulo,
       p.fecha_limite,
       DATEDIFF(CURRENT_DATE, p.fecha_limite) AS dias_retraso
FROM prestamos p
JOIN socios s ON s.id = p.socio_id
JOIN libros l ON l.id = p.libro_id
WHERE p.fecha_devolucion IS NULL
  AND p.fecha_limite < CURRENT_DATE;

-- Prueba
SELECT * FROM v_prestamos_vencidos;

/* ============== R2 - PROCEDIMIENTO ALMACENADO ============== */

DROP PROCEDURE IF EXISTS sp_prestar_libro;

DELIMITER //
CREATE PROCEDURE sp_prestar_libro(
    IN  p_socio_id     INT,
    IN  p_libro_id     INT,
    IN  p_dias         INT,
    OUT p_prestamo_id  INT
)
BEGIN
    DECLARE v_activo           BOOLEAN;
    DECLARE v_prestamos_activos INT;
    DECLARE v_disponibles      INT;

    -- Regla 1: el socio debe existir y estar activo
    SELECT activo INTO v_activo
    FROM socios
    WHERE id = p_socio_id;

    IF v_activo IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio no existe';
    ELSEIF v_activo = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio está inactivo';
    END IF;

    -- Regla 2: máximo 3 préstamos activos
    SELECT COUNT(*) INTO v_prestamos_activos
    FROM prestamos
    WHERE socio_id = p_socio_id AND fecha_devolucion IS NULL;

    IF v_prestamos_activos >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio ya tiene 3 préstamos activos';
    END IF;

    -- Regla 3: el libro debe tener ejemplares disponibles
    SELECT ejemplares_disponibles INTO v_disponibles
    FROM libros
    WHERE id = p_libro_id;

    IF v_disponibles IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El libro no existe';
    ELSEIF v_disponibles <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay ejemplares disponibles de este libro';
    END IF;

    -- Regla 4: el préstamo debe durar entre 1 y 30 días
    IF p_dias < 1 OR p_dias > 30 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La duración del préstamo debe estar entre 1 y 30 días';
    END IF;

    -- Crear el préstamo
    INSERT INTO prestamos (socio_id, libro_id, fecha_prestamo, fecha_limite, fecha_devolucion)
    VALUES (p_socio_id, p_libro_id, CURRENT_DATE, CURRENT_DATE + INTERVAL p_dias DAY, NULL);

    SET p_prestamo_id = LAST_INSERT_ID();

    -- Regla 5: descontar un ejemplar disponible
    UPDATE libros
    SET ejemplares_disponibles = ejemplares_disponibles - 1
    WHERE id = p_libro_id;

    -- Regla 6: registrar en el historial
    INSERT INTO historial_prestamos (prestamo_id, accion, detalle, usuario)
    VALUES (p_prestamo_id, 'PRESTAMO', CONCAT('Préstamo de ', p_dias, ' días'), CURRENT_USER());
END //
DELIMITER ;

-- Pruebas
CALL sp_prestar_libro(1, 3, 15, @id);
SELECT @id AS prestamo_creado;

-- Debe fallar: socio inactivo (id 3)
CALL sp_prestar_libro(3, 3, 10, @id);

-- Debe fallar: libro agotado (id 2, Clean Code)
CALL sp_prestar_libro(1, 2, 10, @id);

-- Debe fallar: socio con 3 préstamos activos (id 4, Mateo)
CALL sp_prestar_libro(4, 3, 10, @id);

-- Debe fallar: días fuera de rango
CALL sp_prestar_libro(1, 1, 45, @id);

SELECT * FROM prestamos;
SELECT * FROM historial_prestamos;
SELECT * FROM libros;
