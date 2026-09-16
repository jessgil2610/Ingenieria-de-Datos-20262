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
└── Segundo Corte/
    ├── Definiciones/
    │   ├── Entornos de trabajo.docx
    │   └── Insercion de datos postgres y SQL.docx
    └── SQL/
        ├── EjercicioMascotas.sql
        ├── EjercicioPostgres.sql
        ├── EjerciciosDDLBiblioteca.sql
        └── ScriptPostgres.sql.txt
```

---

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

- **Entornos de trabajo** — Descripción comparativa de herramientas de bases de datos: MySQL Workbench, XAMPP, Adobe Dreamweaver y PostgreSQL (motor vs. entorno gráfico, para qué sirve cada una).
- **Insercion de datos postgres y SQL** — Cómo insertar datos desde un archivo de texto plano en una tabla ya creada, usando `COPY` en PostgreSQL y sentencias equivalentes en SQL, según el formato y delimitador del archivo.

### SQL

- **EjercicioMascotas** — Script DDL para una base de datos de veterinaria (clientes, teléfonos y llaves foráneas).
- **EjercicioPostgres** / **ScriptPostgres** — Script de creación de la base `tienda_tecno` en PostgreSQL, con tablas de clientes y productos.
- **EjerciciosDDLBiblioteca** — Ejercicios de sentencias DDL para una base de datos de biblioteca (libros y autores).

---
