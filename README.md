# Ingeniería de Datos 2026-2

Repositorio con los entregables del curso de **Ingeniería de Datos**. Reúne las tareas y trabajos organizados por corte.

- **Autora:** Jessica Alejandra Gil Tellez
- **Curso:** Ingeniería de Datos · 2026-2
- **Universidad:** Universidad del Rosario

---

## Estructura del repositorio

```
Ingenieria-de-Datos-20262/
├── Primer Corte/
│   ├── ETL/
│   │   ├── Dato y kanban.docx
│   │   ├── Transformación BD.docx
│   │   └── 03_08 ETL base Excel_Colab/
│   │       ├── student_performance_original.csv
│   │       ├── student_performance_limpio.xlsx
│   │       └── ETL_student_performance_colab.ipynb
│   ├── EDA/
│   │   ├── EDA_rendimiento_estudiantil.xlsx
│   │   ├── EDA_rendimiento_estudiantil.ipynb
│   │   ├── Ejercicio tienda original.xlsx
│   │   ├── Ejercicio_tienda_ETL_EDA.xlsx
│   │   └── Ejercicio_tienda_ETL_EDA.ipynb
│   ├── Diseño BD/
│   │   ├── D.Clases_EjercicioClase.png
│   │   └── TallerClase/
│   │       ├── Taller DiseñoBD.docx
│   │       ├── MER.drawio.png
│   │       ├── MR.png
│   │       ├── DiagramaClases.drawio.png
│   │       ├── Ejercicio1-MER.png
│   │       ├── Ejercicio2-MR.png
│   │       └── Ejercicio3-MR.png
│   ├── Proyecto/
│   │   ├── 03_08 Necesidad.docx
│   │   ├── 19_08 Requerimientos Funcionales.docx
│   │   ├── 19_08 Historias de usuario.docx
│   │   └── Kanban Trello.url
│   └── Parcial Práctico/
│       ├── Parte 1/
│       │   ├── ActividadClase- Ingeniería de datos.pdf
│       │   ├── ModeloConceptual.jpeg
│       │   ├── DigramaClases.png
│       │   └── Punto 6- TablaComparativa.pdf
│       └── Parte 2/
│           ├── M2_viajes_agosto_modifica.xlsx
│           ├── Momento4Grupo1.pdf
│           └── SustentacionpracticaG1.pdf
├── Segundo Corte/
│   ├── Definiciones/
│   │   ├── Entornos de trabajo.docx
│   │   ├── Insercion de datos postgres y SQL.docx
│   │   └── Funciones SQL.docx
│   ├── SQL/
│   │   ├── EjercicioMascotas.sql
│   │   ├── EjercicioPostgres.sql
│   │   ├── EjerciciosDDLBiblioteca.sql
│   │   ├── ScriptPostgres.sql.txt
│   │   ├── Ejercicio Eduplus - Clase.sql
│   │   ├── Tarea TechCorp.sql
│   │   └── Procedimientos Almacenados - Actividad Clase.docx
│   ├── Laboratorio TrazaCafe/
│   │   ├── Laboratorio TrazaCafe.docx
│   │   ├── Diccionario datos.xlsx
│   │   ├── Modelo MR.png
│   │   ├── trazacafe_mysql.sql
│   │   └── trazacafe_postgres.sql
│   ├── Laboratorio BibliotecaDB (Triggers)/
│   │   ├── Ejercicio Trigger - Resultados.docx
│   │   └── LaboratorioBiblioteca_db.sql
│   ├── Simulacro_parcial_practico/
│   │   ├── README.md
│   │   ├── Modelo Relacional/
│   │   │   └── modelo_relacional.drawio.png
│   │   ├── MySQL/
│   │   │   ├── simulacro_parcial_practico2_mysql.sql
│   │   │   └── guia_estudio_sql.sql
│   │   └── Postgresql/
│   │       └── simulacro_parcial_practico2_postgresql.sql
│   ├── Segundo Parcial Práctico/
│   │   ├── README.md
│   │   ├── Segundo Parcial Práctico.docx
│   │   ├── Modelo Relacional/
│   │   │   └── Modelo Relacional.png
│   │   └── MySQL/
│   │       └── mysql.sql
│   └── Sustentacion Proyecto/
│       └── Caso de prueba- RQF 24.sql
└── Tercer Corte/
    └── MongoDB/
        ├── Quiz1_28_10_2026.txt
        ├── Tarea_29_10_2026.txt
        ├── clase_29_10_2026.txt
        └── lab1_gil.js
```

