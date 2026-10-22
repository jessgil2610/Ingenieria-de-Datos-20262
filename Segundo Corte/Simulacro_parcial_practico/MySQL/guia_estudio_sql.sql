-- =====================================================================
-- guia de estudio sql (mysql) - base de datos dronandes
-- ordenada por temas
--
-- indice
--   1. base de datos (create, use, drop)
--   2. ddl: crear tablas y restricciones
--   3. ddl: alter table, rename, truncate, drop
--   4. datos iniciales
--   5. dml: insert, update, delete
--   6. consultas basicas (select, where, order by, limit, union)
--   7. funciones de texto, numeros, fechas y condicionales
--   8. agregacion: group by y having
--   9. consultas multitabla (joins)
--  10. subconsultas
--  11. vistas
--  12. indices
--  13. funciones almacenadas
--  14. procedimientos almacenados
--  15. triggers
--  16. transacciones
--  17. diferencias mysql / postgresql
-- =====================================================================


-- =====================================================================
-- 1. base de datos
-- =====================================================================
drop database if exists dronandes;
create database dronandes;
-- ver las bases que existen en el servidor
show databases;

-- elegir la base con la que se va a trabajar: todo lo que sigue se crea
-- y se consulta dentro de dronandes
use dronandes;


-- =====================================================================
-- 2. ddl: crear tablas y restricciones
-- =====================================================================
-- sintaxis general:
--   create table nombre (
--       columna tipo [restricciones],
--       ...
--       [restricciones de tabla]
--   );
--
-- tipos de datos mas usados
--   int                 numero entero
--   smallint            entero pequeno
--   decimal(p,s)        numero exacto: p digitos en total, s decimales
--   varchar(n)          texto de hasta n caracteres
--   char(n)             texto de longitud fija
--   date                fecha (2026-10-22)
--   datetime            fecha y hora (2026-10-22 08:30:00)
--   boolean             verdadero/falso (en mysql es tinyint(1))
--
-- restricciones (constraints)
--   primary key         identifica cada fila: unica y no nula
--   auto_increment      mysql genera el numero solo
--   not null            la columna no acepta null
--   unique              no se repite el valor (acepta varios null)
--   default             valor que se guarda si no se escribe
--   check               regla que cada fila debe cumplir
--   foreign key         el valor debe existir en otra tabla
--
-- se escribe con nombre (constraint chk_..., fk_...) para poder
-- borrarla o identificarla despues en un mensaje de error.
-- las tablas que no dependen de otras se crean primero; una tabla con
-- foreign key se crea despues de la tabla a la que apunta.
--
-- a continuacion estan las 9 tablas del caso. mirar en cada una que
-- restriccion se usa y como se escribe.

-- orden de creacion: primero las tablas que NO dependen de otras
-- (bases, tipos_carga) y despues las que tienen foreign key hacia ellas.
-- si se crea una tabla con fk antes que la tabla referenciada, da error.

-- ---------------------------------------------------------------------
-- tabla 1: bases (no depende de nadie)
-- ---------------------------------------------------------------------
create table bases (
    -- auto_increment: mysql genera el numero solo (1, 2, 3...)
    id_base int auto_increment primary key,
    -- unique: no pueden existir dos bases con el mismo nombre
    nombre varchar(60) not null unique,
    municipio varchar(60) not null,
    departamento varchar(40) not null,
    capacidad_drones int not null,
    fecha_apertura date not null,
    -- check: regla que cada fila debe cumplir. el nombre empieza por chk_
    constraint chk_bases_capacidad check (capacidad_drones > 0)
);

-- ---------------------------------------------------------------------
-- tabla 2: tipos_carga (no depende de nadie)
-- ---------------------------------------------------------------------
create table tipos_carga (
    id_tipo int auto_increment primary key,
    nombre varchar(40) not null unique,
    -- decimal(10,2): 10 digitos en total, 2 de ellos decimales
    tarifa_kg decimal(10,2) not null,
    -- boolean en mysql es un tinyint(1): false = 0, true = 1
    requiere_frio boolean not null default false,
    constraint chk_tipos_carga_tarifa check (tarifa_kg > 0)
);

-- ---------------------------------------------------------------------
-- tabla 3: drones (depende de bases)
-- ---------------------------------------------------------------------
create table drones (
    id_dron int auto_increment primary key,
    codigo_serie varchar(12) not null unique,
    modelo varchar(40) not null,
    -- la restriccion de carga_max_kg (entre 0,5 y 25) NO va aqui:
    -- se agrega despues con alter table (seccion 3)
    carga_max_kg decimal(5,2) not null,
    autonomia_km decimal(5,1) not null,
    -- default: valor que se guarda si el insert no trae este campo
    estado varchar(15) not null default 'ACTIVO',
    horas_vuelo decimal(7,1) not null default 0,
    fecha_adquisicion date not null,
    id_base int not null,
    constraint chk_drones_autonomia check (autonomia_km > 0),
    -- in (...): el valor tiene que ser uno de la lista
    constraint chk_drones_estado check (estado in ('ACTIVO', 'MANTENIMIENTO', 'RETIRADO')),
    constraint chk_drones_horas check (horas_vuelo >= 0),
    -- foreign key: id_base solo puede tener valores que existan en bases
    constraint fk_drones_bases foreign key (id_base) references bases (id_base)
);

-- ---------------------------------------------------------------------
-- tabla 4: pilotos (depende de bases y de si misma)
-- ---------------------------------------------------------------------
create table pilotos (
    id_piloto int auto_increment primary key,
    documento varchar(15) not null unique,
    nombres varchar(50) not null,
    apellidos varchar(50) not null,
    email varchar(80) not null unique,
    licencia char(1) not null,
    fecha_ingreso date not null,
    -- id_supervisor acepta null: los jefes de operacion no tienen supervisor.
    -- su foreign key (hacia pilotos) NO se declara aqui, se agrega despues con alter table
    id_supervisor int null,
    id_base int not null,
    constraint chk_pilotos_licencia check (licencia in ('A', 'B', 'C')),
    constraint fk_pilotos_bases foreign key (id_base) references bases (id_base)
);

-- ---------------------------------------------------------------------
-- tabla 5: clientes (no depende de nadie)
-- ---------------------------------------------------------------------
create table clientes (
    id_cliente int auto_increment primary key,
    tipo varchar(12) not null,
    -- varchar(80) por ahora: se puede ampliar despues con alter table
    nombre varchar(80) not null,
    nit_documento varchar(15) not null unique,
    -- unique permite varios null: dos clientes sin correo no chocan
    email varchar(80) null unique,
    telefono varchar(15) null,
    municipio varchar(60) not null,
    -- en mysql un default que es una funcion va entre parentesis
    fecha_registro date not null default (current_date),
    constraint chk_clientes_tipo check (tipo in ('HOSPITAL', 'FARMACIA', 'COMERCIO', 'ONG', 'PERSONA'))
);

-- ---------------------------------------------------------------------
-- tabla 6: entregas (depende de clientes, drones y pilotos)
-- ---------------------------------------------------------------------
create table entregas (
    id_entrega int auto_increment primary key,
    codigo varchar(10) not null unique,
    id_cliente int not null,
    id_dron int not null,
    id_piloto int not null,
    fecha_programada datetime not null,
    -- null mientras la entrega no se haya cumplido
    fecha_entrega datetime null,
    municipio_destino varchar(60) not null,
    distancia_km decimal(5,1) not null,
    prioridad varchar(8) not null default 'NORMAL',
    estado varchar(12) not null default 'PROGRAMADA',
    calificacion smallint null,
    constraint chk_entregas_distancia check (distancia_km > 0),
    constraint chk_entregas_prioridad check (prioridad in ('NORMAL', 'URGENTE', 'VITAL')),
    constraint chk_entregas_estado check (estado in ('PROGRAMADA', 'EN_VUELO', 'ENTREGADA', 'CANCELADA', 'FALLIDA')),
    -- la fecha real de entrega solo puede existir si el estado es ENTREGADA
    constraint chk_entregas_fecha_entrega check (fecha_entrega is null or estado = 'ENTREGADA'),
    -- la calificacion es opcional (null) pero si viene debe estar entre 1 y 5
    constraint chk_entregas_calificacion check (calificacion between 1 and 5),
    constraint fk_entregas_clientes foreign key (id_cliente) references clientes (id_cliente),
    constraint fk_entregas_drones foreign key (id_dron) references drones (id_dron),
    constraint fk_entregas_pilotos foreign key (id_piloto) references pilotos (id_piloto)
);

-- ---------------------------------------------------------------------
-- tabla 7: carga_entrega (tabla intermedia de la relacion n:m)
-- una entrega lleva varios tipos de carga y un tipo de carga aparece en
-- muchas entregas. se resuelve con esta tabla, cuya clave primaria es
-- COMPUESTA: (id_entrega, id_tipo). se escoge asi porque un mismo tipo
-- de carga no se repite dentro de una entrega (rn-08), entonces la pareja
-- identifica cada fila sin necesidad de un id adicional.
-- ---------------------------------------------------------------------
create table carga_entrega (
    id_entrega int not null,
    id_tipo int not null,
    peso_kg decimal(6,2) not null,
    unidades int not null default 1,
    -- clave primaria compuesta: se declara al final, con las dos columnas
    primary key (id_entrega, id_tipo),
    constraint chk_carga_entrega_peso check (peso_kg > 0),
    constraint chk_carga_entrega_unidades check (unidades > 0),
    constraint fk_carga_entrega_entregas foreign key (id_entrega) references entregas (id_entrega),
    constraint fk_carga_entrega_tipos foreign key (id_tipo) references tipos_carga (id_tipo)
);

-- ---------------------------------------------------------------------
-- tabla 8: mantenimientos (depende de drones)
-- ---------------------------------------------------------------------
create table mantenimientos (
    id_mantenimiento int auto_increment primary key,
    id_dron int not null,
    fecha date not null,
    tipo varchar(12) not null,
    -- opcional: puede quedar en null
    descripcion varchar(200) null,
    costo decimal(10,2) not null,
    constraint chk_mantenimientos_tipo check (tipo in ('PREVENTIVO', 'CORRECTIVO')),
    constraint chk_mantenimientos_costo check (costo >= 0),
    constraint fk_mantenimientos_drones foreign key (id_dron) references drones (id_dron)
);

-- ---------------------------------------------------------------------
-- tabla 9: historial_entregas (depende de entregas)
-- ---------------------------------------------------------------------
create table historial_entregas (
    id_historial int auto_increment primary key,
    id_entrega int not null,
    estado_anterior varchar(12) not null,
    estado_nuevo varchar(12) not null,
    -- current_timestamp: fecha y hora en que se inserta la fila
    fecha_cambio datetime not null default current_timestamp,
    constraint fk_historial_entregas_entregas foreign key (id_entrega) references entregas (id_entrega)
);


-- ver las tablas creadas y la estructura de una tabla
show tables;
describe entregas;
-- muestra el create table completo, con todas las restricciones y fk
show create table entregas;


-- =====================================================================
-- 3. ddl: alter table, rename, truncate, drop
-- =====================================================================
-- se practica con tablas de ejemplo (practica y practica_detalle) para
-- no tocar las tablas del caso.

create table practica (
    id_practica int auto_increment primary key,
    nombre varchar(30) not null,
    valor int
);

-- 3.1 agregar una columna (queda al final de la tabla)
alter table practica add column categoria varchar(20);

-- 3.2 agregar una columna en una posicion: after = despues de otra columna
alter table practica add column codigo varchar(10) not null default 'S/C' after nombre;

-- 3.3 cambiar el tipo o la definicion de una columna (modify)
-- modify REEMPLAZA toda la definicion: hay que repetir not null, default, etc.
alter table practica modify column nombre varchar(60) not null;

-- 3.4 cambiar el nombre Y la definicion de una columna (change)
-- change necesita el nombre viejo, el nombre nuevo y la definicion completa
alter table practica change column valor valor_total decimal(10,2);

-- 3.5 solo renombrar una columna
alter table practica rename column categoria to tipo;

-- 3.6 poner y quitar el valor por defecto de una columna
alter table practica alter column tipo set default 'GENERAL';
alter table practica alter column tipo drop default;

-- 3.7 agregar restricciones a una tabla que ya existe
alter table practica add constraint chk_practica_valor check (valor_total >= 0);
alter table practica add constraint uq_practica_codigo unique (codigo);

-- 3.8 borrar restricciones
-- check: drop constraint (en mysql 8.0.16 a 8.0.18 se escribe drop check)
alter table practica drop constraint chk_practica_valor;
-- unique: se borra el indice que la sostiene
alter table practica drop index uq_practica_codigo;

-- 3.9 borrar una columna
alter table practica drop column tipo;

describe practica;

-- 3.10 foreign key con acciones: on delete cascade
-- on delete cascade: al borrar la fila padre, se borran sus hijas.
-- otras opciones: on delete restrict (por defecto, no deja borrar),
-- on delete set null (pone null en la fk de las hijas),
-- on update cascade (si cambia la pk del padre, cambia la fk de las hijas).
create table practica_detalle (
    id_detalle int auto_increment primary key,
    id_practica int not null,
    descripcion varchar(50) not null
);

-- la fk tambien se puede agregar despues con alter table
alter table practica_detalle
add constraint fk_practica_detalle_practica
foreign key (id_practica) references practica (id_practica)
on delete cascade;

insert into practica (nombre, codigo, valor_total) values ('Item A', 'A-1', 100), ('Item B', 'B-1', 200);
insert into practica_detalle (id_practica, descripcion) values (1, 'detalle 1 de A'), (1, 'detalle 2 de A'), (2, 'detalle 1 de B');

-- se borra el padre 1: sus dos detalles se borran solos
delete from practica where id_practica = 1;
select * from practica_detalle;

-- borrar la fk
alter table practica_detalle drop foreign key fk_practica_detalle_practica;

-- 3.11 renombrar una tabla (dos formas equivalentes)
rename table practica to practica_nueva;
alter table practica_nueva rename to practica;

-- 3.12 truncate: vacia la tabla completa (mas rapido que delete sin where),
-- reinicia el auto_increment y no se puede deshacer con rollback
truncate table practica_detalle;

-- 3.13 drop table: borra la tabla y sus datos. if exists evita el error
-- si la tabla no existe. primero se borra la tabla hija y luego la padre.
drop table if exists practica_detalle;
drop table if exists practica;


