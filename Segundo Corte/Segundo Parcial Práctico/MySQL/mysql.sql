-- Segundo Parcial práctico - Ingenieria de Datos
-- Motor:  MySQL 8.0 
-- Realizado por : Jessica Alejandra Gil Tellez

-- R1 y R2. Modelo relacional(modelo físico) y creación de la base de datos

-- R2 DDL

drop database if exists cicloverde;
create database cicloverde;
use cicloverde;

create table estaciones(
id_estacion int not null auto_increment primary key,
nombre varchar(50) not null unique,
barrio varchar(50) not null,
capacidad int not null,
activa boolean not null default true,
constraint chk_capacidad
	check (capacidad>0)
);

create table bicicletas(
id_bici int not null auto_increment primary key,
codigo varchar(10) not null unique,
modelo varchar(40) not null,
estado varchar(10) not null default('ACTIVA'),
km_recorridos decimal(7,1) not null default 0,
id_estacion int not null,
constraint chk_estado
	check(estado in ('ACTIVA', 'TALLER', 'BAJA')),
constraint chk_kmrecorrido
	check(km_recorridos>0),
constraint fk_idestacion
	foreign key (id_estacion)
	references estaciones(id_estacion)
	);

create table usuarios(
id_usuario int not null auto_increment primary key,
documento varchar(15) not null unique,
nombres varchar(50) not null,
apellidos varchar(50) not null,
email varchar(80) null unique,
telefono varchar(15) null,
plan varchar(10) not null default('BASICO'),
fecha_registro date not null,
id_referidor int null,
constraint chk_plan 
	check(plan in ('BASICO', 'PREMIUM'))
);

create table accesorios(
id_accesorio int not null auto_increment primary key,
nombre varchar(40) not null unique,
precio decimal(8,2) not null
);

create table viajes(
id_viaje int not null auto_increment primary key,
id_usuario int not null,
id_bici int not null,
id_estacion_origen int not null,
id_estacion_destino int null,
fecha_inicio datetime not null,
fecha_fin datetime null,
km decimal(5,1) not null default 0,
estado varchar(12) not null default ('EN_CURSO'),
calificacion smallint null,
constraint fk_idusuario
	foreign key(id_usuario)
	references usuarios(id_usuario),
constraint fk_idbici
	foreign key(id_bici)
	references bicicletas(id_bici),
constraint fk_idestacionOrigen
	foreign key(id_estacion_origen)
	references estaciones(id_estacion),
constraint fk_idestacionDestino
	foreign key(id_estacion_destino)
	references estaciones(id_estacion),
constraint chk_km
	check (km>=0),
constraint chk_estado
	check(estado in ('EN_CURSO', 'FINALIZADO', 'CANCELADO')),
constraint chk_calificacion
	check (calificacion between 1 and 5)
);

create table viaje_accesorio(
-- Agrego un id de viaje accesorio
-- -- Tabla intermedia - Un viaje puede llevar varios accesorios y un accesorio aparece en muchos viajes. Por
-- cada combinación se registra la cantidad; un accesorio no se repite en el mism
id_viaje_accesorio int not null auto_increment primary key,
id_viaje int not null,
id_accesorio int not null,
cantidad int not null default 1,
constraint fk_idviaje
	foreign key(id_viaje)
	references viajes(id_viaje),
constraint fk_idaccesorio
	foreign key(id_accesorio)
	references accesorios(id_accesorio),
constraint chk_cantidad
	check(cantidad>0)
);
	
create table historial_bicicletas(
id_historial  int not null auto_increment primary key,
id_bici int not null,
estado_anterior varchar(10) not null,
estado_nuevo varchar(10) not null,
fecha_cambio datetime not null default current_timestamp,
constraint fk_idbicihist
	foreign key(id_bici)
	references bicicletas(id_bici)
);


-- Nota: Exporto el modelo fisico de la base de datos creada