## Corte 1

### ETL

- **Dato y kanban** — Qué es un dato y fundamentos de la metodología Kanban.
- **Transformación BD** — Los 8 pasos de la transformación de datos y el manejo de los valores nulos.
- **03_08 ETL base Excel_Colab** — Ejercicio de ETL sobre la base `student_performance` (limpieza de datos) con Excel/Power Query y Google Colab.
  - `student_performance_original.csv` — base cruda para limpiar.
  - `student_performance_limpio.xlsx` — base limpia con Excel/Power Query.
  - `ETL_student_performance_colab.ipynb` — el mismo proceso de ETL en Python (Colab).

### EDA

- **EDA rendimiento estudiantil** — Análisis exploratorio sobre la base limpia de estudiantes, en Excel y en Colab.
  - `EDA_rendimiento_estudiantil.xlsx` — EDA con fórmulas y gráficos.
  - `EDA_rendimiento_estudiantil.ipynb` — el mismo EDA en Python.
- **Ejercicio tienda** — ETL y EDA sobre una base pequeña de ventas y compras de una tienda.
  - `Ejercicio tienda original.xlsx` — base original del ejercicio.
  - `Ejercicio_tienda_ETL_EDA.xlsx` — registros completados, limpieza (ETL) y análisis (EDA) en Excel.
  - `Ejercicio_tienda_ETL_EDA.ipynb` — el mismo ejercicio en Python.

### Diseño BD

- **TallerClase** — Taller de diseño de bases de datos: modelo entidad-relación (MER), modelo relacional (MR) y diagrama de clases.
  - `Taller DiseñoBD.docx` — enunciado y desarrollo del taller.
  - `MER.drawio.png`, `MR.png`, `DiagramaClases.drawio.png` — diagramas del taller.
  - `Ejercicio1-MER.png`, `Ejercicio2-MR.png`, `Ejercicio3-MR.png` — ejercicios de modelado.
- `D.Clases_EjercicioClase.png` — diagrama de clases del ejercicio en clase.

### Proyecto

- **03_08 Necesidad** — Identificación de una necesidad de un cliente real orientada a construir una base de datos.
- **19_08 Requerimientos Funcionales** — Requerimientos funcionales del proyecto (base de datos y tablero).
- **19_08 Historias de usuario** — Historias de usuario del proyecto.
- **Kanban Trello** — Enlace al tablero Kanban del proyecto en Trello.

### Parcial Práctico

- **Parte 1**
  - **ActividadClase- Ingeniería de datos** — Enunciado del parcial práctico.
  - **ModeloConceptual** — Modelo conceptual de la base de datos.
  - **DigramaClases** — Diagrama de clases.
  - **Punto 6- TablaComparativa** — Tabla comparativa (punto 6 del parcial).
- **Parte 2**
  - **M2_viajes_agosto_modifica** — Base de datos de viajes usada en el segundo momento del parcial.
  - **Momento4Grupo1** — Documento del cuarto momento del parcial práctico grupal.
  - **SustentacionpracticaG1** — Sustentación del ejercicio práctico grupal.

---

## Corte 2

### Definiciones

- **Entornos de trabajo** — Descripción comparativa de herramientas de bases de datos: MySQL Workbench, XAMPP, Adobe Dreamweaver y PostgreSQL.
- **Insercion de datos postgres y SQL** — Cómo insertar datos desde un archivo de texto plano en una tabla ya creada, usando `COPY` en PostgreSQL y sentencias equivalentes en SQL, según el formato y delimitador del archivo.
- **Funciones SQL** — Referencia de funciones numéricas, de agregación y de cadena en MySQL

### SQL

- **EjercicioMascotas** — Script DDL para una base de datos de veterinaria (clientes, teléfonos y llaves foráneas).
- **EjercicioPostgres** / **ScriptPostgres** — Script de creación de la base `tienda_tecno` en PostgreSQL, con tablas de clientes y productos.
- **EjerciciosDDLBiblioteca** — Ejercicios de sentencias DDL para una base de datos de biblioteca (libros y autores).
- **Ejercicio Eduplus - Clase** — Ejercicio en MySQL sobre consultas multitabla, subconsultas y funciones de agregación, vistas, procedimiento almacenado y triggers (auditoría de cambios de precio de los cursos y normalización del correo de los instructores).
- **Tarea TechCorp** — Base de datos `TechCorp` con 15 empleados simulados.
- **Procedimientos Almacenados - Actividad Clase** — Ejercicio de Clase de Procedimientos Almacenados

