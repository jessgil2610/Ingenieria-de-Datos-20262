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


-- Punto 1: Vista
create or replace view v_prestamos_vencidos as
select p.id as prestamo_id, s.nombre as socio, s.email, l.titulo, p.fecha_limite,
datediff(current_date, p.fecha_limite) as dias_retraso
from prestamos p
join socios s on s.id =p.socio_id
join libros l on l.id =p.libro_id
where p.fecha_devolucion is null and p.fecha_limite<current_date;

-- Prueba
select * from v_prestamos_vencidos;

-- Punto 2: Procedimientos almacenados
drop procedure if exists sp_prestar_libro;


create procedure sp_prestar_libro(
	in p_socio_id int,
	in p_libro_id int,
	in p_dias int,
	out p_prestamo_id int)
BEGIN
	DECLARE v_activo boolean;
	DECLARE v_prestamos_activos int;
	DECLARE v_disponibles int;

-- El socio debe existir y estar activo
	SELECT activo INTO v_activo FROM socios
	WHERE id =p_socio_id;

	IF v_activo IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio no existe';
    ELSEIF v_activo = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio está inactivo';
    END IF; 
	
-- Maximo 3 prestamos activos
	SELECT COUNT(*) INTO v_prestamos_activos
    FROM prestamos
    WHERE socio_id = p_socio_id AND fecha_devolucion IS NULL;

    IF v_prestamos_activos >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio ya tiene 3 préstamos activos';
    END IF;
    
-- el libro debe tener ejemplares disponibles
    SELECT ejemplares_disponibles INTO v_disponibles
    FROM libros
    WHERE id = p_libro_id;

    IF v_disponibles IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El libro no existe';
    ELSEIF v_disponibles <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay ejemplares disponibles de este libro';
    END IF;
    
-- el préstamo debe durar entre 1 y 30 días
    IF p_dias < 1 OR p_dias > 30 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La duración del préstamo debe estar entre 1 y 30 días';
    END IF;

-- Crear el préstamo
    INSERT INTO prestamos (socio_id, libro_id, fecha_prestamo, fecha_limite, fecha_devolucion)
    VALUES (p_socio_id, p_libro_id, CURRENT_DATE, CURRENT_DATE + INTERVAL p_dias DAY, NULL);

    SET p_prestamo_id = LAST_INSERT_ID();
    
-- descontar un ejemplar disponible
    UPDATE libros
    SET ejemplares_disponibles = ejemplares_disponibles - 1
    WHERE id = p_libro_id;

-- registrar en el historial
    INSERT INTO historial_prestamos (prestamo_id, accion, detalle, usuario)
    VALUES (p_prestamo_id, 'PRESTAMO', CONCAT('Préstamo de ', p_dias, ' días'), CURRENT_USER());
end;
    

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

-- Punto 3: Trigger
drop trigger if exists trg_prestamos_devolucion;

create trigger trg_prestamos_devolucion
after update on prestamos
for each row
begin
	declare v_dias_retraso int;
	if old.fecha_devolucion is null and new.fecha_devolucion is not null then
		set v_dias_retraso= greatest(datediff(new.fecha_devolucion, new.fecha_limite),0);
		-- sumar un ejemplar disponible
		update libros
		set ejemplares_disponibles = ejemplares_disponibles + 1
		where id= new.libro_id;
		-- registrar la devolución en el historial
		insert into historial_prestamos(prestamo_id, accion, detalle, usuario)
		values(new.id, "DEVOLUCION", concat("Días de retraso: ", v_dias_retraso), current_user());
	end if;
end;

-- Reto opcional: Validar fecha de devolución
drop trigger if exists trg_prestamos_validar_devolucion

create trigger trg_prestamos_validar_devolucion
before update on prestamos
for each row
begin
	if new.fecha_devolucion is not null and new.fecha_devolucion < new.fecha_prestamo then
		signal sqlstate '45000'
		set message_text = 'La fecha de devolución no puede ser anterior a la fecha de prestamo';
	end if;
end;

-- Pruebas

-- Estado del prestamo 2
select * from prestamos where  id=2;
select ejemplares_disponibles from libros where id=2

-- Registrar devolución del prestamo 2
UPDATE prestamos SET fecha_devolucion = CURRENT_DATE WHERE id = 2;

-- debe subir a uno disponible
select ejemplares_disponibles from libros where id=2

-- verificación de historial de prestamos
select * from historial_prestamos where prestamo_id = 2;

-- La vista no debe mostrar el prestamo como vencido
select * from v_prestamos_vencidos;

-- No se hace nada si se actualiza otra columna o si el préstamo ya estaba devuelto.
update prestamos set fecha_devolucion = current_date where id = 2;
select ejemplares_disponibles from libros where id = 2;  
select COUNT(*) from historial_prestamos where prestamo_id = 2; 

update prestamos
set fecha_devolucion = fecha_prestamo - interval 1 day
where id = 4;

/* Preguntas:
1.	¿Por qué el reporte de vencidos es una vista y no una tabla que se llena cada noche? ¿En qué caso preferirías una vista materializada (PostgreSQL)?
Porque los datos cambian constantemente y con una vista normal siempre se calcula al momento de cosultarla. preferiria una vista materializada en Postgres si la consulta fuera muy pesada 
muchos joins o agregaciones y se consultara con mucha frecuencia.

2.	¿Por qué el préstamo es un procedimiento y no un trigger BEFORE INSERT sobre prestamos? Menciona al menos una ventaja y una desventaja de cada opción.
El prestamo es un procedimiento porque antes de insertar hay que validar reglas de negocio que dependen de otras tablas y si alguna falla el proceso se debe
detener sin insertar nada.

Procedimiento:
ventaja: valida y decide si se ejcuta o no antes de tocar la tabla
desventaja: solo protege si todos acceden a traves de él

Trigger:
ventaja: se ejecuta siempre sin importar como se inserta la fila
desventaja: es más incomodo devolver información al usuario y las validaciones complejas con varias consultas se vuelven menos legibles dentro de un trigger

3.	¿Por qué la devolución se automatizó con un trigger y no dentro de un procedimiento sp_devolver_libro? ¿Qué riesgo aparecería si alguien hace el UPDATE directo sin trigger?
porque es un aconsecuencia automática de un solo cambio de estado y no requiere de parametros de entrada adicionales ni decisiones de negocio complejas
el risego de no tener el trigger es que alguien actualice fecha_devolucion directamente y el inventario de ejemplares disponibles y el historial queden dedincronizados del
estado real de los prestamos

4.	¿Qué pasaría en tu procedimiento si dos funcionarios prestan al mismo tiempo el último ejemplar de un libro? ¿Qué línea lo evita?
se podria dar una condicion de carrera y la linea que evita que pase esto es el propio update porque se bloque la fila durante la transacción, la segunda llamada tienen que esperar
que la primera termine y para entonces el valor ya cambio

5.	Nombra dos cambios que tuviste que hacer (o tendrías que hacer) para llevar tu código al otro motor.
Cambiar datediff(fecha1,fecha2) por la resta directa (fecha1-fecha2) y date add por current date + p_dias
separar el trigger en dos objetos, una funcion con la lógica y luego create trigger ... execute function

 */



