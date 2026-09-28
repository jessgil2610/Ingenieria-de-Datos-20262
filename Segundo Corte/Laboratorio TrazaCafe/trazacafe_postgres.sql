-- ================================================================
-- TrazaCafe - Laboratorio Ingeniería de Datos
-- Elaborado por: Jessica Alejandra Gil Tellez
-- ================================================================

-- RETO 1: El plano de la finca
-- Se encuentra en el archivo de word "Laboratorio TrazaCafe"


-- RETO 2: Los cimientos ==========================================

create database trazacafe
    with encoding = 'UTF8'
    template = template0;

create table finca(
    idFinca serial primary key,
    nombreFinca varchar(50) not null,
    nombreCafiFinca varchar(50) not null,
    cedulaCafiFinca varchar(15) not null,
    codMpioFinca integer not null,
    codDeptoFinca integer not null,
    altitudFinca real not null
);

create table lote(
    codLote varchar(20) primary key,
    variedadLote varchar(20) not null,
    procesoLote varchar(20) not null,
    fechaCosechaLote date not null,
    kilosLote numeric(7,2) not null,
    idFinca integer not null,
    constraint fklotefinca
        foreign key (idFinca)
        references finca(idFinca)
);

create table catacion(
    idCatacion serial primary key,
    nombreCatador varchar(50) not null,
    codLote varchar(20) not null,
    puntajeScaCatador numeric(5,2) not null,
    constraint fkcatacionlote
        foreign key (codLote)
        references lote(codLote)
);

create table tostion(
    idTostion serial primary key,
    codLote varchar(20) not null,
    fechaTostion date not null,
    kilosEntradaTostion numeric(7,2) not null,
    kilosSalidaTostion numeric(7,2) not null,
    perfilTostion varchar(20) not null,
    constraint fktostionlote
        foreign key (codLote)
        references lote(codLote)
);

create table cliente(
    idCliente serial primary key,
    nombreCliente varchar(50) not null,
    cedulaCliente varchar(15) not null,
    celularCliente varchar(10),
    correoCliente varchar(50)
);


create table pedido(
    idPedido serial primary key,
    idCliente integer not null,
    fechaPedido date not null,
    estadoPedido varchar(20) not null,
    constraint fkpedidocliente
        foreign key (idCliente)
        references cliente(idCliente)
);

create table detallepedido(
    idDetallePedido serial primary key,
    idPedido integer not null,
    idTostion integer not null,
    kilosPedido numeric(7,2) not null,
    precioPedido numeric(10,2) not null,
    constraint fkdetallepedidopedido
        foreign key (idPedido)
        references pedido(idPedido),
    constraint fkdetallepedidotostion
        foreign key (idTostion)
        references tostion(idTostion)
);


/*
 * Reflexión: ¿qué pasaría si intentas crear primero la tabla de lotes y después la de fincas? ¿Por qué?
 * Si se crea primero la tabla lote, se produciria un error ya que la llave foranea idFinca
 * necesita referenciar la columna idFinca de la tabla finca, y esa tabla todavía no existe.
 * Este error es el que arroja si primero se intenta crear la tabla lote: 
 * SQL Error [42P01]: ERROR: relation "finca" does not exist
*/


-- RETO 3: Los guardianes de la calidad ===============================================================


-- 1) Restricciones 
alter table finca
    add constraint chk_finca_altitud check (altitudFinca between 800 and 2500);

alter table catacion
    add constraint chk_catacion_puntaje check (puntajeScaCatador between 0 and 100);

alter table tostion
    add constraint chk_tostion_kilos check (kilosSalidaTostion <= kilosEntradaTostion);

-- El código de lote único ya queda garantizado porque codLote es la PRIMARY KEY de lote:
-- ninguna PK admite valores repetidos, así que no hace falta un UNIQUE aparte.

-- Valor por defecto del estado del pedido
alter table pedido
    alter column estadoPedido set default 'pendiente';

-- 2) ON DELETE de cada llave foránea (se decide aquí y se documenta el motivo)
-- finca -> lote: RESTRICT. Si una finca tiene lotes registrados no se puede borrar
--   directamente
alter table lote drop constraint fklotefinca;
alter table lote
    add constraint fklotefinca
    foreign key (idFinca) references finca(idFinca)
    on delete restrict;

-- lote -> catacion: RESTRICT. No queremos perder el historial de catas de un lote
--   por accidente; si hay que limpiar datos de prueba se hace con un DELETE explícito (Reto 8).
alter table catacion drop constraint fkcatacionlote;
alter table catacion
    add constraint fkcatacionlote
    foreign key (codLote) references lote(codLote)
    on delete restrict;

-- lote -> tostion: RESTRICT. Un lote que ya se tostó no se puede borrar sin antes
--   resolver qué pasa con esa tostión, para no dejar tostiones huérfanas.
alter table tostion drop constraint fktostionlote;
alter table tostion
    add constraint fktostionlote
    foreign key (codLote) references lote(codLote)
    on delete restrict;