-- =====================================================================
-- 4. datos iniciales
-- =====================================================================
-- insert con varias filas: insert into tabla (columnas) values (...), (...);
-- los datos se insertan en el mismo orden de las dependencias: primero las
-- tablas padre (bases, tipos_carga, clientes), luego drones y pilotos, y al
-- final las que tienen fk hacia varias tablas (entregas, carga_entrega).
-- ======================================================================
-- DATOS INICIALES - Proyecto Condor (DronAndes Express S.A.S.)
-- Corte: 30 de septiembre de 2026, 18:00
-- ======================================================================

insert into bases (id_base, nombre, municipio, departamento, capacidad_drones, fecha_apertura) values
(1, 'Base Cóndor',    'Rionegro', 'Antioquia', 6, '2024-02-15'),
(2, 'Base Colibrí',   'Guatapé',  'Antioquia', 4, '2024-08-01'),
(3, 'Base Frailejón', 'Tunja',    'Boyacá',    5, '2025-01-20'),
(4, 'Base Guadua',    'Salento',  'Quindío',   3, '2026-07-01');

insert into tipos_carga (id_tipo, nombre, tarifa_kg, requiere_frio) values
(1, 'Vacunas',                12000, true),
(2, 'Muestras de laboratorio', 10000, true),
(3, 'Medicamentos',            8000, false),
(4, 'Documentos',              5000, false),
(5, 'Repuestos',               4500, false),
(6, 'Alimentos',               3500, false);

insert into drones (id_dron, codigo_serie, modelo, carga_max_kg, autonomia_km, estado, horas_vuelo, fecha_adquisicion, id_base) values
(1, 'DA-CX4-01', 'Cóndor X4',    8.00, 45.0, 'ACTIVO',        312.5, '2024-02-20', 1),
(2, 'DA-CX4-02', 'Cóndor X4',    8.00, 45.0, 'ACTIVO',        468.0, '2024-03-10', 1),
(3, 'DA-CX6-01', 'Cóndor X6',   15.00, 60.0, 'ACTIVO',        205.0, '2025-01-15', 1),
(4, 'DA-COL-01', 'Colibrí Mini', 2.50, 25.0, 'ACTIVO',        520.5, '2024-08-05', 2),
(5, 'DA-COL-02', 'Colibrí Mini', 2.50, 25.0, 'MANTENIMIENTO', 610.0, '2024-08-05', 2),
(6, 'DA-ALB-01', 'Albatros H8', 25.00, 90.0, 'ACTIVO',         98.0, '2025-02-01', 3),
(7, 'DA-CX6-02', 'Cóndor X6',   15.00, 60.0, 'ACTIVO',        150.5, '2025-03-12', 3),
(8, 'DA-ALB-02', 'Albatros H8', 25.00, 90.0, 'RETIRADO',      890.0, '2024-05-01', 3);

-- Los supervisores (id_supervisor NULL) se insertan primero.
insert into pilotos (id_piloto, documento, nombres, apellidos, email, licencia, fecha_ingreso, id_supervisor, id_base) values
(1, '1036600111', 'Laura',   'Restrepo Gil', 'laura.restrepo@dronandes.co',  'C', '2024-02-01', NULL, 1),
(2, '1049600222', 'Camilo',  'Duarte Rojas', 'camilo.duarte@dronandes.co',   'C', '2025-01-10', NULL, 3),
(3, '1036600333', 'Mateo',   'Zapata Vélez', 'mateo.zapata@dronandes.co',    'B', '2024-04-15', 1,    1),
(4, '1036600444', 'Sara',    'Montoya Ruiz', 'sara.montoya@dronandes.co',    'B', '2024-08-10', 1,    2),
(5, '1036600555', 'Julián',  'Patiño Cruz',  'julian.patino@dronandes.co',   'A', '2025-06-01', 1,    2),
(6, '1049600666', 'Daniela', 'Suárez León',  'daniela.suarez@dronandes.co',  'B', '2025-02-01', 2,    3),
(7, '1049600777', 'Tomás',   'Becerra Niño', 'tomas.becerra@dronandes.co',   'A', '2026-06-15', 2,    3);

insert into clientes (id_cliente, tipo, nombre, nit_documento, email, telefono, municipio, fecha_registro) values
(1,  'HOSPITAL', 'Hospital San Juan de Dios de Rionegro', '890980000-1', 'compras@hsjdrionegro.org', '6045310000', 'Rionegro',     '2024-03-01'),
(2,  'FARMACIA', 'Droguería La Esperanza',                '71234567',    'esperanza.drogueria@gmail.com', '3104567890', 'Guatapé',  '2024-09-12'),
(3,  'HOSPITAL', 'E.S.E. Hospital San Rafael de Tunja',   '891800231-6', 'Logistica@HSRTunja.gov.co', '6087405050', 'Tunja',       '2025-01-25'),
(4,  'ONG',      'Fundación Alas para el Campo',          '900456789-2', 'contacto@alasparaelcampo.org', NULL,      'Marinilla',   '2024-11-03'),
(5,  'COMERCIO', 'Repuestos Agrícolas El Arriero',        '900123456-7', NULL,                       '31245678',   'El Peñol',    '2025-04-18'),
(6,  'PERSONA',  'Mariana Gómez Arango',                  '1040123456',  'mariana.gomez@hotmail.com', '3157778899', 'Guarne',     '2025-07-07'),
(7,  'FARMACIA', 'Farmacia Botica del Páramo',            '900777888-1', 'boticaparamo@gmail.com',   '3209998877', 'Ventaquemada', '2025-02-14'),
(8,  'COMERCIO', 'Café de Altura Las Nubes',              '901222333-4', 'ventas@cafelasnubes.co',   '3001112233', 'Salento',      '2026-07-20'),
(9,  'PERSONA',  'Jorge Iván Ríos',                       '79888777',    NULL,                       NULL,         'Rionegro',     '2026-08-30'),
(10, 'ONG',      'Corporación Montaña Viva',              '900999111-0', 'info@montanaviva.org',     '310555444',  'Sáchica',      '2025-09-01');

insert into entregas (id_entrega, codigo, id_cliente, id_dron, id_piloto, fecha_programada, fecha_entrega, municipio_destino, distancia_km, prioridad, estado, calificacion) values
(1,  'ENT-0001', 1,  1, 3, '2026-08-03 08:00:00', '2026-08-03 08:42:00', 'San Vicente',          18.5, 'VITAL',   'ENTREGADA', 5),
(2,  'ENT-0002', 1,  3, 1, '2026-08-05 09:30:00', '2026-08-05 10:20:00', 'Concepción',           32.0, 'VITAL',   'ENTREGADA', 4),
(3,  'ENT-0003', 2,  4, 4, '2026-08-07 14:00:00', '2026-08-07 14:25:00', 'San Rafael',           12.0, 'NORMAL',  'ENTREGADA', 5),
(4,  'ENT-0004', 4,  2, 3, '2026-08-10 07:45:00', '2026-08-10 08:30:00', 'El Carmen de Viboral', 22.4, 'URGENTE', 'ENTREGADA', 3),
(5,  'ENT-0005', 5,  3, 1, '2026-08-12 11:00:00', NULL,                  'El Peñol',             15.0, 'NORMAL',  'CANCELADA', NULL),
(6,  'ENT-0006', 3,  6, 2, '2026-08-14 06:30:00', '2026-08-14 07:40:00', 'Ramiriquí',            48.0, 'VITAL',   'ENTREGADA', 5),
(7,  'ENT-0007', 10, 7, 6, '2026-08-18 10:00:00', '2026-08-18 10:35:00', 'Samacá',               20.5, 'NORMAL',  'ENTREGADA', 4),
(8,  'ENT-0008', 3,  8, 6, '2026-08-20 08:15:00', NULL,                  'Chíquiza',             35.0, 'URGENTE', 'FALLIDA',   NULL),
(9,  'ENT-0009', 6,  4, 5, '2026-08-22 16:00:00', '2026-08-22 16:20:00', 'Guarne',                9.5, 'NORMAL',  'ENTREGADA', 2),
(10, 'ENT-0010', 1,  1, 1, '2026-08-25 07:00:00', '2026-08-25 07:50:00', 'Sonsón',               41.0, 'VITAL',   'ENTREGADA', 5),
(11, 'ENT-0011', 10, 6, 2, '2026-08-27 09:00:00', '2026-08-27 10:05:00', 'Sáchica',              52.5, 'URGENTE', 'ENTREGADA', NULL),
(12, 'ENT-0012', 2,  5, 4, '2026-08-29 13:00:00', NULL,                  'Alejandría',           14.0, 'NORMAL',  'CANCELADA', NULL),
(13, 'ENT-0013', 4,  2, 1, '2026-09-01 08:00:00', '2026-09-01 08:55:00', 'Granada',              38.0, 'URGENTE', 'ENTREGADA', 4),
(14, 'ENT-0014', 1,  3, 1, '2026-09-03 10:30:00', '2026-09-03 11:15:00', 'Abejorral',            44.0, 'VITAL',   'ENTREGADA', 5),
(15, 'ENT-0015', 7,  7, 6, '2026-09-08 15:00:00', '2026-09-08 15:30:00', 'Turmequé',             17.0, 'NORMAL',  'ENTREGADA', 3),
(16, 'ENT-0016', 3,  6, 2, '2026-09-15 06:00:00', '2026-09-15 07:10:00', 'Miraflores',           58.0, 'VITAL',   'ENTREGADA', 4),
(17, 'ENT-0017', 6,  2, 3, '2026-09-21 17:00:00', NULL,                  'Guarne',               10.0, 'NORMAL',  'CANCELADA', NULL),
(18, 'ENT-0018', 10, 7, 6, '2026-09-30 17:40:00', NULL,                  'Villa de Leyva',       26.0, 'NORMAL',  'EN_VUELO',  NULL),
(19, 'ENT-0019', 1,  1, 1, '2026-10-01 07:30:00', NULL,                  'Nariño',               47.0, 'VITAL',   'PROGRAMADA', NULL),
(20, 'ENT-0020', 3,  6, 6, '2026-10-02 06:00:00', NULL,                  'Pesca',                39.0, 'VITAL',   'PROGRAMADA', NULL);

insert into carga_entrega (id_entrega, id_tipo, peso_kg, unidades) values
(1, 1, 3.00, 60),  (1, 3, 2.00, 15),
(2, 2, 1.50, 30),  (2, 3, 4.00, 40),
(3, 3, 1.80, 12),
(4, 3, 3.50, 25),  (4, 4, 0.50, 3),
(5, 5, 6.00, 4),
(6, 1, 5.00, 100), (6, 2, 2.00, 40),
(7, 3, 6.00, 50),
(8, 1, 8.00, 160), (8, 3, 4.00, 30),
(9, 4, 0.80, 5),
(10, 1, 4.00, 80), (10, 2, 1.00, 20), (10, 3, 2.50, 20),
(11, 3, 7.00, 60), (11, 4, 1.00, 6),
(13, 3, 5.00, 40), (13, 5, 2.00, 2),
(14, 1, 6.00, 120), (14, 2, 3.00, 60),
(15, 3, 3.00, 25), (15, 4, 0.30, 2),
(16, 1, 10.00, 200), (16, 3, 8.00, 70),
(18, 3, 4.00, 35),
(19, 1, 3.50, 70),
(20, 2, 2.50, 50), (20, 1, 6.00, 120);

insert into mantenimientos (id_mantenimiento, id_dron, fecha, tipo, descripcion, costo) values
(1, 2, '2026-03-15', 'PREVENTIVO', 'Cambio de hélices',                        350000),
(2, 4, '2026-04-02', 'PREVENTIVO', 'Calibración de GPS',                        180000),
(3, 5, '2026-09-25', 'CORRECTIVO', 'Falla en motor 3',                         1250000),
(4, 8, '2026-08-21', 'CORRECTIVO', 'Impacto en aterrizaje, evaluación de daños', 2800000),
(5, 1, '2026-06-10', 'PREVENTIVO', 'Revisión general de 300 horas',             420000),
(6, 6, '2026-07-05', 'PREVENTIVO', NULL,                                         260000),
(7, 5, '2026-05-14', 'PREVENTIVO', 'Cambio de baterías',                        950000),
(8, 2, '2026-09-12', 'CORRECTIVO', 'Sensor de altitud defectuoso',              610000);



-- =====================================================================
-- 5. dml: insert, update, delete
-- =====================================================================
-- las pruebas van dentro de una transaccion que al final se deshace
-- (rollback), para que los datos no cambien. ver la seccion 16.

-- ---------------------------------------------------------------------
-- 5.1 insert
-- ---------------------------------------------------------------------
start transaction;

-- a) con lista de columnas (la forma recomendada). las columnas que no
-- se escriben toman su default o null. id_base se omite: lo genera
-- auto_increment.
insert into bases (nombre, municipio, departamento, capacidad_drones, fecha_apertura)
values ('Base Demo', 'Medellín', 'Antioquia', 2, '2026-10-01');

-- b) varias filas en una sola sentencia
insert into tipos_carga (nombre, tarifa_kg, requiere_frio) values
('Sangre', 15000, true),
('Plasma', 14000, true);

-- c) usando los valores por defecto: estado queda 'ACTIVO' y horas_vuelo 0
insert into drones (codigo_serie, modelo, carga_max_kg, autonomia_km, fecha_adquisicion, id_base)
values ('DA-DEM-01', 'Demo', 5.00, 30.0, '2026-10-01', 1);

-- d) un valor null se escribe sin comillas
insert into clientes (tipo, nombre, nit_documento, email, telefono, municipio)
values ('PERSONA', 'Cliente Demo', '123456789', null, null, 'Rionegro');

-- e) insert ... select: inserta las filas que devuelve una consulta.
-- aqui se copian a una tabla nueva los clientes tipo HOSPITAL.
-- (create table ... like copia la estructura de otra tabla)
-- nota: create table hace commit implicito, por eso se hace fuera de la transaccion.
rollback;
create table clientes_copia like clientes;
insert into clientes_copia select * from clientes where tipo = 'HOSPITAL';
select id_cliente, nombre from clientes_copia;

-- f) create table ... as select: crea la tabla Y la llena con el resultado
create table resumen_entregas as
select id_cliente, count(*) as total_entregas
from entregas
group by id_cliente;
select * from resumen_entregas order by id_cliente;

drop table clientes_copia;
drop table resumen_entregas;

-- ---------------------------------------------------------------------
-- 5.2 update
-- ---------------------------------------------------------------------
-- sintaxis: update tabla set columna = valor [, columna = valor] where condicion;
-- SIEMPRE con where: sin where se actualizan todas las filas.
start transaction;

