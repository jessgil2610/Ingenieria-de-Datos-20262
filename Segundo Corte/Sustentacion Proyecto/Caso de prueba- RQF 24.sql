-- El sistema debe mantener el catálogo de ramas de actividad con las 13 ramas agrupadas a partir de RAMA2D_R4 
-- y dejar sin rama a los ocupados que no la informan.

-- El codigo no corre porque la tabla ya esta creada y si se borra se borran los datos
create table ramaActividad(
	idRamaActividad primary key not null, -- Se crea la tabla de rama de actividad que permite cargar las ramas de activdad de los ocupados
	nombreRama not null
	);


create table ocupado(
	idPersona varchar(20) primary key not null,
	idRamaActividad null -- Al ser null se permite cargar ocupados que no tengan rama de actividad
	-- Aqui van el resto de variables de esa tabla
)

insert into ramaActividad (idRamaActividad, nombreRama) values 
(1, 'comercio'),
(2, 'construccion'); -- Se inserta el resto de datos de la tabla

-- Se llama a la vista creada para ver los ocupados por rama
select * from v_ocupados_por_rama;