-- cliente -> pedido: RESTRICT. No se pierde el historial de compras de un cliente.
alter table pedido drop constraint fkpedidocliente;
alter table pedido
    add constraint fkpedidocliente
    foreign key (idCliente) references cliente(idCliente)
    on delete restrict;

-- pedido -> detallepedido: CASCADE. Una línea de pedido no tiene sentido sin su
--   cabecera; si se borra un pedido de prueba, sus líneas deben irse con él.
alter table detallepedido drop constraint fkdetallepedidopedido;
alter table detallepedido
    add constraint fkdetallepedidopedido
    foreign key (idPedido) references pedido(idPedido)
    on delete cascade;

-- tostion -> detallepedido: RESTRICT. No se pierde el historial de qué se vendió
--   de esa tostión.
alter table detallepedido drop constraint fkdetallepedidotostion;
alter table detallepedido
    add constraint fkdetallepedidotostion
    foreign key (idTostion) references tostion(idTostion)
    on delete restrict;

-- 3) Filas "ancla" válidas para poder probar los CHECK que dependen de una FK.
insert into finca (nombreFinca, nombreCafiFinca, cedulaCafiFinca, codMpioFinca, codDeptoFinca, altitudFinca)
values ('Finca Prueba', 'Caficultor Prueba', '00000000', 41551, 41, 1500);

insert into lote (codLote, variedadLote, procesoLote, fechaCosechaLote, kilosLote, idFinca)
values ('TEST-0000-000', 'Caturra', 'lavado', '2026-01-01', 50.00,
        (select idFinca from finca where nombreFinca = 'Finca Prueba'));

insert into cliente (nombreCliente, cedulaCliente)
values ('Cliente Prueba', 'PRUEBA0001');

-- 4) Prueba de fuego: un INSERT que viole cada restricción a propósito

-- Viola chk_finca_altitud (altitud fuera de 800-2500)
insert into finca (nombreFinca, nombreCafiFinca, cedulaCafiFinca, codMpioFinca, codDeptoFinca, altitudFinca)
values ('Finca Invalida', 'Nadie', '99999999', 41551, 41, 100);

-- Viola chk_catacion_puntaje (puntaje fuera de 0-100)
insert into catacion (nombreCatador, codLote, puntajeScaCatador)
values ('Catador Prueba', 'TEST-0000-000', 150);

-- Viola chk_tostion_kilos (kilos de salida mayores a los de entrada)
insert into tostion (codLote, fechaTostion, kilosEntradaTostion, kilosSalidaTostion, perfilTostion)
values ('TEST-0000-000', '2026-01-02', 10.00, 20.00, 'medio');

-- Viola la unicidad de codLote (ya es PK)
insert into lote (codLote, variedadLote, procesoLote, fechaCosechaLote, kilosLote, idFinca)
values ('TEST-0000-000', 'Castillo', 'honey', '2026-01-05', 30.00,
        (select idFinca from finca where nombreFinca = 'Finca Prueba'));

-- Verificamos el valor por defecto de estadoPedido (no se envía ese campo)
insert into pedido (idCliente, fechaPedido)
values ((select idCliente from cliente where cedulaCliente = 'PRUEBA0001'), '2026-01-01');

select * from pedido where idCliente = (select idCliente from cliente where cedulaCliente = 'PRUEBA0001');

-- Limpiamos el pedido y el cliente de prueba;
-- dejamos la finca y el lote de prueba porque el Reto 8 los vuelve a usar.
delete from pedido where idCliente = (select idCliente from cliente where cedulaCliente = 'PRUEBA0001');
delete from cliente where cedulaCliente = 'PRUEBA0001';

-- Reflexión: ¿qué regla del caso no se puede expresar con un CHECK y por qué?
/*
 * La regla "un lote puede catarse más de una vez, por catadores distintos" no se puede
 * expresar con un CHECK, porque un CHECK solo valida los valores de columnas dentro de
 * la misma fila que se está insertando o actualizando; no puede comparar esa fila contra
 * otras filas de la tabla (por ejemplo, contar cuántas cataciones tiene ya el mismo lote
 * ni verificar que el catador sea distinto al de una catación anterior). Esa clase de
-- reglas "entre filas"
*/

-- RETO 4: Llegó el correo de Berlín =======================================================

-- País del cliente, obligatorio, por defecto Colombia
alter table cliente
    add column pais varchar(50) not null default 'Colombia';

-- Huella de carbono de cada tostión: puede ser nula, nunca negativa
alter table tostion
    add column huella_carbono_kg numeric(6,2) null;

alter table tostion
    add constraint chk_tostion_huella check (huella_carbono_kg >= 0);

-- Ampliamos la precisión de todas las columnas de kilos: de NUMERIC(7,2) a NUMERIC(10,2)
alter table lote
    alter column kilosLote type numeric(10,2);

alter table tostion
    alter column kilosEntradaTostion type numeric(10,2);

alter table tostion
    alter column kilosSalidaTostion type numeric(10,2);

alter table detallepedido
    alter column kilosPedido type numeric(10,2);

-- Una finca puede tener varias certificaciones y una certificación aplica a muchas
-- fincas:
create table certificacion(
    idCertificacion serial primary key,
    nombreCertificacion varchar(50) not null unique
);