-- a) una columna, una fila
update drones set estado = 'MANTENIMIENTO' where id_dron = 1;

-- b) varias columnas
update drones set estado = 'ACTIVO', horas_vuelo = 0 where id_dron = 5;

-- c) con una expresion: el nuevo valor se calcula con el valor anterior
update drones set horas_vuelo = horas_vuelo + 10 where estado = 'ACTIVO';

-- d) con una condicion compuesta
update entregas set prioridad = 'URGENTE' where estado = 'PROGRAMADA' and distancia_km > 40;

-- e) con subconsulta en el where
update clientes set telefono = null
where id_cliente in (select id_cliente from entregas where estado = 'FALLIDA');

-- f) update con join: actualiza una tabla usando datos de otra
update entregas e
inner join drones d on d.id_dron = e.id_dron
set e.prioridad = 'URGENTE'
where d.estado = 'RETIRADO';

select id_dron, estado, horas_vuelo from drones order by id_dron;
rollback;

-- ---------------------------------------------------------------------
-- 5.3 delete
-- ---------------------------------------------------------------------
-- sintaxis: delete from tabla where condicion;
-- tambien SIEMPRE con where.
start transaction;

-- a) una fila
delete from mantenimientos where id_mantenimiento = 8;

-- b) por condicion
delete from mantenimientos where tipo = 'PREVENTIVO' and costo < 300000;

-- c) con subconsulta: entregas canceladas que no tienen carga
delete from entregas
where estado = 'CANCELADA'
and id_entrega not in (select id_entrega from carga_entrega);

select count(*) as mantenimientos_restantes from mantenimientos;
select count(*) as entregas_restantes from entregas;
rollback;

-- una fila padre con hijas NO se puede borrar (la fk lo impide).
-- por ejemplo, esto da error 1451 porque la base 1 tiene drones:
--   delete from bases where id_base = 1;
-- hay que borrar primero las filas hijas, o definir on delete cascade.

-- si el cliente tiene el modo seguro activado (error 1175 en un update o
-- delete sin llave), ejecutar antes:  set sql_safe_updates = 0;

-- diferencia entre los tres borrados
--   delete from tabla where ...   borra filas, se puede deshacer, activa triggers
--   truncate table tabla          vacia la tabla, reinicia el auto_increment
--   drop table tabla              borra la tabla completa (estructura y datos)


-- =====================================================================
-- 6. consultas basicas
-- =====================================================================
-- orden en que se escribe una consulta:
--   select ... from ... where ... group by ... having ... order by ... limit ...

-- 6.1 todas las columnas y filas
select * from bases;

-- 6.2 solo algunas columnas
select codigo_serie, modelo, estado from drones;

-- 6.3 alias de columna (as) y de tabla
select codigo_serie as serie, autonomia_km as autonomia from drones;
select d.codigo_serie from drones d;

-- 6.4 columnas calculadas
select codigo_serie, horas_vuelo, 1000 - horas_vuelo as horas_restantes from drones;

-- 6.5 distinct: elimina filas repetidas
select distinct modelo from drones;
select distinct licencia from pilotos;

-- 6.6 where: operadores de comparacion  =  <>  !=  >  <  >=  <=
select codigo, distancia_km from entregas where distancia_km > 40;
select codigo, estado from entregas where estado = 'ENTREGADA';
select codigo, estado from entregas where estado <> 'ENTREGADA';
select codigo, estado from entregas where estado != 'ENTREGADA';

-- 6.7 and, or, not (and se evalua antes que or: usar parentesis)
select codigo, prioridad, estado from entregas where prioridad = 'VITAL' and estado = 'ENTREGADA';
select codigo, prioridad from entregas where prioridad = 'VITAL' or prioridad = 'URGENTE';
select codigo, estado from entregas where not estado = 'ENTREGADA';
select codigo_serie, carga_max_kg, horas_vuelo, autonomia_km from drones
where (carga_max_kg >= 8 and horas_vuelo < 400) or autonomia_km > 80;

-- 6.8 between: rango, incluye los dos extremos
select codigo, distancia_km from entregas where distancia_km between 20 and 45;
select codigo, fecha_programada from entregas
where fecha_programada between '2026-09-01' and '2026-09-30 23:59:59';

-- 6.9 in / not in: pertenece a una lista
select codigo, prioridad from entregas where prioridad in ('VITAL', 'URGENTE');
select codigo, estado from entregas where estado not in ('ENTREGADA', 'CANCELADA');

-- 6.10 like: busqueda por patron
--   %  cualquier cantidad de caracteres (incluso ninguno)
--   _  exactamente un caracter
select nombre from clientes where nombre like 'Hospital%';
select nombre from clientes where nombre like '%Tunja';
select nombre from clientes where nombre like '%Alas%';
select codigo_serie from drones where codigo_serie like 'DA-CX_-__';
select nombre from clientes where nombre not like '%Hospital%';

-- 6.11 null: se pregunta con is null / is not null (nunca con = null)
select nombre from clientes where email is null;
select nombre from clientes where email is not null;
select nombre from clientes where telefono is null and email is null;

-- 6.12 order by: asc (por defecto) o desc; se puede ordenar por varias columnas
select codigo, distancia_km from entregas order by distancia_km desc;
select nombres, licencia, fecha_ingreso from pilotos order by licencia asc, fecha_ingreso desc;

-- 6.13 limit: limita la cantidad de filas; offset salta filas
select codigo, distancia_km from entregas order by distancia_km desc limit 3;
select codigo, distancia_km from entregas order by distancia_km desc limit 3 offset 3;

-- 6.14 case: condicional dentro de un select (como un if)
select codigo, distancia_km,
       case
           when distancia_km < 20 then 'CORTA'
           when distancia_km < 40 then 'MEDIA'
           else 'LARGA'
       end as categoria
from entregas
order by distancia_km;

-- 6.15 union: junta los resultados de dos consultas con las mismas columnas
-- union quita las filas repetidas; union all las deja
select nombre, 'CLIENTE' as origen from clientes where tipo = 'HOSPITAL'
union
select nombres, 'PILOTO' from pilotos where licencia = 'C';



-- 6.16 mas ejemplos de consultas basicas (cada uno con su enunciado)

-- a) las 5 entregas mas largas que ya fueron entregadas

select codigo, municipio_destino, distancia_km
from entregas
where estado = 'ENTREGADA'
order by distancia_km desc
limit 5;
-- resultado esperado:
-- +----------+-------------------+--------------+
-- | codigo   | municipio_destino | distancia_km |
-- +----------+-------------------+--------------+
-- | ENT-0016 | Miraflores        |         58.0 |
-- | ENT-0011 | Sáchica           |         52.5 |
-- | ENT-0006 | Ramiriquí         |         48.0 |
-- | ENT-0014 | Abejorral         |         44.0 |
-- | ENT-0010 | Sonsón            |         41.0 |
-- +----------+-------------------+--------------+

-- b) entregas de septiembre de 2026 (rango de fechas)

select codigo, fecha_programada, estado
from entregas
where fecha_programada >= '2026-09-01' and fecha_programada < '2026-10-01'
order by fecha_programada;
-- resultado esperado:
-- +----------+---------------------+-----------+
-- | codigo   | fecha_programada    | estado    |
-- +----------+---------------------+-----------+
-- | ENT-0013 | 2026-09-01 08:00:00 | ENTREGADA |
-- | ENT-0014 | 2026-09-03 10:30:00 | ENTREGADA |
-- | ENT-0015 | 2026-09-08 15:00:00 | ENTREGADA |
-- | ENT-0016 | 2026-09-15 06:00:00 | ENTREGADA |
-- | ENT-0017 | 2026-09-21 17:00:00 | CANCELADA |
-- | ENT-0018 | 2026-09-30 17:40:00 | EN_VUELO  |
-- +----------+---------------------+-----------+

-- c) entregas vitales o urgentes que no se cumplieron (parentesis por el or)

select codigo, prioridad, estado
from entregas
where (prioridad = 'VITAL' or prioridad = 'URGENTE')
and estado in ('CANCELADA', 'FALLIDA');
-- resultado esperado:
-- +----------+-----------+---------+
-- | codigo   | prioridad | estado  |
-- +----------+-----------+---------+
-- | ENT-0008 | URGENTE   | FALLIDA |
-- +----------+-----------+---------+

-- d) clientes que tienen correo pero no telefono

select nombre, email
from clientes
where email is not null and telefono is null;
-- resultado esperado:
-- +-------------------------------+------------------------------+
-- | nombre                        | email                        |
-- +-------------------------------+------------------------------+
-- | Fundación Alas para el Campo  | contacto@alasparaelcampo.org |
-- +-------------------------------+------------------------------+

-- e) pilotos cuyo apellido contiene 'ez' (like con % a los dos lados)

select nombres, apellidos
from pilotos
where apellidos like '%ez%';
-- resultado esperado:
-- +---------+---------------+
-- | nombres | apellidos     |
-- +---------+---------------+
-- | Mateo   | Zapata Vélez  |
-- | Daniela | Suárez León   |
-- +---------+---------------+

-- f) drones de la base 1 o de la base 3 con mas de 200 horas, ordenados por horas

select codigo_serie, id_base, horas_vuelo
from drones
where id_base in (1, 3) and horas_vuelo > 200
order by horas_vuelo desc;
-- resultado esperado:
-- +--------------+---------+-------------+
-- | codigo_serie | id_base | horas_vuelo |
-- +--------------+---------+-------------+
-- | DA-ALB-02    |       3 |       890.0 |
-- | DA-CX4-02    |       1 |       468.0 |
-- | DA-CX4-01    |       1 |       312.5 |
-- | DA-CX6-01    |       1 |       205.0 |
-- +--------------+---------+-------------+

-- g) mantenimientos correctivos de mas de 1 millon de pesos

select id_dron, fecha, descripcion, costo
from mantenimientos
where tipo = 'CORRECTIVO' and costo > 1000000
order by costo desc;
-- resultado esperado:
-- +---------+------------+----------------------------------------------+------------+
-- | id_dron | fecha      | descripcion                                  | costo      |
-- +---------+------------+----------------------------------------------+------------+
-- |       8 | 2026-08-21 | Impacto en aterrizaje, evaluación de daños   | 2800000.00 |
-- |       5 | 2026-09-25 | Falla en motor 3                             | 1250000.00 |
-- +---------+------------+----------------------------------------------+------------+

-- h) mantenimientos sin descripcion

select id_mantenimiento, id_dron, tipo
from mantenimientos
where descripcion is null;
-- resultado esperado:
-- +------------------+---------+------------+
-- | id_mantenimiento | id_dron | tipo       |
-- +------------------+---------+------------+
-- |                6 |       6 | PREVENTIVO |
-- +------------------+---------+------------+

-- i) tipos de carga que requieren cadena de frio, de la mas cara a la mas barata

select nombre, tarifa_kg
from tipos_carga
where requiere_frio = true
order by tarifa_kg desc;
-- resultado esperado:
-- +-------------------------+-----------+
-- | nombre                  | tarifa_kg |
-- +-------------------------+-----------+
-- | Vacunas                 |  12000.00 |
-- | Muestras de laboratorio |  10000.00 |
-- +-------------------------+-----------+

-- j) entregas con una columna que indica si hubo calificacion (case con is null)

select codigo, calificacion,
       case when calificacion is null then 'SIN CALIFICAR' else 'CALIFICADA' end as situacion
from entregas
where estado = 'ENTREGADA'
order by codigo
limit 6;
-- resultado esperado:
-- +----------+--------------+------------+
-- | codigo   | calificacion | situacion  |
-- +----------+--------------+------------+
-- | ENT-0001 |            5 | CALIFICADA |
-- | ENT-0002 |            4 | CALIFICADA |
-- | ENT-0003 |            5 | CALIFICADA |
-- | ENT-0004 |            3 | CALIFICADA |
-- | ENT-0006 |            5 | CALIFICADA |
-- | ENT-0007 |            4 | CALIFICADA |
-- +----------+--------------+------------+

-- k) cantidad de entregas por prioridad, solo las ENTREGADA, de mayor a menor

select prioridad, count(*) as total
from entregas
where estado = 'ENTREGADA'
group by prioridad
order by total desc;
-- resultado esperado:
-- +-----------+-------+
-- | prioridad | total |
-- +-----------+-------+
-- | VITAL     |     6 |
-- | NORMAL    |     4 |
-- | URGENTE   |     3 |
-- +-----------+-------+

-- l) los 3 clientes mas antiguos (los primeros registrados)

select nombre, fecha_registro
from clientes
order by fecha_registro asc
limit 3;
-- resultado esperado:
-- +---------------------------------------+----------------+
-- | nombre                                | fecha_registro |
-- +---------------------------------------+----------------+
-- | Hospital San Juan de Dios de Rionegro | 2024-03-01     |
-- | Droguería La Esperanza                | 2024-09-12     |
-- | Fundación Alas para el Campo          | 2024-11-03     |
-- +---------------------------------------+----------------+



-- =====================================================================
-- 7. funciones de texto, numeros, fechas y condicionales
-- =====================================================================

-- 7.1 texto
select upper(nombre) as mayusculas,           -- a mayusculas
       lower(nombre) as minusculas,           -- a minusculas
       length(nombre) as largo,               -- cantidad de caracteres
       substring(nombre, 1, 8) as primeros_8, -- substring(texto, inicio, cantidad)
       left(nombre, 4) as izquierda,          -- primeros n caracteres
       right(nombre, 4) as derecha,           -- ultimos n caracteres
       replace(nombre, 'Hospital', 'Hosp.') as reemplazo,
       trim('   hola   ') as sin_espacios
from clientes
where id_cliente = 1;

-- concat une textos (en mysql, si un valor es null el resultado es null)
select concat(nombres, ' ', apellidos) as nombre_completo from pilotos;
-- concat_ws pone un separador y ignora los null
select concat_ws(' - ', nombre, email, telefono) as ficha from clientes;

-- 7.2 numeros
select round(22.456, 1) as redondeo,          -- 22.5
       round(1250.7) as entero,               -- 1251
       ceil(2.1) as hacia_arriba,             -- 3
       floor(2.9) as hacia_abajo,             -- 2
       abs(-15) as valor_absoluto,            -- 15
       mod(10, 3) as residuo,                 -- 1
       10 / 4 as division;                    -- 2.5000

