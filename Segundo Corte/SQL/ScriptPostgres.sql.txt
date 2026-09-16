create database tienda_tecno
	with encoding ='UTF8'
	template= template0;

/* Crear tablas*/
create table clientes(
idCliente serial primary key,
nombreCliente varchar(50) not null ,
correoCliente varchar(120)not null unique,
fechaRegitro date not null default current_date
);

/* Tabla Producto*/
create table producto(
idProducto serial primary key,
nombreProducto varchar(100) not null,
precioProducto numeric(10,2) not null check (precioproducto >0),
stock integer not null default 0
);

/*Tabla Pedido*/
create table pedido(
idPedido serial primary key,
idClienteFK integer not null references clientes(idcliente) on delete cascade,
fechaPedido timestamp not null default now(),
estadoPedido varchar(20) not null default 'Pendiente'
);

/*tabla detalle pedido*/
create table detallePedido(
idpedidoFK integer not null references pedido(idpedido) on delete cascade,
idproductoFK integer not null references producto(idproducto) on delete cascade,
cantidad integer not null check (cantidad >0),
primary key (idpedidoFK,idproductoFK)
);

alter table producto alter column nombreproducto type varchar(150);
alter table pedido rename column estadopedido to estado;

drop table if exists detallepedido;

truncate table detallePedido restart identity cascade;