create table finca_certificacion(
    idFinca integer not null,
    idCertificacion integer not null,
    primary key (idFinca, idCertificacion),
    constraint fkfincacertfinca
        foreign key (idFinca) references finca(idFinca)
        on delete restrict,
    constraint fkfincacertcert
        foreign key (idCertificacion) references certificacion(idCertificacion)
        on delete restrict
);

-- Renombramos puntajeScaCatador a puntajeSca: el nombre original sugiere que el
-- puntaje es del catador, cuando en realidad es el puntaje que ese catador le dio
-- a la catación (el catador ya está identificado en su propia columna nombreCatador).
alter table catacion
    rename column puntajeScaCatador to puntajeSca;


-- Reflexión: ¿por qué en producción es peligroso borrar y recrear una tabla en lugar de alterarla?
-- Borrar y recrear una tabla implica perder todos los datos que ya tenía a menos que se
-- haga un respaldo y una restauración perfecta, lo cual añade riesgo y tiempo de
-- inactividad, además, rompe temporalmente todas las llaves foráneas que apuntan a ella
-- (los lotes de una finca, por ejemplo, quedarían huérfanos), y obliga a recrear también
-- los índices, vistas, triggers y permisos que dependían de la tabla original. ALTER TABLE,
-- en cambio, modifica la estructura sin tocar las filas existentes ni las relaciones que ya
-- funcionan, así que el sistema sigue disponible mientras cambia.


-- RETO 5: La primera cosecha =========================================================

-- 4 fincas de 3 departamentos distintos (aquí van 4 departamentos distintos),
-- en una sola inserción de varias filas.
insert into finca (nombreFinca, nombreCafiFinca, cedulaCafiFinca, codMpioFinca, codDeptoFinca, altitudFinca) values
('La Esperanza', 'Carlos Pérez', '12345678', 41551, 41, 1750),
('El Mirador', 'Marta Gómez', '23456789', 63690, 63, 1900),
('Buena Vista', 'Jorge Ruiz', '34567890', 52110, 52, 2100),
('Villa Luz', 'Ana Torres', '45678901', 5364, 5, 1650);

-- 8 lotes (usamos subconsultas para tomar el idFinca correcto por cédula del caficultor)
insert into lote (codLote, variedadLote, procesoLote, fechaCosechaLote, kilosLote, idFinca)
values ('HUI-2026-001', 'Caturra', 'lavado', '2026-03-10', 320.50,
        (select idFinca from finca where cedulaCafiFinca = '12345678'));
insert into lote (codLote, variedadLote, procesoLote, fechaCosechaLote, kilosLote, idFinca)
values ('HUI-2026-002', 'Castillo', 'honey', '2026-03-15', 280.00,
        (select idFinca from finca where cedulaCafiFinca = '12345678'));
insert into lote (codLote, variedadLote, procesoLote, fechaCosechaLote, kilosLote, idFinca)
values ('QUI-2026-001', 'Geisha', 'natural', '2026-02-20', 150.75,
        (select idFinca from finca where cedulaCafiFinca = '23456789'));
insert into lote (codLote, variedadLote, procesoLote, fechaCosechaLote, kilosLote, idFinca)
values ('QUI-2026-002', 'Bourbon', 'lavado', '2026-02-25', 200.00,
        (select idFinca from finca where cedulaCafiFinca = '23456789'));
insert into lote (codLote, variedadLote, procesoLote, fechaCosechaLote, kilosLote, idFinca)
values ('NAR-2026-001', 'Caturra', 'honey', '2026-04-05', 310.25,
        (select idFinca from finca where cedulaCafiFinca = '34567890'));
insert into lote (codLote, variedadLote, procesoLote, fechaCosechaLote, kilosLote, idFinca)
values ('NAR-2026-002', 'Castillo', 'lavado', '2026-04-10', 275.50,
        (select idFinca from finca where cedulaCafiFinca = '34567890'));
insert into lote (codLote, variedadLote, procesoLote, fechaCosechaLote, kilosLote, idFinca)
values ('ANT-2026-001', 'Geisha', 'natural', '2026-01-15', 180.00,
        (select idFinca from finca where cedulaCafiFinca = '45678901'));
insert into lote (codLote, variedadLote, procesoLote, fechaCosechaLote, kilosLote, idFinca)
values ('ANT-2026-002', 'Caturra', 'lavado', '2026-01-20', 260.75,
        (select idFinca from finca where cedulaCafiFinca = '45678901'));

-- 10 cataciones (varios lotes catados más de una vez, por catadores distintos)
insert into catacion (nombreCatador, codLote, puntajeSca) values
('Laura Restrepo', 'HUI-2026-001', 86.50),
('Pedro Salazar',  'HUI-2026-001', 85.00),
('Laura Restrepo', 'HUI-2026-002', 82.25),
('Pedro Salazar',  'QUI-2026-001', 90.00),
('Laura Restrepo', 'QUI-2026-001', 88.75),
('Pedro Salazar',  'QUI-2026-002', 84.00),
('Laura Restrepo', 'NAR-2026-001', 87.25),
('Pedro Salazar',  'NAR-2026-002', 79.50),
('Laura Restrepo', 'ANT-2026-001', 91.00),
('Pedro Salazar',  'ANT-2026-002', 83.75);