-- 7.3 fechas
select now() as ahora,                        -- fecha y hora actual
       curdate() as hoy,                      -- solo la fecha actual
       year('2026-10-22') as anio,
       month('2026-10-22') as mes,
       day('2026-10-22') as dia,
       datediff('2026-10-22', '2026-10-01') as dias_entre,
       date_add('2026-10-22', interval 10 day) as mas_10_dias,
       date_sub('2026-10-22', interval 1 month) as menos_1_mes,
       date_format('2026-10-22 14:30:00', '%d/%m/%Y') as formato;

-- minutos entre dos fechas con hora: timestampdiff(unidad, desde, hasta)
-- unidades: second, minute, hour, day, month, year
select codigo,
       timestampdiff(minute, fecha_programada, fecha_entrega) as minutos
from entregas
where fecha_entrega is not null
limit 5;

-- entregas por mes
select year(fecha_programada) as anio, month(fecha_programada) as mes, count(*) as total
from entregas
group by year(fecha_programada), month(fecha_programada)
order by anio, mes;

-- 7.4 manejo de null
-- coalesce(a, b, ...) devuelve el primer valor que no sea null
select nombre, coalesce(telefono, 'SIN TELÉFONO') as telefono from clientes;
-- ifnull(a, b): igual pero con dos valores (solo mysql)
select nombre, ifnull(email, 'SIN CORREO') as email from clientes;

-- 7.5 condicional con if(condicion, si_verdadero, si_falso) (solo mysql)
select codigo, if(estado = 'ENTREGADA', 'CERRADA', 'ABIERTA') as situacion from entregas;


-- =====================================================================
-- 8. agregacion: group by y having
-- =====================================================================
-- funciones de agregacion: resumen de muchas filas en un solo valor
--   count(*)         cantidad de filas
--   count(columna)   cantidad de filas con la columna no nula
--   count(distinct columna)  cantidad de valores distintos
--   sum, avg, min, max

-- 8.1 sin group by: un solo resultado para toda la tabla
select count(*) as total_entregas,
       count(calificacion) as con_calificacion,   -- ignora los null
       count(distinct id_cliente) as clientes_distintos,
       sum(distancia_km) as km_totales,
       avg(distancia_km) as km_promedio,
       min(distancia_km) as km_minimo,
       max(distancia_km) as km_maximo
from entregas;

-- 8.2 group by: un resultado por cada grupo
-- toda columna del select que no esta dentro de una funcion de agregacion
-- debe aparecer en el group by
select estado, count(*) as total from entregas group by estado;
select prioridad, estado, count(*) as total from entregas group by prioridad, estado order by prioridad, estado;

-- 8.3 where filtra filas ANTES de agrupar; having filtra grupos DESPUES
select id_cliente, count(*) as entregas_realizadas
from entregas
where estado = 'ENTREGADA'
group by id_cliente
having count(*) >= 2
order by entregas_realizadas desc;

-- 8.4 promedios con redondeo
select modelo, count(*) as unidades, round(avg(horas_vuelo), 1) as horas_promedio
from drones
group by modelo
order by horas_promedio desc;

-- 8.5 agrupar con un join
select b.nombre as base, count(d.id_dron) as drones
from bases b
left join drones d on d.id_base = b.id_base
group by b.id_base, b.nombre
order by drones desc;



-- 8.6 ejemplos de having
-- having filtra GRUPOS despues de agrupar (sobre count, sum, avg, min, max);
-- where filtra FILAS antes de agrupar.
-- ejemplo: clientes con al menos 2 entregas ENTREGADA.
-- sin having aparecen todos los clientes:
select id_cliente, count(*) as entregas_realizadas
from entregas
where estado = 'ENTREGADA'
group by id_cliente
order by id_cliente;
-- resultado esperado:
-- +------------+---------------------+
-- | id_cliente | entregas_realizadas |
-- +------------+---------------------+
-- |          1 |                   4 |
-- |          2 |                   1 |
-- |          3 |                   2 |
-- |          4 |                   2 |
-- |          6 |                   1 |
-- |          7 |                   1 |
-- |         10 |                   2 |
-- +------------+---------------------+

-- con having solo quedan los que tienen 2 o mas:
select id_cliente, count(*) as entregas_realizadas
from entregas
where estado = 'ENTREGADA'
group by id_cliente
having count(*) >= 2
order by id_cliente;
-- resultado esperado:
-- +------------+---------------------+
-- | id_cliente | entregas_realizadas |
-- +------------+---------------------+
-- |          1 |                   4 |
-- |          3 |                   2 |
-- |          4 |                   2 |
-- |         10 |                   2 |
-- +------------+---------------------+

-- error tipico: where count(*) >= 2 (el where no puede usar funciones de agregacion)

-- ejemplos de having (cada uno con su enunciado)

-- a) having con count: prioridades con mas de 5 entregas en total

select prioridad, count(*) as total
from entregas
group by prioridad
having count(*) > 5;
-- resultado esperado:
-- +-----------+-------+
-- | prioridad | total |
-- +-----------+-------+
-- | NORMAL    |     8 |
-- | VITAL     |     8 |
-- +-----------+-------+

-- b) having con sum: pilotos que han volado mas de 100 km en total

select concat(p.nombres, ' ', p.apellidos) as piloto, sum(e.distancia_km) as km_totales
from pilotos p
inner join entregas e on e.id_piloto = p.id_piloto
group by p.id_piloto, p.nombres, p.apellidos
having sum(e.distancia_km) > 100
order by km_totales desc;
-- resultado esperado:
-- +-----------------------+------------+
-- | piloto                | km_totales |
-- +-----------------------+------------+
-- | Laura Restrepo Gil    |      217.0 |
-- | Camilo Duarte Rojas   |      158.5 |
-- | Daniela Suárez León   |      137.5 |
-- +-----------------------+------------+

-- c) having con avg: clientes cuya calificacion promedio es de 4 o mas.
-- avg ignora los null, asi que las entregas sin calificacion no cuentan en el promedio.

select id_cliente, round(avg(calificacion), 2) as promedio, count(calificacion) as calificadas
from entregas
group by id_cliente
having avg(calificacion) >= 4
order by promedio desc;
-- resultado esperado:
-- +------------+----------+-------------+
-- | id_cliente | promedio | calificadas |
-- +------------+----------+-------------+
-- |          2 |     5.00 |           1 |
-- |          1 |     4.75 |           4 |
-- |          3 |     4.50 |           2 |
-- |         10 |     4.00 |           1 |
-- +------------+----------+-------------+

-- d) where y having en la misma consulta: where filtra filas (solo ENTREGADA)
-- y having filtra grupos (2 o mas entregas y promedio de distancia mayor a 30 km)

select id_cliente, count(*) as entregas, round(avg(distancia_km), 1) as km_promedio
from entregas
where estado = 'ENTREGADA'
group by id_cliente
having count(*) >= 2 and avg(distancia_km) > 30
order by km_promedio desc;
-- resultado esperado:
-- +------------+----------+-------------+
-- | id_cliente | entregas | km_promedio |
-- +------------+----------+-------------+
-- |          3 |        2 |        53.0 |
-- |         10 |        2 |        36.5 |
-- |          1 |        4 |        33.9 |
-- |          4 |        2 |        30.2 |
-- +------------+----------+-------------+

-- e) having con or: modelos con mas de 1 unidad o con horas promedio sobre 500

select modelo, count(*) as unidades, round(avg(horas_vuelo), 1) as horas_promedio
from drones
group by modelo
having count(*) > 1 or avg(horas_vuelo) > 500
order by modelo;
-- resultado esperado:
-- +---------------+----------+----------------+
-- | modelo        | unidades | horas_promedio |
-- +---------------+----------+----------------+
-- | Albatros H8   |        2 |          494.0 |
-- | Colibrí Mini  |        2 |          565.3 |
-- | Cóndor X4     |        2 |          390.3 |
-- | Cóndor X6     |        2 |          177.8 |
-- +---------------+----------+----------------+

-- f) having con max: bases en las que algun dron supera las 500 horas

select b.nombre as base, max(d.horas_vuelo) as max_horas
from bases b
inner join drones d on d.id_base = b.id_base
group by b.id_base, b.nombre
having max(d.horas_vuelo) > 500;
-- resultado esperado:
-- +-----------------+-----------+
-- | base            | max_horas |
-- +-----------------+-----------+
-- | Base Colibrí    |     610.0 |
-- | Base Frailejón  |     890.0 |
-- +-----------------+-----------+

-- g) having con count(distinct): clientes que han enviado 3 o mas tipos de carga distintos

select c.nombre as cliente, count(distinct ce.id_tipo) as tipos_distintos
from clientes c
inner join entregas e on e.id_cliente = c.id_cliente
inner join carga_entrega ce on ce.id_entrega = e.id_entrega
group by c.id_cliente, c.nombre
having count(distinct ce.id_tipo) >= 3;
-- resultado esperado:
-- +---------------------------------------+-----------------+
-- | cliente                               | tipos_distintos |
-- +---------------------------------------+-----------------+
-- | Hospital San Juan de Dios de Rionegro |               3 |
-- | E.S.E. Hospital San Rafael de Tunja   |               3 |
-- | Fundación Alas para el Campo          |               3 |
-- +---------------------------------------+-----------------+

-- h) having count(*) = 1: clientes con exactamente una entrega

select c.nombre as cliente, count(*) as total
from clientes c
inner join entregas e on e.id_cliente = c.id_cliente
group by c.id_cliente, c.nombre
having count(*) = 1
order by cliente;
-- resultado esperado:
-- +---------------------------------+-------+
-- | cliente                         | total |
-- +---------------------------------+-------+
-- | Farmacia Botica del Páramo      |     1 |
-- | Repuestos Agrícolas El Arriero  |     1 |
-- +---------------------------------+-------+

-- i) having con una subconsulta: clientes con mas entregas que el promedio
-- de entregas por cliente. (la subconsulta calcula ese promedio)

select id_cliente, count(*) as total
from entregas
group by id_cliente
having count(*) > (select count(*) / count(distinct id_cliente) from entregas)
order by total desc;
-- resultado esperado:
-- +------------+-------+
-- | id_cliente | total |
-- +------------+-------+
-- |          1 |     5 |
-- |          3 |     4 |
-- |         10 |     3 |
-- +------------+-------+

-- j) having sobre una columna del group by: funciona, pero es mejor usar where,
-- porque where descarta las filas antes de agrupar y hace menos trabajo.
-- las dos consultas dan el mismo resultado:

select estado, count(*) as total from entregas group by estado having estado <> 'CANCELADA';
-- resultado esperado:
-- +------------+-------+
-- | estado     | total |
-- +------------+-------+
-- | ENTREGADA  |    13 |
-- | EN_VUELO   |     1 |
-- | FALLIDA    |     1 |
-- | PROGRAMADA |     2 |
-- +------------+-------+

select estado, count(*) as total from entregas where estado <> 'CANCELADA' group by estado;
-- resultado esperado:
-- +------------+-------+
-- | estado     | total |
-- +------------+-------+
-- | ENTREGADA  |    13 |
-- | EN_VUELO   |     1 |
-- | FALLIDA    |     1 |
-- | PROGRAMADA |     2 |
-- +------------+-------+

-- k) agregacion condicional: sum(case ...) cuenta solo las filas que cumplen.
-- sirve para sacar varios conteos en una sola consulta y filtrarlos con having.
-- aqui: porcentaje de entregas cumplidas por cliente, solo los que tienen 3 o mas entregas.

select id_cliente,
       count(*) as total,
       sum(case when estado = 'ENTREGADA' then 1 else 0 end) as entregadas,
       round(sum(case when estado = 'ENTREGADA' then 1 else 0 end) * 100 / count(*), 1) as pct_cumplimiento
from entregas
group by id_cliente
having count(*) >= 3
order by pct_cumplimiento desc;
-- resultado esperado:
-- +------------+-------+------------+------------------+
-- | id_cliente | total | entregadas | pct_cumplimiento |
-- +------------+-------+------------+------------------+
-- |          1 |     5 |          4 |             80.0 |
-- |         10 |     3 |          2 |             66.7 |
-- |          3 |     4 |          2 |             50.0 |
-- +------------+-------+------------+------------------+

-- l) having con join y varias condiciones: bases con 2 o mas drones ACTIVO
-- y un promedio de horas de vuelo menor a 400

select b.nombre as base, count(*) as drones_activos, round(avg(d.horas_vuelo), 1) as horas_promedio
from bases b
inner join drones d on d.id_base = b.id_base
where d.estado = 'ACTIVO'
group by b.id_base, b.nombre
having count(*) >= 2 and avg(d.horas_vuelo) < 400;
-- resultado esperado:
-- +-----------------+----------------+----------------+
-- | base            | drones_activos | horas_promedio |
-- +-----------------+----------------+----------------+
-- | Base Cóndor     |              3 |          328.5 |
-- | Base Frailejón  |              2 |          124.3 |
-- +-----------------+----------------+----------------+


-- =====================================================================
-- 9. consultas multitabla (joins)
-- =====================================================================
-- un join une filas de dos tablas usando la condicion del on
-- (casi siempre pk = fk).

-- 9.1 inner join: solo las filas que tienen pareja en las dos tablas
select e.codigo, c.nombre as cliente
from entregas e
inner join clientes c on c.id_cliente = e.id_cliente;

-- 9.2 left join: todas las filas de la tabla izquierda; si no tienen pareja,
-- las columnas de la derecha salen en null
select c.nombre, e.codigo
from clientes c
left join entregas e on e.id_cliente = c.id_cliente
order by c.nombre;

-- 9.3 right join: lo mismo pero conserva la tabla derecha
select e.codigo, c.nombre
from entregas e
right join clientes c on c.id_cliente = e.id_cliente;

-- 9.4 left join + is null: filas de la izquierda SIN pareja
-- (clientes que nunca han tenido una entrega)
select c.nombre
from clientes c
left join entregas e on e.id_cliente = c.id_cliente
where e.id_entrega is null;

-- 9.5 varios joins en una consulta: cada join agrega una tabla
select e.codigo,
       c.nombre as cliente,
       concat(p.nombres, ' ', p.apellidos) as piloto,
       d.codigo_serie as dron,
       b.nombre as base
from entregas e
inner join clientes c on c.id_cliente = e.id_cliente
inner join pilotos p on p.id_piloto = e.id_piloto
inner join drones d on d.id_dron = e.id_dron
inner join bases b on b.id_base = d.id_base
order by e.codigo;