-- =====================================================================
-- DATOS INICIALES — Operación Pedal (CicloVerde S.A.S.)
-- Ejecutar inmediatamente después del DDL de R2.
-- =====================================================================
INSERT INTO estaciones (id_estacion, nombre, barrio, capacidad, activa) VALUES
(1, 'Estación Las Aguas', 'La Candelaria', 12, TRUE),
(2, 'Estación Parque 93', 'Chapinero', 15, TRUE),
(3, 'Estación Usaquén', 'Usaquén', 10, TRUE),
(4, 'Estación Kennedy', 'Kennedy', 8, FALSE);
INSERT INTO bicicletas (id_bici, codigo, modelo, estado, km_recorridos, id_estacion)
VALUES
(1, 'CV-E01', 'Volta E2', 'ACTIVA', 1350.5, 1),
(2, 'CV-E02', 'Volta E2', 'ACTIVA', 820.0, 1),
(3, 'CV-M01', 'Urbana M1', 'ACTIVA', 240.0, 1),
(4, 'CV-E03', 'Volta E3', 'ACTIVA', 1620.0, 2),
(5, 'CV-M02', 'Urbana M1', 'TALLER', 95.5, 2),
(6, 'CV-E04', 'Volta E3', 'ACTIVA', 410.0, 3),
(7, 'CV-M03', 'Urbana M2', 'BAJA', 2100.0, 3),
(8, 'CV-E-PRO', 'Prototipo Volta X', 'ACTIVA', 60.0, 3);
-- Los usuarios que refieren se insertan antes que sus referidos.
INSERT INTO usuarios (id_usuario, documento, nombres, apellidos, email, telefono,
plan, fecha_registro, id_referidor) VALUES
(1, '1036101001', 'Valentina', 'Ríos Mejía', 'vale.rios@gmail.com',
'3001234567', 'PREMIUM', '2025-11-03', NULL),
(2, '1036101002', 'Santiago', 'Gómez Ruiz', 'sgomez@urosario.edu.co',
'3012223344', 'BASICO', '2026-01-15', 1),
(3, '1036101003', 'Isabella', 'Torres Cano', 'isa.torres@hotmail.com', NULL,
'PREMIUM', '2026-02-20', 1),
(4, '1036101004', 'Mateo', 'Herrera Díaz', NULL,
'312456789', 'BASICO', '2026-03-31', 2),
(5, '1036101005', 'Camila', 'Ortiz León', 'camila.ortiz@urosario.edu.co',
'3157654321', 'BASICO', '2026-05-10', NULL),
(6, '1036101006', 'Sebastián', 'Vargas Pino', 'sebas.vargas@gmail.com',
'3209876543', 'PREMIUM', '2026-07-01', 3),
(7, '1036101007', 'Daniela', 'Cruz Mora', 'DCRUZ@UROSARIO.EDU.CO',
'3104445566', 'BASICO', '2026-09-12', NULL),
(8, '1036101008', 'Andrés', 'Patiño Gil', NULL, NULL,
'BASICO', '2026-10-01', 5);
INSERT INTO accesorios (id_accesorio, nombre, precio) VALUES
(1, 'Casco', 2500),
(2, 'Candado', 1500),
(3, 'Canasta', 1000),
(4, 'Luz recargable', 2000);
INSERT INTO viajes (id_viaje, id_usuario, id_bici, id_estacion_origen,
id_estacion_destino, fecha_inicio, fecha_fin, km, estado, calificacion) VALUES
(1, 1, 1, 1, 2, '2026-10-01 07:10:00', '2026-10-01 07:32:00', 5.2, 'FINALIZADO',
5),
(2, 2, 3, 1, 3, '2026-10-01 08:00:00', '2026-10-01 08:25:00', 3.8, 'FINALIZADO',
4),
(3, 3, 4, 2, 1, '2026-10-02 18:05:00', '2026-10-02 18:40:00', 6.0, 'FINALIZADO',
2),
(4, 1, 2, 1, 1, '2026-10-03 12:00:00', '2026-10-03 12:15:00', 2.1, 'FINALIZADO',
NULL),
(5, 3, 6, 3, 2, '2026-10-04 09:30:00', '2026-10-04 09:58:00', 4.4, 'FINALIZADO',
3),
(6, 5, 1, 2, NULL, '2026-10-05 10:00:00', NULL, 0.0, 'CANCELADO',
NULL),
(7, 6, 4, 2, 3, '2026-10-06 17:20:00', '2026-10-06 18:05:00', 11.0, 'FINALIZADO',
5),
(8, 2, 2, 1, 2, '2026-10-08 07:45:00', '2026-10-08 08:05:00', 4.9, 'FINALIZADO',
1),
(9, 3, 6, 3, NULL, '2026-10-09 14:00:00', NULL, 0.8, 'CANCELADO',
NULL),
(10, 1, 6, 3, 1, '2026-10-11 06:50:00', '2026-10-11 07:20:00', 6.0, 'FINALIZADO',
4),
(11, 5, 3, 1, 3, '2026-10-12 16:00:00', '2026-10-12 16:18:00', 2.7, 'FINALIZADO',
5),
(12, 6, 8, 3, NULL, '2026-10-14 11:00:00', NULL, 0.0, 'CANCELADO',
NULL),
(13, 4, 2, 1, NULL, '2026-10-15 19:30:00', NULL, 1.2, 'EN_CURSO',
NULL),
(14, 2, 6, 3, NULL, '2026-10-15 19:45:00', NULL, 0.0, 'EN_CURSO',
NULL);
INSERT INTO viaje_accesorio (id_viaje, id_accesorio, cantidad) VALUES
(1, 1, 1), (1, 2, 1),
(3, 1, 1),
(5, 3, 1),
(7, 1, 1), (7, 3, 1),
(8, 2, 1),
(10, 1, 1),
(11, 2, 1),
(13, 1, 1);

-- Evidencia 1
show tables;

-- R3  AlTER TABLE
-- a)
alter table usuarios add constraint fk_usuarios_referidor foreign key (id_referidor) references usuarios (id_usuario);

-- b) 
alter table viajes add constraint chk_viajes_fechas check (fecha_fin is null or fecha_fin>fecha_inicio);

-- R4.a R4.b R4.c R4.d
insert into usuarios (documento, nombres, apellidos, email, telefono, plan, fecha_registro, id_referidor) values
(1036101009, 'Lucía', 'Arango Vélez', 'lucia.arango@gmail.com','3165551234', 'PREMIUM', '2026-10-14', 2),
(1036101010, 'Juan Pablo', 'Restrepo Sierra', 'jp.restrepo@unal.edu.co','3001112222', 'BASICO', '2026-10-15', null);

update bicicletas  set estado ='TALLER' where km_recorridos>1500 and estado='ACTIVA';

delete from viajes where estado = 'CANCELADO' and km=0;

select
    (select count(*) from usuarios) as total_usuarios,
    (select count(*) from viajes) as total_viajes,
    (select count(*) from bicicletas where estado = 'TALLER') as bicicletas_taller;

-- RN
-- R5.a R5.b R5.c R5.d
select id_viaje, id_estacion_origen, km, calificacion from viajes
where (estado='FINALIZADO')  and (km between 2 and 6)

-- R6.a R6.b R6.c
-- R7.a R7.b
-- R8.a R8.b R8.c R8.d
-- R9.a R9.b R9.c R9.d
-- R10.a VISTA R10.b ÍNDICES
-- R11 FUNCIÓN (+ pruebas)
-- R12 TRIGGER (+ pruebas)
-- R13 PROCEDIMIENTO (+ pruebas)