-- 5 tostiones (dejamos 6 para tener material de sobra para los pedidos)
insert into tostion (codLote, fechaTostion, kilosEntradaTostion, kilosSalidaTostion, perfilTostion, huella_carbono_kg) values
('HUI-2026-001', '2026-03-20', 100.00, 84.00, 'medio',  12.50),
('QUI-2026-001', '2026-03-01', 50.00,  41.50, 'claro',  6.20),
('NAR-2026-001', '2026-04-15', 120.00, 100.80,'oscuro', 15.00),
('ANT-2026-001', '2026-01-25', 80.00,  67.20, 'medio',  9.80),
('HUI-2026-001', '2026-04-01', 90.00,  75.60, 'claro',  11.10),
('QUI-2026-002', '2026-03-05', 60.00,  50.40, 'medio',  7.30);

-- 3 clientes, uno en Alemania. CL2 no envía país: prueba el DEFAULT 'Colombia' del Reto 4.
insert into cliente (nombreCliente, cedulaCliente, celularCliente, correoCliente, pais) values
('Rösterei Berlin GmbH', '900123456', '3011234567', 'contacto@rosterei-berlin.de', 'Alemania');
insert into cliente (nombreCliente, cedulaCliente, celularCliente, correoCliente) values
('Café Boutique Bogotá', '900234567', '3021234567', 'ventas@cafeboutique.co');
insert into cliente (nombreCliente, cedulaCliente, celularCliente, correoCliente, pais) values
('Nordic Coffee House', 'SE55667788', '3031234567', 'hello@nordiccoffee.se', 'Suecia');

-- 4 pedidos, ninguno envía estadoPedido: prueba el DEFAULT 'pendiente' del Reto 3.
insert into pedido (idCliente, fechaPedido)
values ((select idCliente from cliente where cedulaCliente = '900123456'), '2026-04-10');
insert into pedido (idCliente, fechaPedido)
values ((select idCliente from cliente where cedulaCliente = '900234567'), '2026-04-12');
insert into pedido (idCliente, fechaPedido)
values ((select idCliente from cliente where cedulaCliente = '900123456'), '2026-04-20');
insert into pedido (idCliente, fechaPedido)
values ((select idCliente from cliente where cedulaCliente = 'SE55667788'), '2026-04-22');

-- 7 líneas de pedido en total (más de las 6 mínimas)
insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido) values
((select idPedido from pedido where idCliente = (select idCliente from cliente where cedulaCliente='900123456') and fechaPedido='2026-04-10'),
 (select idTostion from tostion where codLote='HUI-2026-001' and fechaTostion='2026-03-20'), 20.00, 45000);
insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido) values
((select idPedido from pedido where idCliente = (select idCliente from cliente where cedulaCliente='900123456') and fechaPedido='2026-04-10'),
 (select idTostion from tostion where codLote='NAR-2026-001' and fechaTostion='2026-04-15'), 15.00, 52000);
insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido) values
((select idPedido from pedido where idCliente = (select idCliente from cliente where cedulaCliente='900234567') and fechaPedido='2026-04-12'),
 (select idTostion from tostion where codLote='QUI-2026-001' and fechaTostion='2026-03-01'), 10.00, 60000);
insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido) values
((select idPedido from pedido where idCliente = (select idCliente from cliente where cedulaCliente='900123456') and fechaPedido='2026-04-20'),
 (select idTostion from tostion where codLote='HUI-2026-001' and fechaTostion='2026-03-20'), 25.00, 45000);
insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido) values
((select idPedido from pedido where idCliente = (select idCliente from cliente where cedulaCliente='900123456') and fechaPedido='2026-04-20'),
 (select idTostion from tostion where codLote='HUI-2026-001' and fechaTostion='2026-04-01'), 12.00, 48000);
insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido) values
((select idPedido from pedido where idCliente = (select idCliente from cliente where cedulaCliente='SE55667788') and fechaPedido='2026-04-22'),
 (select idTostion from tostion where codLote='ANT-2026-001' and fechaTostion='2026-01-25'), 18.00, 50000);
insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido) values
((select idPedido from pedido where idCliente = (select idCliente from cliente where cedulaCliente='SE55667788') and fechaPedido='2026-04-22'),
 (select idTostion from tostion where codLote='QUI-2026-002' and fechaTostion='2026-03-05'), 8.00, 55000);

-- Certificaciones del Reto 4 (N:M entre finca y certificacion)
insert into certificacion (nombreCertificacion) values
('Orgánico'),
('Fair Trade');