-- 9.6 join con relacion n:m (tabla intermedia carga_entrega)
select e.codigo, tc.nombre as tipo_carga, ce.peso_kg, ce.unidades
from entregas e
inner join carga_entrega ce on ce.id_entrega = e.id_entrega
inner join tipos_carga tc on tc.id_tipo = ce.id_tipo
where e.codigo = 'ENT-0010';

-- 9.7 autojoin: una tabla unida consigo misma (necesita dos alias distintos)
-- cada piloto con su supervisor
select concat(p.nombres, ' ', p.apellidos) as piloto,
       coalesce(concat(s.nombres, ' ', s.apellidos), 'SIN SUPERVISOR') as supervisor
from pilotos p
left join pilotos s on s.id_piloto = p.id_supervisor;

-- 9.8 left join con condicion en el on
-- la condicion sobre la tabla derecha va en el ON, no en el where; si va en
-- el where se pierden las filas sin pareja y el left join se vuelve inner join
select concat(p.nombres, ' ', p.apellidos) as piloto, count(e.id_entrega) as entregadas
from pilotos p
left join entregas e on e.id_piloto = p.id_piloto and e.estado = 'ENTREGADA'
group by p.id_piloto, p.nombres, p.apellidos;

-- 9.9 cross join: todas las combinaciones posibles (producto cartesiano)
select b.nombre as base, tc.nombre as tipo_carga
from bases b
cross join tipos_carga tc
limit 6;



-- 9.10 mas ejemplos de consultas multitabla (cada uno con su enunciado)

-- a) peso total y valor de la carga de cada entrega (join de 3 tablas + group by)

select e.codigo,
       sum(ce.peso_kg) as peso_total_kg,
       sum(ce.peso_kg * tc.tarifa_kg) as valor_carga
from entregas e
inner join carga_entrega ce on ce.id_entrega = e.id_entrega
inner join tipos_carga tc on tc.id_tipo = ce.id_tipo
group by e.id_entrega, e.codigo
order by valor_carga desc
limit 5;
-- resultado esperado:
-- +----------+---------------+-------------+
-- | codigo   | peso_total_kg | valor_carga |
-- +----------+---------------+-------------+
-- | ENT-0016 |         18.00 | 184000.0000 |
-- | ENT-0008 |         12.00 | 128000.0000 |
-- | ENT-0014 |          9.00 | 102000.0000 |
-- | ENT-0020 |          8.50 |  97000.0000 |
-- | ENT-0006 |          7.00 |  80000.0000 |
-- +----------+---------------+-------------+

-- b) tipos de carga distintos que ha enviado cada cliente (distinct)

select distinct c.nombre as cliente, tc.nombre as tipo_carga
from clientes c
inner join entregas e on e.id_cliente = c.id_cliente
inner join carga_entrega ce on ce.id_entrega = e.id_entrega
inner join tipos_carga tc on tc.id_tipo = ce.id_tipo
where c.id_cliente in (1, 3)
order by cliente, tipo_carga;
-- resultado esperado:
-- +---------------------------------------+-------------------------+
-- | cliente                               | tipo_carga              |
-- +---------------------------------------+-------------------------+
-- | E.S.E. Hospital San Rafael de Tunja   | Medicamentos            |
-- | E.S.E. Hospital San Rafael de Tunja   | Muestras de laboratorio |
-- | E.S.E. Hospital San Rafael de Tunja   | Vacunas                 |
-- | Hospital San Juan de Dios de Rionegro | Medicamentos            |
-- | Hospital San Juan de Dios de Rionegro | Muestras de laboratorio |
-- | Hospital San Juan de Dios de Rionegro | Vacunas                 |
-- +---------------------------------------+-------------------------+

-- c) cada dron con su base, cantidad de mantenimientos y costo total (left join: incluye los que no tienen)

select d.codigo_serie, b.nombre as base,
       count(m.id_mantenimiento) as mantenimientos,
       coalesce(sum(m.costo), 0) as costo_total
from drones d
inner join bases b on b.id_base = d.id_base
left join mantenimientos m on m.id_dron = d.id_dron
group by d.id_dron, d.codigo_serie, b.nombre
order by d.codigo_serie;
-- resultado esperado:
-- +--------------+-----------------+----------------+-------------+
-- | codigo_serie | base            | mantenimientos | costo_total |
-- +--------------+-----------------+----------------+-------------+
-- | DA-ALB-01    | Base Frailejón  |              1 |   260000.00 |
-- | DA-ALB-02    | Base Frailejón  |              1 |  2800000.00 |
-- | DA-COL-01    | Base Colibrí    |              1 |   180000.00 |
-- | DA-COL-02    | Base Colibrí    |              2 |  2200000.00 |
-- | DA-CX4-01    | Base Cóndor     |              1 |   420000.00 |
-- | DA-CX4-02    | Base Cóndor     |              2 |   960000.00 |
-- | DA-CX6-01    | Base Cóndor     |              0 |        0.00 |
-- | DA-CX6-02    | Base Frailejón  |              0 |        0.00 |
-- +--------------+-----------------+----------------+-------------+

-- d) cada piloto con su base y su supervisor (join normal + autojoin en la misma consulta)

select concat(p.nombres, ' ', p.apellidos) as piloto,
       b.nombre as base,
       coalesce(concat(s.nombres, ' ', s.apellidos), 'SIN SUPERVISOR') as supervisor
from pilotos p
inner join bases b on b.id_base = p.id_base
left join pilotos s on s.id_piloto = p.id_supervisor
order by piloto;
-- resultado esperado:
-- +-----------------------+-----------------+---------------------+
-- | piloto                | base            | supervisor          |
-- +-----------------------+-----------------+---------------------+
-- | Camilo Duarte Rojas   | Base Frailejón  | SIN SUPERVISOR      |
-- | Daniela Suárez León   | Base Frailejón  | Camilo Duarte Rojas |
-- | Julián Patiño Cruz    | Base Colibrí    | Laura Restrepo Gil  |
-- | Laura Restrepo Gil    | Base Cóndor     | SIN SUPERVISOR      |
-- | Mateo Zapata Vélez    | Base Cóndor     | Laura Restrepo Gil  |
-- | Sara Montoya Ruiz     | Base Colibrí    | Laura Restrepo Gil  |
-- | Tomás Becerra Niño    | Base Frailejón  | Camilo Duarte Rojas |
-- +-----------------------+-----------------+---------------------+

-- e) drones que nunca han hecho una entrega (left join + is null)

select d.codigo_serie, d.estado
from drones d
left join entregas e on e.id_dron = d.id_dron
where e.id_entrega is null;
-- resultado esperado:
--

-- f) entregas ENTREGADA que llevaron carga con cadena de frio

select distinct e.codigo, tc.nombre as tipo_carga
from entregas e
inner join carga_entrega ce on ce.id_entrega = e.id_entrega
inner join tipos_carga tc on tc.id_tipo = ce.id_tipo
where e.estado = 'ENTREGADA' and tc.requiere_frio = true
order by e.codigo, tipo_carga
limit 8;
-- resultado esperado:
-- +----------+-------------------------+
-- | codigo   | tipo_carga              |
-- +----------+-------------------------+
-- | ENT-0001 | Vacunas                 |
-- | ENT-0002 | Muestras de laboratorio |
-- | ENT-0006 | Muestras de laboratorio |
-- | ENT-0006 | Vacunas                 |
-- | ENT-0010 | Muestras de laboratorio |
-- | ENT-0010 | Vacunas                 |
-- | ENT-0014 | Muestras de laboratorio |
-- | ENT-0014 | Vacunas                 |
-- +----------+-------------------------+

-- g) costo total de mantenimiento por base (3 tablas: bases -> drones -> mantenimientos)

select b.nombre as base, count(m.id_mantenimiento) as mantenimientos, sum(m.costo) as costo_total
from bases b
inner join drones d on d.id_base = b.id_base
inner join mantenimientos m on m.id_dron = d.id_dron
group by b.id_base, b.nombre
order by costo_total desc;
-- resultado esperado:
-- +-----------------+----------------+-------------+
-- | base            | mantenimientos | costo_total |
-- +-----------------+----------------+-------------+
-- | Base Frailejón  |              2 |  3060000.00 |
-- | Base Colibrí    |              3 |  2380000.00 |
-- | Base Cóndor     |              3 |  1380000.00 |
-- +-----------------+----------------+-------------+

-- h) entregas por piloto y por prioridad (group by con dos columnas)

select concat(p.nombres, ' ', p.apellidos) as piloto, e.prioridad, count(*) as total
from pilotos p
inner join entregas e on e.id_piloto = p.id_piloto
group by p.id_piloto, p.nombres, p.apellidos, e.prioridad
order by piloto, e.prioridad
limit 8;
-- resultado esperado:
-- +-----------------------+-----------+-------+
-- | piloto                | prioridad | total |
-- +-----------------------+-----------+-------+
-- | Camilo Duarte Rojas   | URGENTE   |     1 |
-- | Camilo Duarte Rojas   | VITAL     |     2 |
-- | Daniela Suárez León   | NORMAL    |     3 |
-- | Daniela Suárez León   | URGENTE   |     1 |
-- | Daniela Suárez León   | VITAL     |     1 |
-- | Julián Patiño Cruz    | NORMAL    |     1 |
-- | Laura Restrepo Gil    | NORMAL    |     1 |
-- | Laura Restrepo Gil    | URGENTE   |     1 |
-- +-----------------------+-----------+-------+

-- i) los 3 clientes con mayor valor de carga transportada (4 tablas + order by + limit)

select c.nombre as cliente, sum(ce.peso_kg * tc.tarifa_kg) as valor_carga
from clientes c
inner join entregas e on e.id_cliente = c.id_cliente
inner join carga_entrega ce on ce.id_entrega = e.id_entrega
inner join tipos_carga tc on tc.id_tipo = ce.id_tipo
group by c.id_cliente, c.nombre
order by valor_carga desc
limit 3;
-- resultado esperado:
-- +---------------------------------------+-------------+
-- | cliente                               | valor_carga |
-- +---------------------------------------+-------------+
-- | E.S.E. Hospital San Rafael de Tunja   | 489000.0000 |
-- | Hospital San Juan de Dios de Rionegro | 321000.0000 |
-- | Corporación Montaña Viva              | 141000.0000 |
-- +---------------------------------------+-------------+

-- j) cada entrega ENTREGADA con la base de origen del dron y la calificacion (si no hay, 'SIN CALIFICAR')

select e.codigo, b.nombre as base_origen, e.municipio_destino,
       coalesce(e.calificacion, 'SIN CALIFICAR') as calificacion
from entregas e
inner join drones d on d.id_dron = e.id_dron
inner join bases b on b.id_base = d.id_base
where e.estado = 'ENTREGADA'
order by e.codigo
limit 6;
-- resultado esperado:
-- +----------+-----------------+----------------------+--------------+
-- | codigo   | base_origen     | municipio_destino    | calificacion |
-- +----------+-----------------+----------------------+--------------+
-- | ENT-0001 | Base Cóndor     | San Vicente          | 5            |
-- | ENT-0002 | Base Cóndor     | Concepción           | 4            |
-- | ENT-0003 | Base Colibrí    | San Rafael           | 5            |
-- | ENT-0004 | Base Cóndor     | El Carmen de Viboral | 3            |
-- | ENT-0006 | Base Frailejón  | Ramiriquí            | 5            |
-- | ENT-0007 | Base Frailejón  | Samacá               | 4            |
-- +----------+-----------------+----------------------+--------------+

-- k) bases con la cantidad de drones y de pilotos (dos conteos independientes: cada uno en una subconsulta)

select b.nombre as base,
       (select count(*) from drones d where d.id_base = b.id_base) as drones,
       (select count(*) from pilotos p where p.id_base = b.id_base) as pilotos
from bases b
order by b.nombre;
-- resultado esperado:
-- +-----------------+--------+---------+
-- | base            | drones | pilotos |
-- +-----------------+--------+---------+
-- | Base Colibrí    |      2 |       2 |
-- | Base Cóndor     |      3 |       2 |
-- | Base Frailejón  |      3 |       3 |
-- | Base Guadua     |      0 |       0 |
-- +-----------------+--------+---------+

-- cuidado: si se hace left join de drones y de pilotos a la vez en una sola consulta,
-- las filas se multiplican y los count salen inflados. cuando hay dos relaciones
-- 1:N independientes, se usan subconsultas (como arriba) o count(distinct ...).

-- l) union de left y right join: todas las bases y todos los drones aunque no tengan pareja
-- (en mysql no existe full outer join; se simula con union)

select b.nombre as base, d.codigo_serie
from bases b left join drones d on d.id_base = b.id_base
union
select b.nombre, d.codigo_serie
from bases b right join drones d on d.id_base = b.id_base
order by base, codigo_serie;
-- resultado esperado:
-- +-----------------+--------------+
-- | base            | codigo_serie |
-- +-----------------+--------------+
-- | Base Colibrí    | DA-COL-01    |
-- | Base Colibrí    | DA-COL-02    |
-- | Base Cóndor     | DA-CX4-01    |
-- | Base Cóndor     | DA-CX4-02    |
-- | Base Cóndor     | DA-CX6-01    |
-- | Base Frailejón  | DA-ALB-01    |
-- | Base Frailejón  | DA-ALB-02    |
-- | Base Frailejón  | DA-CX6-02    |
-- | Base Guadua     | NULL         |
-- +-----------------+--------------+



-- =====================================================================
-- 10. subconsultas
-- =====================================================================
-- una subconsulta es un select dentro de otro, entre parentesis.

-- 10.1 escalar: devuelve un solo valor; se compara con =, >, <, etc.
select codigo, distancia_km
from entregas
where distancia_km > (select avg(distancia_km) from entregas);

-- 10.2 en el select: una columna calculada por una subconsulta
select c.nombre,
       (select count(*) from entregas e where e.id_cliente = c.id_cliente) as total_entregas
from clientes c;

-- 10.3 in: la subconsulta devuelve una lista de valores
select nombre from clientes
where id_cliente in (select id_cliente from entregas where prioridad = 'VITAL');

-- 10.4 not in: los que NO estan en la lista
-- cuidado: si la lista tiene algun null, not in no devuelve nada
select nombre from clientes
where id_cliente not in (select id_cliente from entregas);

-- 10.5 exists / not exists: verdadero si la subconsulta devuelve (o no) filas
-- select 1 solo comprueba que exista una fila
select d.codigo_serie from drones d
where exists (select 1 from mantenimientos m where m.id_dron = d.id_dron);

select d.codigo_serie from drones d
where not exists (select 1 from mantenimientos m where m.id_dron = d.id_dron);