### Laboratorio TrazaCafe

Laboratorio de DDL y DML en MySQL y PostgreSQL sobre la trazabilidad del café, desde la finca hasta el pedido del cliente.

- **Laboratorio TrazaCafe** — Documento del laboratorio con el Reto 1: entidades (finca, lote, catación, tostión, cliente, pedido y detalle de pedido), claves, tipos de datos y reflexión sobre cómo el diseño conserva el historial cuando un caficultor se va.
- **Diccionario datos** — Diccionario de datos del modelo (columna, tipo, obligatoriedad y regla de negocio).
- **Modelo MR** — Diagrama del modelo relacional.
- **trazacafe_mysql** / **trazacafe_postgres** — Scripts del mismo laboratorio en cada motor. 

### Laboratorio BibliotecaDB (Triggers)

Laboratorio sobre vistas, procedimientos almacenados y triggers para una biblioteca (socios, libros, préstamos e historial de préstamos).

- **Ejercicio Trigger - Resultados** — Documento con los requerimientos del ejercicio, la solución de cada uno y las capturas de la salida del código.
- **LaboratorioBiblioteca_db** — Script en MySQL con la base `biblioteca_db` y datos de prueba. Incluye la vista `v_prestamos_vencidos`, el procedimiento `sp_prestar_libro`, el trigger `trg_prestamos_devolucion` (devuelve el ejemplar al inventario y registra la devolución en el historial) y el reto opcional con un trigger que valida la fecha de devolución.

### Simulacro Parcial Práctico
 
Simulacro del segundo parcial práctico sobre la base de datos de **DronAndes Express** (Proyecto Cóndor), resuelto en MySQL y en PostgreSQL.
 
- **Modelo Relacional** — `modelo_relacional.drawio.png`, diagrama del modelo relacional.
- **MySQL**
  - `simulacro_parcial_practico2_mysql.sql` — Solución completa: creación de la base (bases, tipos de carga, drones, pilotos, clientes, entregas, cargas, mantenimientos e historial), `ALTER TABLE`, DML, consultas básicas, agrupaciones, joins, subconsultas, vista, índices, función almacenada, trigger y procedimiento.
  - `guia_estudio_sql.sql` — Guía de estudio de SQL en MySQL organizada por temas, desde DDL y DML hasta transacciones y diferencias con PostgreSQL.
- **Postgresql** — `simulacro_parcial_practico2_postgresql.sql`, la misma solución adaptada a PostgreSQL.
### Segundo Parcial Práctico
 
Parcial práctico sobre la base de datos de **CicloVerde** (sistema de bicicletas compartidas), en MySQL 8.0.
 
- **Segundo Parcial Práctico** — Documento de entrega con el enlace al repositorio, el script y los pantallazos de su ejecución.
- **Modelo Relacional** — Diagrama del modelo relacional (modelo físico).
- **MySQL** — `mysql.sql`, script con las tablas (estaciones, bicicletas, usuarios, accesorios, viajes, viaje_accesorio e historial de bicicletas), ajustes con `ALTER TABLE`, DML, consultas.
### Sustentación Proyecto
 
- **Caso de prueba- RQF 24** — Caso de prueba del requerimiento RQF 24.
---
 
## Corte 3
 
### MongoDB
 
Trabajo con la base de datos `saborya` (restaurantes, clientes, productos y pedidos de domicilios) en MongoDB.
 
- **Quiz1_28_10_2026** — Quiz 1: creación de la base y las colecciones, inserción de documentos y conteos.
- **Tarea_29_10_2026** — Tarea: carga de la base `saborya` con sus colecciones y datos de prueba.
- **clase_29_10_2026** — Notas de clase: conteos, renombrar y eliminar colecciones, ayuda de comandos y consultas con `find` (operadores de comparación y lógicos, proyección, `sort`, `skip` y `limit`).
- **lab1_gil** — Laboratorio 1 en MongoDB (mongoshell)
---