insert into finca_certificacion (idFinca, idCertificacion) values
((select idFinca from finca where cedulaCafiFinca='12345678'), (select idCertificacion from certificacion where nombreCertificacion='Orgánico')),
((select idFinca from finca where cedulaCafiFinca='12345678'), (select idCertificacion from certificacion where nombreCertificacion='Fair Trade')),
((select idFinca from finca where cedulaCafiFinca='23456789'), (select idCertificacion from certificacion where nombreCertificacion='Fair Trade')),
((select idFinca from finca where cedulaCafiFinca='34567890'), (select idCertificacion from certificacion where nombreCertificacion='Orgánico')),
((select idFinca from finca where cedulaCafiFinca='45678901'), (select idCertificacion from certificacion where nombreCertificacion='Orgánico')),
((select idFinca from finca where cedulaCafiFinca='45678901'), (select idCertificacion from certificacion where nombreCertificacion='Fair Trade'));

-- Tabla de lotes de especialidad (puntaje SCA promedio >= 85), cargada con INSERT...SELECT
create table lotes_especialidad(
    codigo_lote varchar(20) primary key,
    puntaje_promedio numeric(5,2) not null
);

insert into lotes_especialidad (codigo_lote, puntaje_promedio)
select l.codLote, avg(c.puntajeSca)
from lote l
join catacion c on c.codLote = l.codLote
group by l.codLote
having avg(c.puntajeSca) >= 85;

select * from lotes_especialidad order by puntaje_promedio desc;

/*
 * Reflexión: ¿lotes_especialidad se actualiza sola cuando llega una nueva catación?
 * ¿Qué objeto usarías para que sí lo hiciera?
 * No, lotes_especialidad no se actualiza sola: es una tabla normal que quedó cargada
 * con una foto del promedio de puntajes en el momento en que se ejecutó el INSERT...SELECT.
 * Si mañana llega una catación nueva para HUI-2026-002 que sube su promedio a 85+, esa
 * tabla seguirá mostrando el valor viejo hasta que alguien vuelva a correr la consulta.
 * Para que se actualizara sola necesitaría, o bien un TRIGGER en catacion (AFTER INSERT/
 * UPDATE/DELETE) que recalculara y refrescara la fila correspondiente en lotes_especialidad,
 * o, más simple, reemplazar la tabla por una VISTA (como la que se pide en el Reto 10), que
 * no guarda datos sino que recalcula el promedio cada vez que se consulta.
*/

-- ============================================================
-- RETO 6: La lista de precios que llega dos veces
-- ============================================================

create table precios_referencia(
    variedad varchar(20) primary key,
    precio_kg numeric(10,2) not null,
    actualizado_en timestamp not null default now()
);

-- Semana 1: carga inicial
insert into precios_referencia (variedad, precio_kg) values
('Castillo', 32000),
('Caturra', 35500),
('Geisha', 120000);

select * from precios_referencia;

-- Semana 2: upsert -> inserta Bourbon (nueva) y actualiza Caturra y Geisha (ya existían)
insert into precios_referencia (variedad, precio_kg) values ('Caturra', 36800)
on conflict (variedad)
do update set precio_kg = excluded.precio_kg, actualizado_en = now();

insert into precios_referencia (variedad, precio_kg) values ('Geisha', 118000)
on conflict (variedad)
do update set precio_kg = excluded.precio_kg, actualizado_en = now();

insert into precios_referencia (variedad, precio_kg) values ('Bourbon', 41000)
on conflict (variedad)
do update set precio_kg = excluded.precio_kg, actualizado_en = now();

-- Verificamos: deben quedar 4 variedades, y actualizado_en cambió en Caturra y Geisha
select * from precios_referencia order by variedad;
select count(*) as total_variedades from precios_referencia;

/*
 * Reflexión: ¿qué pasaría si variedad no fuera clave primaria ni UNIQUE?
 * Si variedad no fuera PK ni UNIQUE, el motor no tendría cómo decidir cuál fila ya
 * "existe" para actualizarla: ON DUPLICATE KEY UPDATE (o ON CONFLICT en PostgreSQL)
 * dependen de que exista una restricción de unicidad sobre la columna que se está
 * comparando. Sin esa restricción, cada INSERT de la semana 2 simplemente agregaría
 * una fila nueva con el mismo nombre de variedad en vez de actualizar la existente, y
 * terminaríamos con variedades duplicadas (por ejemplo, dos filas de "Caturra" con
 * precios distintos), lo que rompe el propósito del upsert.
*/

-- ============================================================
-- RETO 7: La balanza descalibrada
-- ============================================================

-- Antes de actualizar: contamos cuántas filas debería tocar el UPDATE (catador con
-- la balanza descalibrada: Laura Restrepo, 5 cataciones en nuestros datos)
select count(*) as filas_a_cambiar
from catacion
where nombreCatador = 'Laura Restrepo';

-- Restamos 1.5 puntos a todas sus cataciones, sin dejar ningún puntaje por debajo de 0
update catacion
set puntajeSca = greatest(puntajeSca - 1.5, 0)
where nombreCatador = 'Laura Restrepo';

-- Comparamos con lo que reportó el motor (UPDATE n)
select nombreCatador, codLote, puntajeSca
from catacion
where nombreCatador = 'Laura Restrepo';

-- Antes de actualizar: contamos cuántas líneas de pedido son del cliente alemán
select count(*) as filas_a_cambiar
from detallepedido dp
join pedido p on p.idPedido = dp.idPedido
join cliente c on c.idCliente = p.idCliente
where c.pais = 'Alemania';