-- 10.6 correlacionada: usa una columna de la consulta de afuera, asi que
-- se vuelve a ejecutar para cada fila
-- drones con mas horas que el promedio de su propia base
select d.codigo_serie, d.id_base, d.horas_vuelo
from drones d
where d.horas_vuelo > (select avg(d2.horas_vuelo) from drones d2 where d2.id_base = d.id_base);

-- 10.7 en el from (tabla derivada): la subconsulta funciona como una tabla
-- y OBLIGATORIAMENTE lleva alias
select t.estado, t.total
from (select estado, count(*) as total from entregas group by estado) t
where t.total > 2;

-- 10.8 con max/min: la entrega mas larga
select codigo, distancia_km from entregas
where distancia_km = (select max(distancia_km) from entregas);

-- 10.9 any / all: comparar contra varios valores
-- distancia mayor que TODAS las distancias de entregas NORMAL
select codigo, distancia_km from entregas
where distancia_km > all (select distancia_km from entregas where prioridad = 'NORMAL');



-- 10.10 mas ejemplos de subconsultas (cada uno con su enunciado)

-- a) in: pilotos que han hecho alguna entrega VITAL

select concat(nombres, ' ', apellidos) as piloto
from pilotos
where id_piloto in (select id_piloto from entregas where prioridad = 'VITAL')
order by piloto;
-- resultado esperado:
-- +-----------------------+
-- | piloto                |
-- +-----------------------+
-- | Camilo Duarte Rojas   |
-- | Daniela Suárez León   |
-- | Laura Restrepo Gil    |
-- | Mateo Zapata Vélez    |
-- +-----------------------+

-- b) not exists: pilotos sin ninguna entrega ENTREGADA

select concat(p.nombres, ' ', p.apellidos) as piloto
from pilotos p
where not exists (select 1 from entregas e where e.id_piloto = p.id_piloto and e.estado = 'ENTREGADA');
-- resultado esperado:
-- +----------------------+
-- | piloto               |
-- +----------------------+
-- | Tomás Becerra Niño   |
-- +----------------------+

-- c) exists: clientes que han tenido alguna entrega FALLIDA

select c.nombre
from clientes c
where exists (select 1 from entregas e where e.id_cliente = c.id_cliente and e.estado = 'FALLIDA');
-- resultado esperado:
-- +-------------------------------------+
-- | nombre                              |
-- +-------------------------------------+
-- | E.S.E. Hospital San Rafael de Tunja |
-- +-------------------------------------+

-- d) correlacionada: entregas cuya distancia supera el promedio de las entregas de ese mismo cliente

select e.codigo, e.id_cliente, e.distancia_km
from entregas e
where e.distancia_km > (select avg(e2.distancia_km) from entregas e2 where e2.id_cliente = e.id_cliente)
order by e.id_cliente, e.distancia_km desc;
-- resultado esperado:
-- +----------+------------+--------------+
-- | codigo   | id_cliente | distancia_km |
-- +----------+------------+--------------+
-- | ENT-0019 |          1 |         47.0 |
-- | ENT-0014 |          1 |         44.0 |
-- | ENT-0010 |          1 |         41.0 |
-- | ENT-0012 |          2 |         14.0 |
-- | ENT-0016 |          3 |         58.0 |
-- | ENT-0006 |          3 |         48.0 |
-- | ENT-0013 |          4 |         38.0 |
-- | ENT-0017 |          6 |         10.0 |
-- | ENT-0011 |         10 |         52.5 |
-- +----------+------------+--------------+

-- e) el dron con mas horas de vuelo (subconsulta con max)

select codigo_serie, modelo, horas_vuelo
from drones
where horas_vuelo = (select max(horas_vuelo) from drones);
-- resultado esperado:
-- +--------------+-------------+-------------+
-- | codigo_serie | modelo      | horas_vuelo |
-- +--------------+-------------+-------------+
-- | DA-ALB-02    | Albatros H8 |       890.0 |
-- +--------------+-------------+-------------+

-- f) tabla derivada: clientes cuyo total de km supera el promedio de km por cliente

select t.id_cliente, t.km_totales
from (select id_cliente, sum(distancia_km) as km_totales from entregas group by id_cliente) t
where t.km_totales > (select avg(km_totales) from (select sum(distancia_km) as km_totales from entregas group by id_cliente) x)
order by t.km_totales desc;
-- resultado esperado:
-- +------------+------------+
-- | id_cliente | km_totales |
-- +------------+------------+
-- |          1 |      182.5 |
-- |          3 |      180.0 |
-- |         10 |       99.0 |
-- +------------+------------+

-- g) subconsulta dentro de having: bases con mas drones que el promedio de drones por base

select b.nombre as base, count(*) as drones
from bases b
inner join drones d on d.id_base = b.id_base
group by b.id_base, b.nombre
having count(*) > (select count(*) / count(distinct id_base) from drones);
-- resultado esperado:
-- +-----------------+--------+
-- | base            | drones |
-- +-----------------+--------+
-- | Base Cóndor     |      3 |
-- | Base Frailejón  |      3 |
-- +-----------------+--------+

-- h) not in: tipos de carga que nunca se han transportado en una entrega ENTREGADA

select nombre
from tipos_carga
where id_tipo not in (
    select ce.id_tipo
    from carga_entrega ce
    inner join entregas e on e.id_entrega = ce.id_entrega
    where e.estado = 'ENTREGADA'
);
-- resultado esperado:
-- +-----------+
-- | nombre    |
-- +-----------+
-- | Alimentos |
-- +-----------+

-- i) subconsulta en el select: porcentaje que representa cada entrega del total de km

select codigo, distancia_km,
       round(distancia_km * 100 / (select sum(distancia_km) from entregas), 2) as pct_del_total
from entregas
order by pct_del_total desc
limit 5;
-- resultado esperado:
-- +----------+--------------+---------------+
-- | codigo   | distancia_km | pct_del_total |
-- +----------+--------------+---------------+
-- | ENT-0016 |         58.0 |          9.68 |
-- | ENT-0011 |         52.5 |          8.76 |
-- | ENT-0006 |         48.0 |          8.01 |
-- | ENT-0019 |         47.0 |          7.84 |
-- | ENT-0014 |         44.0 |          7.34 |
-- +----------+--------------+---------------+

-- j) la entrega mas reciente (fecha maxima)

select codigo, fecha_programada, estado
from entregas
where fecha_programada = (select max(fecha_programada) from entregas);
-- resultado esperado:
-- +----------+---------------------+------------+
-- | codigo   | fecha_programada    | estado     |
-- +----------+---------------------+------------+
-- | ENT-0020 | 2026-10-02 06:00:00 | PROGRAMADA |
-- +----------+---------------------+------------+

-- k) tabla derivada con join: cada cliente con la fecha de su ultima entrega

select c.nombre, u.ultima_entrega
from clientes c
inner join (select id_cliente, max(fecha_programada) as ultima_entrega from entregas group by id_cliente) u
        on u.id_cliente = c.id_cliente
order by u.ultima_entrega desc
limit 5;
-- resultado esperado:
-- +---------------------------------------+---------------------+
-- | nombre                                | ultima_entrega      |
-- +---------------------------------------+---------------------+
-- | E.S.E. Hospital San Rafael de Tunja   | 2026-10-02 06:00:00 |
-- | Hospital San Juan de Dios de Rionegro | 2026-10-01 07:30:00 |
-- | Corporación Montaña Viva              | 2026-09-30 17:40:00 |
-- | Mariana Gómez Arango                  | 2026-09-21 17:00:00 |
-- | Farmacia Botica del Páramo            | 2026-09-08 15:00:00 |
-- +---------------------------------------+---------------------+

-- l) any: entregas con distancia mayor que alguna entrega VITAL de menos de 20 km
-- (any = mayor que al menos uno de los valores de la lista)

select codigo, distancia_km
from entregas
where distancia_km > any (select distancia_km from entregas where prioridad = 'VITAL' and distancia_km < 20)
order by distancia_km
limit 5;
-- resultado esperado:
-- +----------+--------------+
-- | codigo   | distancia_km |
-- +----------+--------------+
-- | ENT-0007 |         20.5 |
-- | ENT-0004 |         22.4 |
-- | ENT-0018 |         26.0 |
-- | ENT-0002 |         32.0 |
-- | ENT-0008 |         35.0 |
-- +----------+--------------+

-- cuando usar cada una:
--   in / not in        comparar un valor contra una lista corta de valores
--   exists / not exists  solo importa si hay o no filas (suele ser mas claro y seguro con null)
--   escalar (= > <)    comparar contra un solo valor (promedio, maximo)
--   correlacionada     la comparacion depende de cada fila de afuera
--   en el from         cuando se necesita un resultado intermedio (agrupado) para seguir consultando



-- =====================================================================
-- 11. vistas
-- =====================================================================
-- una vista es una consulta guardada con nombre. no guarda datos: se
-- ejecuta cada vez que se consulta, asi que siempre muestra los datos actuales.
-- sirve para simplificar consultas largas y para dar acceso a solo
-- algunas columnas.

-- 11.1 crear una vista simple
create view vw_drones_activos as
select id_dron, codigo_serie, modelo, horas_vuelo
from drones
where estado = 'ACTIVO';

-- se consulta como si fuera una tabla
select * from vw_drones_activos;
select * from vw_drones_activos where horas_vuelo > 300 order by horas_vuelo desc;

-- 11.2 vista con joins
create view vw_entregas_detalle as
select e.codigo, e.fecha_programada, c.nombre as cliente, d.codigo_serie as dron,
       concat(p.nombres, ' ', p.apellidos) as piloto, e.estado
from entregas e
inner join clientes c on c.id_cliente = e.id_cliente
inner join drones d on d.id_dron = e.id_dron
inner join pilotos p on p.id_piloto = e.id_piloto;

select * from vw_entregas_detalle where estado = 'ENTREGADA' order by fecha_programada limit 5;

-- 11.3 vista con agregacion y left join (incluye entregas sin carga)
create view vw_resumen_cliente as
select c.id_cliente, c.nombre,
       count(e.id_entrega) as total_entregas,
       coalesce(sum(e.distancia_km), 0) as km_totales
from clientes c
left join entregas e on e.id_cliente = c.id_cliente
group by c.id_cliente, c.nombre;

select * from vw_resumen_cliente order by total_entregas desc;

-- 11.4 modificar una vista: create or replace view
create or replace view vw_drones_activos as
select id_dron, codigo_serie, modelo, horas_vuelo, autonomia_km
from drones
where estado = 'ACTIVO';

-- 11.5 ver las vistas y su definicion
show full tables where table_type = 'VIEW';
show create view vw_drones_activos;

-- 11.6 borrar una vista
drop view if exists vw_drones_activos;
drop view if exists vw_entregas_detalle;
drop view if exists vw_resumen_cliente;


-- =====================================================================
-- 12. indices
-- =====================================================================
-- un indice acelera las busquedas por una columna (como el indice de un
-- libro) pero ocupa espacio y hace un poco mas lentos los insert y update.
-- mysql crea solos los indices de las primary key, de las unique y de las
-- foreign key: solo se crean a mano para otras columnas muy consultadas.

-- 12.1 indice simple
create index idx_entregas_prioridad on entregas (prioridad);

-- 12.2 indice compuesto: primero la columna que se compara con =, despues
-- la que se compara con un rango
create index idx_entregas_estado_fecha on entregas (estado, fecha_programada);

-- 12.3 indice unico (equivale a una restriccion unique)
create unique index idx_pilotos_documento_unico on pilotos (documento);

-- 12.4 ver los indices de una tabla
show index from entregas;

-- 12.5 explain muestra como ejecuta mysql la consulta y que indice usa
-- (columna key del resultado)
explain select * from entregas where estado = 'ENTREGADA' and fecha_programada >= '2026-09-01';

-- 12.6 borrar indices
drop index idx_entregas_prioridad on entregas;
drop index idx_entregas_estado_fecha on entregas;
drop index idx_pilotos_documento_unico on pilotos;


-- =====================================================================
-- 13. funciones almacenadas
-- =====================================================================
-- una funcion recibe parametros y DEVUELVE UN SOLO VALOR; se usa dentro
-- de un select como cualquier otra funcion (upper, round, etc.).
-- forma de crearla en mysql:
--   create function nombre(parametro tipo)
--   returns tipo_que_devuelve
--   [deterministic | reads sql data]
--   begin
--       declare variables;
--       ...
--       return valor;
--   end;
-- deterministic: siempre devuelve lo mismo con los mismos parametros y no
-- lee tablas. reads sql data: lee tablas pero no las modifica.
-- mysql exige declarar una de las dos cuando el registro binario esta activo.
-- declare: las variables se declaran al inicio del bloque; set asigna.

-- 13.1 funcion simple con calculo
create function fn_demo_iva(p_valor decimal(12,2))
returns decimal(12,2)
deterministic
begin
    return round(p_valor * 1.19, 2);
end;

select fn_demo_iva(100000) as valor_con_iva;

-- 13.2 funcion con if: clasifica una distancia
create function fn_demo_categoria_distancia(p_km decimal(5,1))
returns varchar(10)
deterministic
begin
    declare v_categoria varchar(10);

    if p_km < 20 then
        set v_categoria = 'CORTA';
    elseif p_km < 40 then
        set v_categoria = 'MEDIA';
    else
        set v_categoria = 'LARGA';
    end if;

    return v_categoria;
end;

select codigo, distancia_km, fn_demo_categoria_distancia(distancia_km) as categoria
from entregas
order by distancia_km;

-- 13.3 funcion que consulta tablas (select ... into)
create function fn_demo_total_entregas(p_id_cliente int)
returns int
reads sql data
begin
    declare v_total int;

    select count(*) into v_total
    from entregas
    where id_cliente = p_id_cliente;

    return v_total;
end;

select nombre, fn_demo_total_entregas(id_cliente) as total_entregas from clientes;

-- ver y borrar funciones
show function status where db = 'dronandes';
drop function if exists fn_demo_iva;
drop function if exists fn_demo_categoria_distancia;
drop function if exists fn_demo_total_entregas;


-- =====================================================================
-- 14. procedimientos almacenados
-- =====================================================================
-- un procedimiento es un conjunto de sentencias con nombre que se
-- ejecuta con call. a diferencia de la funcion: puede modificar tablas
-- (insert, update, delete), no se usa dentro de un select, puede devolver
-- varios resultados o ninguno y tiene parametros de tres tipos:
--   in     entrada (valor que recibe, es el tipo por defecto)
--   out    salida (valor que devuelve a quien lo llama)
--   inout  entrada y salida

