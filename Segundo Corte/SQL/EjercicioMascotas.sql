create database veterinaria;
use veterinaria;

create table cliente(
cedulaCliente varchar(20) primary key,
nombreCliente varchar(30) not null,
apellidoCliente varchar(30) not null,
direccionCliente varchar(50)
);

create table telefonoCliente(
idTelefono int auto_increment primary key,
telefonoCliente varchar(15) not null,
cedulaClienteFK varchar(20),
constraint fktelefonocliente
foreign key (cedulaClienteFK)
references cliente(cedulaCliente)
on delete cascade
);

create table producto(
codigoProducto varchar(20) primary key,
nombreProducto varchar(50) not null,
marcaProducto varchar(30),
precioProducto decimal(10,2)
);

create table compra(
idCompra int auto_increment primary key,
cedulaClienteFK varchar(20),
codigoProductoFK varchar(20),
constraint fkclientecompra
foreign key (cedulaClienteFK)
references cliente(cedulaCliente)
on delete cascade,
constraint fkproductocompra
foreign key (codigoProductoFK)
references producto(codigoProducto)
on delete cascade
);

create table mascota(
idMascota varchar(20) primary key,
nombreMascota varchar(30) not null,
tipoMascota varchar(20),
generoMascota varchar(10),
razaMascota varchar(30),
cedulaClienteFK varchar(20),
constraint fkclientemascota
foreign key (cedulaClienteFK)
references cliente(cedulaCliente)
on delete cascade
);

create table vacuna(
codigoVacuna varchar(20) primary key,
dosisVacuna varchar(20),
nombreVacuna varchar(50) not null,
enfermedadVacuna varchar(50),
idMascotaFK varchar(20),
constraint fkmascotavacuna
foreign key (idMascotaFK)
references mascota(idMascota)
on delete cascade
);


-- indices es una estructura de datos que agiliza las consultas
-- simpl: crea una sola columna
-- compuesto: crrea sobre multiples columnas funciona de izq a derecha
-- costo: los que aceleran draticamente las consultas

create index idxNombreProducto on producto(nombreProducto);

-- Inserciones -> permite registrar nuevos registros
-- Insercion unitaria
-- Sintaxis insert to nombreTabla(campo1, campo2, campo3,..., campon) values(val1, val2, val3,...,valn)

-- Consulta general
-- select * from nombreTabla

-- inserciones multiples
-- Sintaxis insert to nombreTabla(campo1, campo2, campo3,..., campon) values(val1, val2, val3,...,valn), values(val1, val2, val3,...,valn), values(val1, val2, val3,...,valn);


-- Hacer 10 registros en cada tabla
-- agregar un campo calculado - como se hace una inserción a una tabla cuando tengo un autoincrement

-- Solucion
insert into cliente(cedulaCliente, nombreCliente, apellidoCliente, direccionCliente) values
("524455555", "Jesus", "Ortiz", "Calle 24"),
("5255665", "Alejandra", "Suarez", "Carrera 13"),
("100200300", "Carlos", "Ramirez", "Calle 45"),
("100200301", "Laura", "Gomez", "Carrera 20"),
("100200302", "Andres", "Lopez", "Calle 80"),
("100200303", "Camila", "Diaz", "Carrera 7"),
("100200304", "Felipe", "Martinez", "Calle 100"),
("100200305", "Valentina", "Rojas", "Carrera 50"),
("100200306", "Santiago", "Torres", "Calle 33"),
("100200307", "Isabella", "Vargas", "Carrera 15");

-- cuando una tabla tiene un campo auto_increment (como idTelefono, idCompra), simplemente no lo incluyes en la lista de campos de la inserción — MySQL lo genera solo:

insert into telefonoCliente(telefonoCliente, cedulaClienteFK) values
("3001234567", "524455555"),
("3007654321", "5255665"),
("3012345678", "100200300"),
("3023456789", "100200301"),
("3034567890", "100200302"),
("3045678901", "100200303"),
("3056789012", "100200304"),
("3067890123", "100200305"),
("3078901234", "100200306"),
("3089012345", "100200307");

insert into producto(codigoProducto, nombreProducto, marcaProducto, precioProducto) values
("P001", "Alimento Perro Adulto", "Dogchow", 45000),
("P002", "Alimento Gato Adulto", "Whiskas", 38000),
("P003", "Shampoo Antipulgas", "Bioline", 22000),
("P004", "Correa Retractil", "Petmax", 35000),
("P005", "Cama para Mascota", "Confipet", 60000),
("P006", "Juguete Mordedor", "Kong", 18000),
("P007", "Arena para Gato", "Cleanpet", 25000),
("P008", "Comedero Doble", "Petmax", 20000),
("P009", "Vitaminas Caninas", "Vetnova", 30000),
("P010", "Transportadora Mediana", "Petcargo", 90000);