-- Aplicamos el 10% de descuento a las líneas de pedido del cliente alemán (UPDATE ... FROM)
update detallepedido dp
set precioPedido = dp.precioPedido * 0.90
from pedido p
join cliente c on c.idCliente = p.idCliente
where p.idPedido = dp.idPedido
  and c.pais = 'Alemania';

select dp.idDetallePedido, dp.precioPedido
from detallepedido dp
join pedido p on p.idPedido = dp.idPedido
join cliente c on c.idCliente = p.idCliente
where c.pais = 'Alemania';

/*
 * Reflexión: ¿qué habría pasado si ejecutabas el UPDATE del descuento dos veces?
 * El descuento no es idempotente: cada vez que se ejecuta, multiplica el precio actual
 * por 0.90, así que correrlo dos veces aplicaría un 19% de descuento acumulado en total
 * (0.90 * 0.90 = 0.81) en vez del 10% que pidió el cliente alemán. Es el mismo problema
 * que la resta de 1.5 puntos a las cataciones: si se corre dos veces, el catador termina
 * con -3 puntos en vez de -1.5. Por eso conviene hacer primero el SELECT de verificación
 * (para saber exactamente qué filas se van a tocar) y, si el UPDATE se va a repetir por
 * error, envolverlo en una transacción para poder hacer ROLLBACK a tiempo.
*/

-- ============================================================
-- RETO 8: El caficultor que se fue
-- ============================================================

-- 1) Intentamos borrar una finca que ya tiene lotes vendidos: La Esperanza
--    (tiene lotes, esos lotes tienen tostiones ya vendidas en detallepedido, y además
--    tiene certificaciones asociadas). Con las FK en ON DELETE RESTRICT, el motor debe
--    impedirlo. Aquí PostgreSQL reporta la FK lote->finca, justo la que protege el
--    historial de ventas (requerimiento 6); en MySQL, sobre los mismos datos, el motor
--    reportó primero la FK de finca_certificacion, pero el resultado es el mismo: la
--    finca no se puede borrar mientras tenga hijos.
delete from finca where cedulaCafiFinca = '12345678';

-- 2) Alternativa: baja lógica. Agregamos la columna "activa" y la ponemos en falso
--    para esta finca, sin borrar nada ni romper el historial (requerimiento 6).
alter table finca
    add column activa boolean not null default true;

update finca
set activa = false
where cedulaCafiFinca = '12345678';

select idFinca, nombreFinca, activa from finca order by idFinca;

-- 3) Borramos las cataciones de un lote de prueba con un DELETE que cruza dos tablas,
--    filtrando por el código del lote (no por el id). Primero le agregamos un par de
--    cataciones de prueba al lote TEST-0000-000 para tener algo que borrar.
insert into catacion (nombreCatador, codLote, puntajeSca) values
('Catador Prueba', 'TEST-0000-000', 82.00),
('Catador Prueba', 'TEST-0000-000', 79.50);

select count(*) as cataciones_lote_prueba
from catacion
where codLote = 'TEST-0000-000';

delete from catacion c
using lote l
where l.codLote = c.codLote
  and l.codLote = 'TEST-0000-000';

select count(*) as cataciones_lote_prueba
from catacion
where codLote = 'TEST-0000-000';

-- 4) Vaciamos lotes_especialidad con TRUNCATE y después la eliminamos con DROP TABLE
truncate table lotes_especialidad restart identity;
drop table lotes_especialidad;

/*
 * Reflexión: explica en tus palabras la diferencia entre DELETE, TRUNCATE y DROP.
 * ¿Cuál es DML y cuáles DDL?
 * DELETE borra filas una por una (se puede filtrar con WHERE, queda registrado en el log
 * de transacciones y se puede revertir con ROLLBACK dentro de una transacción); es DML.
 * TRUNCATE vacía la tabla completa de una sola vez sin poder filtrar filas, reinicia el
 * contador de autoincremento (con RESTART IDENTITY), y aunque en PostgreSQL también se
 * puede revertir dentro de una transacción, se considera una operación de definición
 * porque afecta el almacenamiento físico de la tabla; formalmente se clasifica como DDL.
 * DROP TABLE va un paso más allá: elimina la tabla entera junto con su estructura
 * (columnas, restricciones, índices), no solo sus datos; también es DDL. En nuestro caso,
 * TRUNCATE nos sirvió para vaciar lotes_especialidad rápido antes de decidir que ya no la
 * necesitábamos, y DROP TABLE para eliminarla del todo, ya que en el Reto 10 la
 * reemplazamos por una vista que calcula lo mismo en tiempo real.
*/


-- RETO 9: El pedido que no puede quedar a medias


-- 1) Nuestro modelo no guardaba los kilos disponibles por tostión: los agregamos con
--    ALTER TABLE y un CHECK que impide valores negativos.
alter table tostion
    add column kilosDisponibles numeric(10,2) not null default 0;

-- Inicializamos: lo que salió de la tostión menos lo que ya se había vendido en el Reto 5/7
update tostion t
set kilosDisponibles = kilosSalidaTostion
    - coalesce((select sum(dp.kilosPedido) from detallepedido dp where dp.idTostion = t.idTostion), 0);