-- 14.1 procedimiento simple con un parametro in: devuelve un resultado
create procedure sp_demo_entregas_cliente(in p_id_cliente int)
begin
    select codigo, fecha_programada, estado, distancia_km
    from entregas
    where id_cliente = p_id_cliente
    order by fecha_programada;
end;

call sp_demo_entregas_cliente(1);

-- 14.2 parametros out: el procedimiento deja valores en variables de
-- usuario (@nombre) que luego se consultan con select
create procedure sp_demo_totales_cliente(in p_id_cliente int, out p_entregas int, out p_km decimal(10,1))
begin
    select count(*), coalesce(sum(distancia_km), 0)
    into p_entregas, p_km
    from entregas
    where id_cliente = p_id_cliente;
end;

call sp_demo_totales_cliente(1, @entregas, @km);
select @entregas as entregas, @km as km;

-- 14.3 variables, if / elseif / else y inout
-- declare crea variables locales; set les asigna un valor.
-- inout: entra con un valor y sale modificado.
create procedure sp_demo_ajuste_tarifa(in p_tipo_cliente varchar(12), inout p_valor decimal(12,2))
begin
    -- ong: 10 % de descuento; persona: 5 % de recargo; los demas no cambian
    if p_tipo_cliente = 'ONG' then
        set p_valor = p_valor * 0.90;
    elseif p_tipo_cliente = 'PERSONA' then
        set p_valor = p_valor * 1.05;
    else
        set p_valor = p_valor;
    end if;
end;

set @valor = 100000;
call sp_demo_ajuste_tarifa('ONG', @valor);
select @valor as valor_ajustado;

-- 14.4 case dentro de un procedimiento
create procedure sp_demo_estado_dron(in p_id_dron int)
begin
    declare v_estado varchar(15);
    declare v_mensaje varchar(60);

    select estado into v_estado from drones where id_dron = p_id_dron;

    case v_estado
        when 'ACTIVO' then set v_mensaje = 'Puede recibir entregas';
        when 'MANTENIMIENTO' then set v_mensaje = 'En revision tecnica';
        when 'RETIRADO' then set v_mensaje = 'Fuera de servicio';
        else set v_mensaje = 'Dron no existe';
    end case;

    select p_id_dron as id_dron, v_estado as estado, v_mensaje as mensaje;
end;

call sp_demo_estado_dron(1);
call sp_demo_estado_dron(8);
call sp_demo_estado_dron(99);

-- 14.5 ciclo while: se repite mientras la condicion sea verdadera
-- (cuidado: si la condicion nunca se vuelve falsa, el ciclo no termina)
create table practica_ciclo (
    id int auto_increment primary key,
    numero int not null
);

create procedure sp_demo_llenar(in p_cantidad int)
begin
    declare v_i int default 1;

    while v_i <= p_cantidad do
        insert into practica_ciclo (numero) values (v_i * 10);
        set v_i = v_i + 1;
    end while;
end;

call sp_demo_llenar(5);
select * from practica_ciclo;

-- 14.6 validar y lanzar un error con signal
-- sqlstate '45000' es un error definido por el usuario; message_text es el
-- mensaje que ve quien llama. el procedimiento se detiene en ese punto.
create procedure sp_demo_validar_horas(in p_id_dron int, in p_horas decimal(7,1))
begin
    declare v_existe int;

    select count(*) into v_existe from drones where id_dron = p_id_dron;

    if v_existe = 0 then
        signal sqlstate '45000' set message_text = 'El dron no existe';
    end if;

    if p_horas < 0 then
        signal sqlstate '45000' set message_text = 'Las horas no pueden ser negativas';
    end if;

    update drones set horas_vuelo = horas_vuelo + p_horas where id_dron = p_id_dron;
    select codigo_serie, horas_vuelo from drones where id_dron = p_id_dron;
end;

start transaction;
call sp_demo_validar_horas(1, 5.5);
rollback;
-- estas dos llamadas dan error a proposito (si el cliente se detiene en
-- el primer error, ejecutarlas una por una):
call sp_demo_validar_horas(99, 5);
call sp_demo_validar_horas(1, -3);

-- 14.7 manejo de errores con handler y transaccion dentro del procedimiento
-- declare exit handler: si ocurre un error sql, ejecuta el bloque y sale.
-- aqui se deshace todo lo hecho si algo falla (todo o nada).
create procedure sp_demo_transferir_entrega(in p_id_entrega int, in p_id_piloto_nuevo int)
begin
    declare exit handler for sqlexception
    begin
        rollback;
        select 'Error: no se pudo reasignar la entrega, se deshicieron los cambios' as mensaje;
    end;

    start transaction;
    update entregas set id_piloto = p_id_piloto_nuevo where id_entrega = p_id_entrega;
    insert into historial_entregas (id_entrega, estado_anterior, estado_nuevo)
    select id_entrega, estado, estado from entregas where id_entrega = p_id_entrega;
    commit;
    select 'Entrega reasignada' as mensaje;
end;

-- piloto 99 no existe: la fk falla y el handler hace rollback
call sp_demo_transferir_entrega(19, 99);
-- piloto 3 si existe: se confirma
call sp_demo_transferir_entrega(19, 3);
-- se devuelve el dato original y se limpia lo que dejo la prueba
update entregas set id_piloto = 1 where id_entrega = 19;
delete from historial_entregas;


-- 14.9 parametros opcionales: si el parametro es null, no filtra
-- el truco es (p_parametro is null or columna = p_parametro)
create procedure sp_demo_listar_entregas(in p_estado varchar(12), in p_prioridad varchar(8))
begin
    select codigo, estado, prioridad, distancia_km
    from entregas
    where (p_estado is null or estado = p_estado)
    and (p_prioridad is null or prioridad = p_prioridad)
    order by codigo;
end;

call sp_demo_listar_entregas('ENTREGADA', 'URGENTE');
call sp_demo_listar_entregas(null, 'VITAL');
call sp_demo_listar_entregas('PROGRAMADA', null);

-- 14.10 insert dentro de un procedimiento, con parametro out y update condicionado
-- registra un mantenimiento; si es correctivo, ademas pone el dron en MANTENIMIENTO.
-- last_insert_id() devuelve el id que genero el ultimo insert.
create procedure sp_demo_registrar_mantenimiento(
    in p_id_dron int,
    in p_tipo varchar(12),
    in p_descripcion varchar(200),
    in p_costo decimal(10,2),
    out p_id_mantenimiento int
)
begin
    insert into mantenimientos (id_dron, fecha, tipo, descripcion, costo)
    values (p_id_dron, curdate(), p_tipo, p_descripcion, p_costo);

    set p_id_mantenimiento = last_insert_id();

    if p_tipo = 'CORRECTIVO' then
        update drones set estado = 'MANTENIMIENTO' where id_dron = p_id_dron and estado = 'ACTIVO';
    end if;
end;

start transaction;
call sp_demo_registrar_mantenimiento(3, 'CORRECTIVO', 'Cambio de helice trasera', 380000, @nuevo_id);
select @nuevo_id as id_mantenimiento_creado;
select id_dron, codigo_serie, estado from drones where id_dron = 3;
rollback;

-- 14.11 update con validacion del estado actual
-- solo se puede cancelar una entrega que este PROGRAMADA
create procedure sp_demo_cancelar_entrega(in p_codigo varchar(10))
begin
    declare v_estado varchar(12);

    select estado into v_estado from entregas where codigo = p_codigo;

    if v_estado is null then
        signal sqlstate '45000' set message_text = 'La entrega no existe';
    elseif v_estado <> 'PROGRAMADA' then
        signal sqlstate '45000' set message_text = 'Solo se puede cancelar una entrega PROGRAMADA';
    end if;

    update entregas set estado = 'CANCELADA' where codigo = p_codigo;
    select codigo, estado from entregas where codigo = p_codigo;
end;

start transaction;
call sp_demo_cancelar_entrega('ENT-0019');
rollback;
-- estas dan error a proposito (ejecutarlas una por una):
call sp_demo_cancelar_entrega('ENT-0001');
call sp_demo_cancelar_entrega('ENT-9999');

-- 14.12 delete con validacion: no se borra un cliente que tenga entregas
create procedure sp_demo_borrar_cliente(in p_id_cliente int)
begin
    declare v_entregas int;

    select count(*) into v_entregas from entregas where id_cliente = p_id_cliente;

    if v_entregas > 0 then
        signal sqlstate '45000' set message_text = 'El cliente tiene entregas, no se puede borrar';
    end if;

    delete from clientes where id_cliente = p_id_cliente;
    select row_count() as clientes_borrados;
end;

start transaction;
call sp_demo_borrar_cliente(9);
rollback;
-- error a proposito: el cliente 1 tiene entregas
call sp_demo_borrar_cliente(1);

-- 14.13 ciclos: loop con leave / iterate y repeat ... until
-- leave sale del ciclo; iterate salta a la siguiente vuelta.
create procedure sp_demo_ciclos(in p_n int)
begin
    declare v_i int default 0;
    declare v_pares varchar(100) default '';
    declare v_suma int default 0;

    -- loop: se repite hasta que se ejecute leave
    ciclo_pares: loop
        set v_i = v_i + 1;
        if v_i > p_n then
            leave ciclo_pares;
        end if;
        if v_i mod 2 = 1 then
            iterate ciclo_pares;
        end if;
        set v_pares = concat(v_pares, v_i, ' ');
    end loop;

    -- repeat: ejecuta primero y revisa la condicion al final (siempre da al menos una vuelta)
    set v_i = 0;
    repeat
        set v_i = v_i + 1;
        set v_suma = v_suma + v_i;
    until v_i >= p_n end repeat;

    select p_n as n, v_pares as numeros_pares, v_suma as suma_1_a_n;
end;

call sp_demo_ciclos(10);

-- 14.14 un procedimiento que llama a otro
-- las variables locales sirven para recibir los parametros out
create procedure sp_demo_reporte_cliente(in p_id_cliente int)
begin
    declare v_entregas int;
    declare v_km decimal(10,1);
    declare v_nombre varchar(120);

    select nombre into v_nombre from clientes where id_cliente = p_id_cliente;
    call sp_demo_totales_cliente(p_id_cliente, v_entregas, v_km);

    select v_nombre as cliente, v_entregas as entregas, v_km as km_totales;
end;

call sp_demo_reporte_cliente(3);

-- 14.15 un procedimiento que devuelve varios resultados (varios select)
create procedure sp_demo_ficha_dron(in p_id_dron int)
begin
    select codigo_serie, modelo, estado, horas_vuelo from drones where id_dron = p_id_dron;
    select fecha, tipo, costo from mantenimientos where id_dron = p_id_dron order by fecha;
    select codigo, estado, distancia_km from entregas where id_dron = p_id_dron order by fecha_programada;
end;

call sp_demo_ficha_dron(2);

-- 14.16 procedimiento completo: validar, insertar la entrega y su carga, todo o nada
-- usa handler + transaccion: si cualquier insert falla, se deshace todo.
create procedure sp_demo_nueva_entrega_con_carga(
    in p_codigo varchar(10),
    in p_id_cliente int,
    in p_id_dron int,
    in p_id_piloto int,
    in p_fecha datetime,
    in p_municipio varchar(60),
    in p_km decimal(5,1),
    in p_id_tipo int,
    in p_peso decimal(6,2)
)
begin
    declare v_estado varchar(15);
    declare v_id_entrega int;

    declare exit handler for sqlexception
    begin
        rollback;
        select 'Error: no se registro la entrega ni su carga' as mensaje;
    end;

    select estado into v_estado from drones where id_dron = p_id_dron;
    if v_estado is null or v_estado <> 'ACTIVO' then
        signal sqlstate '45000' set message_text = 'El dron no existe o no esta ACTIVO';
    end if;

    start transaction;
    insert into entregas (codigo, id_cliente, id_dron, id_piloto, fecha_programada, municipio_destino, distancia_km)
    values (p_codigo, p_id_cliente, p_id_dron, p_id_piloto, p_fecha, p_municipio, p_km);

    set v_id_entrega = last_insert_id();

    insert into carga_entrega (id_entrega, id_tipo, peso_kg) values (v_id_entrega, p_id_tipo, p_peso);
    commit;

    select concat('Entrega ', p_codigo, ' registrada con id ', v_id_entrega) as mensaje;
end;

-- caso valido
call sp_demo_nueva_entrega_con_carga('ENT-0030', 1, 1, 1, '2026-10-10 08:00:00', 'Guarne', 12.0, 3, 2.50);
select e.codigo, ce.id_tipo, ce.peso_kg from entregas e inner join carga_entrega ce on ce.id_entrega = e.id_entrega where e.codigo = 'ENT-0030';
-- caso con error (el tipo de carga 99 no existe: el segundo insert falla y se deshace tambien la entrega)
call sp_demo_nueva_entrega_con_carga('ENT-0031', 1, 1, 1, '2026-10-11 08:00:00', 'Guarne', 12.0, 99, 2.50);
select count(*) as entregas_ent_0031 from entregas where codigo = 'ENT-0031';
-- se limpia lo que dejo la prueba
delete from carga_entrega where id_entrega in (select id_entrega from entregas where codigo = 'ENT-0030');
delete from entregas where codigo = 'ENT-0030';


-- 14.17 ver y borrar procedimientos
show procedure status where db = 'dronandes';
drop procedure if exists sp_demo_entregas_cliente;
drop procedure if exists sp_demo_totales_cliente;
drop procedure if exists sp_demo_ajuste_tarifa;
drop procedure if exists sp_demo_estado_dron;
drop procedure if exists sp_demo_llenar;
drop procedure if exists sp_demo_validar_horas;
drop procedure if exists sp_demo_transferir_entrega;
drop procedure if exists sp_demo_listar_entregas;
drop procedure if exists sp_demo_registrar_mantenimiento;
drop procedure if exists sp_demo_cancelar_entrega;
drop procedure if exists sp_demo_borrar_cliente;
drop procedure if exists sp_demo_ciclos;
drop procedure if exists sp_demo_reporte_cliente;
drop procedure if exists sp_demo_ficha_dron;
drop procedure if exists sp_demo_nueva_entrega_con_carga;
drop table if exists practica_ciclo;