insert into compra(cedulaClienteFK, codigoProductoFK) values
("524455555", "P001"),
("5255665", "P002"),
("100200300", "P003"),
("100200301", "P004"),
("100200302", "P005"),
("100200303", "P006"),
("100200304", "P007"),
("100200305", "P008"),
("100200306", "P009"),
("100200307", "P010");

insert into mascota(idMascota, nombreMascota, tipoMascota, generoMascota, razaMascota, cedulaClienteFK) values
("M001", "Firulais", "Perro", "Macho", "Labrador", "524455555"),
("M002", "Michi", "Gato", "Hembra", "Siames", "5255665"),
("M003", "Rocky", "Perro", "Macho", "Bulldog", "100200300"),
("M004", "Luna", "Gato", "Hembra", "Persa", "100200301"),
("M005", "Toby", "Perro", "Macho", "Beagle", "100200302"),
("M006", "Nina", "Gato", "Hembra", "Angora", "100200303"),
("M007", "Max", "Perro", "Macho", "Pastor Aleman", "100200304"),
("M008", "Pelusa", "Gato", "Hembra", "Comun Europeo", "100200305"),
("M009", "Zeus", "Perro", "Macho", "Boxer", "100200306"),
("M010", "Kira", "Gato", "Hembra", "Bengali", "100200307");

insert into vacuna(codigoVacuna, dosisVacuna, nombreVacuna, enfermedadVacuna, idMascotaFK) values
("V001", "1ml", "Rabia", "Rabia", "M001"),
("V002", "0.5ml", "Triple Felina", "Panleucopenia", "M002"),
("V003", "1ml", "Parvovirus", "Parvovirus", "M003"),
("V004", "0.5ml", "Leucemia Felina", "Leucemia Felina", "M004"),
("V005", "1ml", "Moquillo", "Moquillo", "M005"),
("V006", "0.5ml", "Rinotraqueitis", "Rinotraqueitis", "M006"),
("V007", "1ml", "Hepatitis", "Hepatitis Canina", "M007"),
("V008", "0.5ml", "Calicivirus", "Calicivirus", "M008"),
("V009", "1ml", "Leptospirosis", "Leptospirosis", "M009"),
("V010", "0.5ml", "Coriza", "Coriza Felina", "M010");

select nombreProducto AS 'Producto', precioProducto AS 'Precio',
precioProducto * 0.9 AS 'PrecioConDescuento'
from producto;

-- Crear índice
create index idxNombreMAscota on mascota(nombreMascota);

select * from mascota;
select * from telefonoCliente;

-- Consultas
-- Sentencia Select
-- general : select * from nombreTabla

select * from mascota;
select nombreMascota,tipoMascota,generoMascota from mascota;


-- Consulta con alias select (campos) as 'nombre alias' from nombreTabla
select nombreMascota as 'Nombre Mascota' ,tipoMascota as 'Tipo Mascota',generoMascota as 'Genero mascota' from mascota;

-- Consulta con ordenamientos select (campos) from tabla order by campo a ordenar ASC/DESC
select *  from mascota order by nombreMascota ASC;

select *  from mascota order by nombreMascota DESC;

-- Consulta con clausula where (con condiciones)
-- select campo from tabla where condicion (< > = >= <= diferente(<>))
select * from producto
select * from producto where precioProducto>20000
select * from producto where precioProducto<20000
select * from producto where precioProducto=18000
select * from mascota where tipoMascota='perro'
select * from mascota where tipoMascota<>'perro'

-- comparadores lógicos anf (y) or (o) negación (not)
select * from mascota where tipoMascota='gato' and nombreMascota='Luna'
select * from mascota where tipoMascota='gato' or nombreMascota='Luna'
select * from mascota where not nombreMascota='Luna'
select * from mascota where tipoMascota='gato' and (nombreMascota='Luna' or nombreMascota='Michi')
select * from mascota ma where ma.tipoMascota='gato' and (nombreMascota='Luna' or nombreMascota='Michi')

-- consulta de un índice
show index from mascota
describe mascota

select distinct nombreMascota from information_schema.STATISTICS s  where s.TABLE_SCHEMA =mascota and s.TABLE_NAME ='Nombres';

-- Consultas multitabla, subconsultas y funciones

/* 
 * Trabajas como desarrollador en TecnoAndes, una tienda de tecnología. 
 * El sistema de ventas guarda la información en cinco tablas: 
 * clientes, vendedores, productos, pedidos y detalle_pedido. 
 * El miercoles a las 8:00 el gerente te escribe por el chat:
 
1.       “¿Qué clientes han comprado?” Tabla clientes y pedido (FK de clientes)
2.       “¿Qué productos compró cada cliente?” detallePedido
3.       “¿Qué vendedor vendió más?” 
4.       “¿Cuáles productos cuestan más que el promedio?”
5.       “¿Cuánto hemos vendido en total?”
6.       “¿Qué clientes se registraron y nunca compraron? Quiero llamarlos.” clientes y pedido
Necesita todo antes de la reunión de las 10:00.
 */






