alter table tostion
    add constraint chk_tostion_disponibles check (kilosDisponibles >= 0);

select idTostion, codLote, kilosSalidaTostion, kilosDisponibles from tostion order by idTostion;

-- 2) Transacción que registra un pedido de 2 líneas y descuenta el inventario disponible
begin;

insert into pedido (idCliente, fechaPedido)
values ((select idCliente from cliente where cedulaCliente = '900234567'), '2026-05-01')
returning idpedido as id \gset pedido_ok_

insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido)
values (:pedido_ok_id,
        (select idTostion from tostion where codLote = 'HUI-2026-001' and fechaTostion = '2026-03-20'),
        10.00, 45000);

update tostion
set kilosDisponibles = kilosDisponibles - 10.00
where codLote = 'HUI-2026-001' and fechaTostion = '2026-03-20';

insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido)
values (:pedido_ok_id,
        (select idTostion from tostion where codLote = 'QUI-2026-001' and fechaTostion = '2026-03-01'),
        5.00, 60000);

update tostion
set kilosDisponibles = kilosDisponibles - 5.00
where codLote = 'QUI-2026-001' and fechaTostion = '2026-03-01';

commit;

select * from pedido where idPedido = :pedido_ok_id;
select * from detallepedido where idPedido = :pedido_ok_id;

-- 3) Simulamos el desastre: repetimos la transacción pidiendo más kilos de los
--    disponibles. El CHECK debe fallar; hacemos ROLLBACK y comprobamos con un SELECT
--    que no quedó ni la cabecera del pedido.
begin;

insert into pedido (idCliente, fechaPedido)
values ((select idCliente from cliente where cedulaCliente = '900234567'), '2026-05-02')
returning idpedido as id \gset pedido_fallido_

insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido)
values (:pedido_fallido_id,
        (select idTostion from tostion where codLote = 'HUI-2026-001' and fechaTostion = '2026-03-20'),
        5.00, 45000);

update tostion
set kilosDisponibles = kilosDisponibles - 5.00
where codLote = 'HUI-2026-001' and fechaTostion = '2026-03-20';

insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido)
values (:pedido_fallido_id,
        (select idTostion from tostion where codLote = 'NAR-2026-001' and fechaTostion = '2026-04-15'),
        9999.00, 52000);

-- Esta UPDATE intenta dejar kilosDisponibles negativo: debe fallar por chk_tostion_disponibles
update tostion
set kilosDisponibles = kilosDisponibles - 9999.00
where codLote = 'NAR-2026-001' and fechaTostion = '2026-04-15';

rollback;

-- No debe quedar ni la cabecera del pedido fallido
select * from pedido where idPedido = :pedido_fallido_id;

-- 4) SAVEPOINT: deshacemos solo la segunda línea y confirmamos la primera
begin;

insert into pedido (idCliente, fechaPedido)
values ((select idCliente from cliente where cedulaCliente = '900234567'), '2026-05-03')
returning idpedido as id \gset pedido_sp_

savepoint antes_linea_1;

insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido)
values (:pedido_sp_id,
        (select idTostion from tostion where codLote = 'ANT-2026-001' and fechaTostion = '2026-01-25'),
        4.00, 50000);

update tostion
set kilosDisponibles = kilosDisponibles - 4.00
where codLote = 'ANT-2026-001' and fechaTostion = '2026-01-25';

savepoint despues_linea_1;

insert into detallepedido (idPedido, idTostion, kilosPedido, precioPedido)
values (:pedido_sp_id,
        (select idTostion from tostion where codLote = 'QUI-2026-002' and fechaTostion = '2026-03-05'),
        3.00, 55000);

update tostion
set kilosDisponibles = kilosDisponibles - 3.00
where codLote = 'QUI-2026-002' and fechaTostion = '2026-03-05';

-- Nos arrepentimos solo de la segunda línea
rollback to savepoint despues_linea_1;

commit;

select * from detallepedido where idPedido = :pedido_sp_id;

-- 5) Experimento comparativo: CREATE TABLE dentro de una transacción y luego ROLLBACK
begin;
create table prueba (id int);
rollback;

-- ¿La tabla existe? En PostgreSQL el DDL sí es transaccional: el CREATE TABLE queda
-- deshecho igual que cualquier INSERT, así que la tabla ya no existe.
select * from prueba;

/*
 * Reflexión: ¿qué descubriste en el punto 5 y qué riesgo implica para un script de
 * migración en MySQL?
 * Descubrimos que PostgreSQL sí trata el DDL como parte de la transacción: el CREATE
 * TABLE del experimento quedó completamente deshecho con el ROLLBACK, y la tabla "prueba"
 * ni siquiera existe (el SELECT final da error "relation does not exist"). Esto es lo
 * opuesto a lo que vimos en MySQL, donde el mismo CREATE TABLE se queda para siempre
 * aunque se haga ROLLBACK después, porque el motor le hace un COMMIT implícito. El riesgo
 * concreto para un script de migración en MySQL es que si se mezcla DDL con DML dentro de
 * lo que se cree que es una sola transacción y el script falla a mitad de camino, los
 * cambios de estructura (tablas o columnas creadas) ya quedaron aplicados de forma
 * irreversible, mientras que los datos si se revierten, dejando la base en un estado
 * intermedio e inconsistente que hay que arreglar a mano.
*/