-- =====================================================================
-- 15. triggers
-- =====================================================================
-- un trigger es codigo que mysql ejecuta AUTOMATICAMENTE cuando ocurre un
-- insert, update o delete sobre una tabla. no se llama con call.
--   momento:  before (antes de guardar, puede modificar la fila nueva)
--             after  (despues de guardar, sirve para registrar o auditar)
--   evento:   insert, update, delete
--   new.columna = valor nuevo (en insert y update)
--   old.columna = valor anterior (en update y delete)
--   solo se puede modificar new.columna en un trigger before.
-- sintaxis:
--   create trigger nombre
--   before|after insert|update|delete on tabla
--   for each row
--   begin
--       ...
--   end;
-- para los ejemplos se usan dos tablas de prueba.

create table prueba (
    id int auto_increment primary key,
    nombre varchar(50) not null,
    precio decimal(10,2) not null,
    stock int not null default 0
);

create table prueba_log (
    id int auto_increment primary key,
    accion varchar(10) not null,
    detalle varchar(200),
    fecha datetime not null default current_timestamp
);

-- 15.1 before insert: modifica o valida los datos antes de guardarlos
create trigger trg_prueba_bi
before insert on prueba
for each row
begin
    -- normaliza el nombre a mayusculas
    set new.nombre = upper(new.nombre);

    -- rechaza precios negativos
    if new.precio < 0 then
        signal sqlstate '45000' set message_text = 'El precio no puede ser negativo';
    end if;
end;

-- 15.2 after insert: registra lo que se inserto
create trigger trg_prueba_ai
after insert on prueba
for each row
begin
    insert into prueba_log (accion, detalle)
    values ('INSERT', concat('nuevo producto: ', new.nombre, ' con precio ', new.precio));
end;

-- 15.3 before update: compara old y new
create trigger trg_prueba_bu
before update on prueba
for each row
begin
    if new.stock < 0 then
        signal sqlstate '45000' set message_text = 'El stock no puede quedar negativo';
    end if;
end;

-- 15.4 after update: registra el cambio solo si cambio el precio
create trigger trg_prueba_au
after update on prueba
for each row
begin
    if new.precio <> old.precio then
        insert into prueba_log (accion, detalle)
        values ('UPDATE', concat(old.nombre, ': precio de ', old.precio, ' a ', new.precio));
    end if;
end;

-- 15.5 before delete: impide borrar si hay stock
create trigger trg_prueba_bd
before delete on prueba
for each row
begin
    if old.stock > 0 then
        signal sqlstate '45000' set message_text = 'No se puede borrar un producto con stock';
    end if;
end;

-- 15.6 after delete: registra lo borrado
create trigger trg_prueba_ad
after delete on prueba
for each row
begin
    insert into prueba_log (accion, detalle) values ('DELETE', concat('producto borrado: ', old.nombre));
end;

-- demostracion
insert into prueba (nombre, precio, stock) values ('tornillo', 500, 100);
insert into prueba (nombre, precio, stock) values ('tuerca', 300, 0);
update prueba set precio = 650 where nombre = 'TORNILLO';
update prueba set stock = stock - 10 where nombre = 'TORNILLO';
delete from prueba where nombre = 'TUERCA';

select * from prueba;
select id, accion, detalle from prueba_log order by id;

-- estas sentencias dan error a proposito por los triggers (ejecutarlas
-- una por una si el cliente se detiene en el primer error):
insert into prueba (nombre, precio, stock) values ('clavo', -5, 10);
update prueba set stock = -1 where nombre = 'TORNILLO';
delete from prueba where nombre = 'TORNILLO';


-- 15.7 resumen: que se puede usar en cada trigger
--   evento    new                  old
--   insert    si (valores nuevos)  no existe
--   update    si (valores nuevos)  si (valores anteriores)
--   delete    no existe            si (valores borrados)
-- before: se puede cambiar new.columna (set new.columna = ...) y rechazar con signal.
-- after: la fila ya se guardo; sirve para registrar en otra tabla o actualizar totales.
-- si un trigger lanza un error con signal, la sentencia que lo activo se cancela.
-- los siguientes ejemplos usan las tablas reales del caso. al final se borran los triggers.

-- 15.8 before insert sobre entregas: validar y normalizar antes de guardar
-- consulta otras tablas (drones) con select ... into
create trigger trg_demo_entregas_bi
before insert on entregas
for each row
begin
    declare v_autonomia decimal(5,1);
    declare v_estado varchar(15);

    select autonomia_km, estado into v_autonomia, v_estado
    from drones
    where id_dron = new.id_dron;

    if v_estado <> 'ACTIVO' then
        signal sqlstate '45000' set message_text = 'El dron no esta ACTIVO';
    end if;

    if new.distancia_km > v_autonomia then
        signal sqlstate '45000' set message_text = 'La distancia supera la autonomia del dron';
    end if;

    -- normaliza el codigo a mayusculas
    set new.codigo = upper(new.codigo);
end;

-- 15.9 before update sobre entregas: controlar el ciclo de estados (rn-09)
-- PROGRAMADA -> EN_VUELO o CANCELADA; EN_VUELO -> ENTREGADA o FALLIDA;
-- las entregas cerradas no cambian de estado.
create trigger trg_demo_entregas_bu
before update on entregas
for each row
begin
    if new.estado <> old.estado then
        if old.estado in ('ENTREGADA', 'CANCELADA', 'FALLIDA') then
            signal sqlstate '45000' set message_text = 'Una entrega cerrada no puede cambiar de estado';
        elseif old.estado = 'PROGRAMADA' and new.estado not in ('EN_VUELO', 'CANCELADA') then
            signal sqlstate '45000' set message_text = 'Desde PROGRAMADA solo se pasa a EN_VUELO o CANCELADA';
        elseif old.estado = 'EN_VUELO' and new.estado not in ('ENTREGADA', 'FALLIDA') then
            signal sqlstate '45000' set message_text = 'Desde EN_VUELO solo se pasa a ENTREGADA o FALLIDA';
        end if;
    end if;
end;

-- 15.10 before delete sobre entregas: no se borra lo que ya se entrego (trazabilidad)
create trigger trg_demo_entregas_bd
before delete on entregas
for each row
begin
    if old.estado = 'ENTREGADA' then
        signal sqlstate '45000' set message_text = 'No se puede borrar una entrega ENTREGADA';
    end if;
end;

-- pruebas de los tres triggers anteriores (dentro de una transaccion)
start transaction;

-- valida: se guarda y el codigo queda en mayusculas
insert into entregas (codigo, id_cliente, id_dron, id_piloto, fecha_programada, municipio_destino, distancia_km)
values ('ent-0040', 1, 1, 1, '2026-10-05 08:00:00', 'Guarne', 10.0);
select codigo, estado from entregas where id_dron = 1 and fecha_programada = '2026-10-05 08:00:00';

-- cambios de estado permitidos
update entregas set estado = 'EN_VUELO' where codigo = 'ENT-0019';
update entregas set estado = 'ENTREGADA' where codigo = 'ENT-0019';
select codigo, estado from entregas where codigo = 'ENT-0019';

-- borrado permitido: la entrega 5 esta CANCELADA y tiene carga; primero se borra la carga
delete from carga_entrega where id_entrega = 5;
delete from entregas where codigo = 'ENT-0005';
select count(*) as quedan_ent_0005 from entregas where codigo = 'ENT-0005';
rollback;

-- estas sentencias dan error a proposito (ejecutarlas una por una):
-- distancia mayor que la autonomia del dron 1 (45 km)
insert into entregas (codigo, id_cliente, id_dron, id_piloto, fecha_programada, municipio_destino, distancia_km)
values ('ENT-0041', 1, 1, 1, '2026-10-06 08:00:00', 'Nariño', 100.0);
-- dron 8 esta RETIRADO
insert into entregas (codigo, id_cliente, id_dron, id_piloto, fecha_programada, municipio_destino, distancia_km)
values ('ENT-0042', 1, 8, 1, '2026-10-06 09:00:00', 'Nariño', 10.0);
-- PROGRAMADA no puede pasar directo a ENTREGADA
update entregas set estado = 'ENTREGADA' where codigo = 'ENT-0020';
-- una entrega cerrada no cambia de estado
update entregas set estado = 'PROGRAMADA' where codigo = 'ENT-0001';
-- no se borra una entrega ENTREGADA
delete from entregas where codigo = 'ENT-0001';

-- 15.11 after update sobre drones: bitacora de cambios de estado
create table bitacora_demo (
    id int auto_increment primary key,
    tabla varchar(30) not null,
    detalle varchar(200) not null,
    fecha datetime not null default current_timestamp
);

create trigger trg_demo_drones_au
after update on drones
for each row
begin
    if new.estado <> old.estado then
        insert into bitacora_demo (tabla, detalle)
        values ('drones', concat(old.codigo_serie, ': ', old.estado, ' -> ', new.estado));
    end if;
end;

start transaction;
update drones set estado = 'MANTENIMIENTO' where id_dron = 1;
update drones set horas_vuelo = horas_vuelo + 5 where id_dron = 2;
update drones set estado = 'RETIRADO' where id_dron = 5;
select id, tabla, detalle from bitacora_demo order by id;
rollback;

-- 15.12 mantener un total actualizado con triggers after insert / update / delete
-- tabla resumen: peso total por entrega, que se actualiza sola cuando cambia carga_entrega
create table peso_entrega_demo as
select e.id_entrega, coalesce(sum(ce.peso_kg), 0) as peso_total
from entregas e
left join carga_entrega ce on ce.id_entrega = e.id_entrega
group by e.id_entrega;

create trigger trg_demo_carga_ai
after insert on carga_entrega
for each row
begin
    update peso_entrega_demo set peso_total = peso_total + new.peso_kg where id_entrega = new.id_entrega;
end;

create trigger trg_demo_carga_au
after update on carga_entrega
for each row
begin
    update peso_entrega_demo set peso_total = peso_total - old.peso_kg + new.peso_kg where id_entrega = new.id_entrega;
end;

create trigger trg_demo_carga_ad
after delete on carga_entrega
for each row
begin
    update peso_entrega_demo set peso_total = peso_total - old.peso_kg where id_entrega = old.id_entrega;
end;

start transaction;
select * from peso_entrega_demo where id_entrega = 12;
insert into carga_entrega (id_entrega, id_tipo, peso_kg, unidades) values (12, 3, 2.00, 10);
select * from peso_entrega_demo where id_entrega = 12;
update carga_entrega set peso_kg = 5.00 where id_entrega = 12 and id_tipo = 3;
select * from peso_entrega_demo where id_entrega = 12;
delete from carga_entrega where id_entrega = 12 and id_tipo = 3;
select * from peso_entrega_demo where id_entrega = 12;
rollback;

-- se borran los triggers y tablas de estos ejemplos
drop trigger if exists trg_demo_entregas_bi;
drop trigger if exists trg_demo_entregas_bu;
drop trigger if exists trg_demo_entregas_bd;
drop trigger if exists trg_demo_drones_au;
drop trigger if exists trg_demo_carga_ai;
drop trigger if exists trg_demo_carga_au;
drop trigger if exists trg_demo_carga_ad;
drop table if exists bitacora_demo;
drop table if exists peso_entrega_demo;


-- ver y borrar triggers
show triggers;
drop trigger if exists trg_prueba_bi;
drop trigger if exists trg_prueba_ai;
drop trigger if exists trg_prueba_bu;
drop trigger if exists trg_prueba_au;
drop trigger if exists trg_prueba_bd;
drop trigger if exists trg_prueba_ad;
drop table if exists prueba_log;
drop table if exists prueba;


-- =====================================================================
-- 16. transacciones
-- =====================================================================
-- una transaccion agrupa varias sentencias: o se aplican todas (commit)
-- o no se aplica ninguna (rollback). evita dejar datos a medias si algo
-- falla (por ejemplo, un descuento sin su abono).
--   start transaction   inicia
--   commit              confirma los cambios
--   rollback            deshace todo lo hecho desde start transaction
--   savepoint nombre / rollback to nombre   punto intermedio al que se puede volver
-- por defecto mysql tiene autocommit: cada sentencia se confirma sola.
-- los create, alter y drop confirman la transaccion de forma implicita.

-- 16.1 rollback: se deshace
start transaction;
update drones set horas_vuelo = 0;
select codigo_serie, horas_vuelo from drones;
rollback;
select codigo_serie, horas_vuelo from drones;

-- 16.2 commit: se confirma (aqui se deja el dato como estaba)
start transaction;
update drones set horas_vuelo = horas_vuelo + 1 where id_dron = 1;
commit;
update drones set horas_vuelo = horas_vuelo - 1 where id_dron = 1;

-- 16.3 savepoint: volver a un punto intermedio
start transaction;
update drones set estado = 'MANTENIMIENTO' where id_dron = 1;
savepoint despues_dron_1;
update drones set estado = 'MANTENIMIENTO' where id_dron = 2;
rollback to despues_dron_1;
select id_dron, estado from drones where id_dron in (1, 2);
rollback;


-- =====================================================================
-- 17. diferencias mysql / postgresql
-- =====================================================================
--   tema                   mysql                          postgresql
--   autoincremento         auto_increment                 generated by default as identity (o serial)
--   fecha y hora           datetime                       timestamp
--   usar la base           use dronandes;                 \c dronandes
--   ver tablas             show tables;                   \dt
--   ver estructura         describe tabla;                \d tabla
--   ver indices            show index from tabla;         select * from pg_indexes where tablename = 'tabla';
--   default de una fecha   default (current_date)         default current_date
--   cambiar tipo columna   modify column c tipo           alter column c type tipo
--   borrar indice          drop index idx on tabla        drop index idx
--   borrar check           drop constraint (o drop check) drop constraint
--   minutos entre fechas   timestampdiff(minute, a, b)    extract(epoch from (b - a)) / 60
--   concat con null        devuelve null                  ignora el null (usar || para obtener null)
--   like                   no distingue mayusculas        distingue mayusculas (ilike no)
--   alias en having        permitido                      no permitido (repetir la expresion)
--   ifnull, if(), limit n  existen                        usar coalesce, case, limit n
--   funcion                create function ... begin end  create function ... $$ ... $$ language plpgsql
--   procedimiento          create procedure ... call      create procedure ... language plpgsql; call
--   error personalizado    signal sqlstate '45000'        raise exception 'mensaje'
--   trigger                el codigo va dentro del        funcion que returns trigger + create trigger
--                          create trigger                 ... execute function nombre()
--   variable               declare v int; set v = 1;      declare (en la seccion antes de begin); v := 1;
--   resultado de un proc.  select ...                     raise notice '...' (mensajes) o funciones que devuelven tabla