-- ============================================================
-- RETO 10: El QR que cuenta la historia
-- ============================================================

-- Reto creativo: un dato más que enriquece la historia del QR para el consumidor final:
-- notas de sabor de la catación (floral, cítrico, chocolate...). Lo agregamos al modelo.
alter table catacion
    add column if not exists notasCata varchar(200) null;

update catacion set notasCata = 'Notas florales y a panela, cuerpo suave'      where codLote = 'HUI-2026-001' and nombreCatador = 'Pedro Salazar';
update catacion set notasCata = 'Notas a chocolate y frutos secos'            where codLote = 'HUI-2026-002';
update catacion set notasCata = 'Notas cítricas y florales, taza muy limpia'  where codLote = 'QUI-2026-001' and nombreCatador = 'Pedro Salazar';
update catacion set notasCata = 'Notas a durazno y jazmín'                    where codLote = 'QUI-2026-001' and nombreCatador = 'Laura Restrepo';
update catacion set notasCata = 'Notas a caramelo y almendra'                 where codLote = 'QUI-2026-002';
update catacion set notasCata = 'Notas a mora y panela'                      where codLote = 'NAR-2026-001';
update catacion set notasCata = 'Notas herbales, acidez media'                where codLote = 'NAR-2026-002';
update catacion set notasCata = 'Notas tropicales, taza muy dulce'            where codLote = 'ANT-2026-001';
update catacion set notasCata = 'Notas a cacao y nuez'                        where codLote = 'ANT-2026-002';

-- Script idempotente: se puede correr varias veces sin fallar
drop view if exists v_trazabilidad;

create or replace view v_trazabilidad as
select
    dp.idPedido,
    dp.idDetallePedido,
    cli.nombreCliente,
    cli.pais,
    f.nombreFinca,
    f.nombreCafiFinca,
    case f.codMpioFinca
        when 41551 then 'Pitalito'
        when 63690 then 'Salento'
        when 52110 then 'Buesaco'
        when 5364  then 'Jardín'
        else concat('Municipio ', f.codMpioFinca)
    end as municipio,
    f.altitudFinca,
    lo.variedadLote,
    lo.procesoLote,
    round((select avg(c.puntajeSca) from catacion c where c.codLote = lo.codLote)::numeric, 2) as puntajeScaPromedio,
    (select ca.notasCata from catacion ca where ca.codLote = lo.codLote and ca.notasCata is not null limit 1) as notasCata,
    t.fechaTostion,
    t.perfilTostion,
    t.huella_carbono_kg,
    lo.variedadLote || ' ' || lo.procesoLote || ' de Finca ' || f.nombreFinca || ', ' ||
    (case f.codMpioFinca
        when 41551 then 'Pitalito'
        when 63690 then 'Salento'
        when 52110 then 'Buesaco'
        when 5364  then 'Jardín'
        else concat('Municipio ', f.codMpioFinca)
    end) ||
    ' (' || f.altitudFinca || ' m). Puntaje ' ||
    round((select avg(c2.puntajeSca) from catacion c2 where c2.codLote = lo.codLote)::numeric, 2) ||
    '. Tostado ' || t.perfilTostion || ' el ' || t.fechaTostion || '. ' ||
    coalesce((select ca2.notasCata || '.' from catacion ca2 where ca2.codLote = lo.codLote and ca2.notasCata is not null limit 1), '')
    as texto_qr
from detallepedido dp
join pedido p on p.idPedido = dp.idPedido
join cliente cli on cli.idCliente = p.idCliente
join tostion t on t.idTostion = dp.idTostion
join lote lo on lo.codLote = t.codLote
join finca f on f.idFinca = lo.idFinca;

-- Consultamos la vista filtrando un solo pedido, como lo haría la app al escanear
-- las bolsas de ese pedido
select * from v_trazabilidad where idPedido = 2;

/*
 * Reflexión: ¿una vista guarda datos? ¿Qué ventaja tiene sobre copiar los datos a una
 * tabla como hiciste en el Reto 5?
 * No, una vista no guarda datos propios: es una consulta guardada con nombre que se
 * vuelve a ejecutar cada vez que se consulta, trayendo siempre el estado actual de las
 * tablas que combina (dp, pedido, cliente, tostion, lote, finca, catacion). La ventaja
 * frente a lotes_especialidad del Reto 5, que era una tabla física con una foto fija de
 * los promedios, es justamente esa: v_trazabilidad nunca queda desactualizada. Si mañana
 * llega una catación nueva para HUI-2026-001, la próxima vez que alguien escanee una
 * bolsa de ese lote, puntajeScaPromedio y texto_qr ya van a reflejar el nuevo promedio
 * sin que nadie tenga que volver a correr un INSERT...SELECT ni acordarse de mantenerlo
 * sincronizado a mano.
*/

