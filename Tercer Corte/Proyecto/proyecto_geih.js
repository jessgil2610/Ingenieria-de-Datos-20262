// =====================================================================
// Proyecto GEIH - Implementación en MongoDB (script para mongosh)
// =====================================================================

// 1. Creación y uso de la base de datos
// En MongoDB no existe "create database": la base se crea sola cuando
// se crea la primera colección dentro de ella.
use("proyecto_geih");
db.dropDatabase();

// 2. Creación de las colecciones según el modelo de BD
// Nota: MongoDB no tiene llaves foráneas ni auto_increment. Las relaciones
// se guardan por valor (idPeriodo, idSexo, etc.) y los id se asignan en el script.
// Las restricciones check se pasan a validadores $jsonSchema. Los índices
// se crean al final del script (sección 4).

// 2.1 Colección Persona
db.createCollection("persona", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idPersona", "idPeriodo", "idSexo", "edad", "clase", "area", "factorExpansion"],   // pet se calcula después de cargar el CSV
      properties: {
        idPersona:       { bsonType: "string", maxLength: 12 },
        idPeriodo:       { bsonType: "number" },
        idSexo:          { bsonType: "number" },
        edad:            { bsonType: "number", minimum: 0, maximum: 120 },
        pet:             { bsonType: "number", enum: [0, 1] },   // población en edad de trabajar (edad >= 15)
        clase:           { bsonType: "number", enum: [1, 2] },
        area:            { bsonType: "number" },
        factorExpansion: { bsonType: "number", minimum: 0, exclusiveMinimum: true }   // mayor que 0
      }
    }
  }
});

// 2.2 Colección Ocupado
db.createCollection("ocupado", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idPersona", "cotizaPension"],   // idRama, horasTrabajo e ingreso pueden venir vacíos
      properties: {
        idPersona:     { bsonType: "string", maxLength: 12 },
        idRama:        { bsonType: ["number", "null"] },   // null si no sabe, no informa o viene vacía
        horasTrabajo:  { bsonType: ["number", "null"], minimum: 0, maximum: 168 },
        ingreso:       { bsonType: ["number", "null"], minimum: 0 },
        cotizaPension: { bsonType: "number", enum: [0, 1] }
      }
    }
  }
});

// 2.3 Colección Desocupado
db.createCollection("desocupado", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idPersona"],
      properties: {
        idPersona: { bsonType: "string", maxLength: 12 }
      }
    }
  }
});

// 2.4 Colección Usuario
db.createCollection("usuario", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idUsuario", "nombreUsuario", "correoUsuario", "rolUsuario", "activo"],
      properties: {
        idUsuario:     { bsonType: "number" },
        nombreUsuario: { bsonType: "string", maxLength: 100 },
        correoUsuario: { bsonType: "string", maxLength: 150 },
        rolUsuario:    { enum: ["administrador", "ingeniero de datos", "investigador"] },
        activo:        { bsonType: "number", enum: [0, 1] }   // 1 activo, 0 inactivo (el usuario no se elimina)
      }
    }
  }
});

// 2.5 Colección Periodo
db.createCollection("periodo", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idPeriodo", "anio", "mes"],
      properties: {
        idPeriodo: { bsonType: "number" },
        anio:      { bsonType: "number" },
        mes:       { bsonType: "number", minimum: 1, maximum: 12 }
      }
    }
  }
});

// 2.6 Colección Sexo
db.createCollection("sexo", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idSexo", "nombreSexo"],
      properties: {
        idSexo:     { bsonType: "number" },
        nombreSexo: { bsonType: "string", maxLength: 20 }
      }
    }
  }
});

// 2.7 Colección RangoEdad
db.createCollection("rangoEdad", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idRangoEdad", "nombreRangoEdad", "edadInicial", "edadFinal"],
      properties: {
        idRangoEdad:     { bsonType: "number" },
        nombreRangoEdad: { bsonType: "string", maxLength: 20 },
        edadInicial:     { bsonType: "number" },
        edadFinal:       { bsonType: ["number", "null"] }   // es nula en el rango de 60 años o más
      }
    },
    $expr: {
      $or: [
        { $eq: ["$edadFinal", null] },
        { $gte: ["$edadFinal", "$edadInicial"] }
      ]
    }
  }
});

// 2.8 Colección Territorio
db.createCollection("territorio", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idTerritorio", "nombreTerritorio", "tipoTerritorio"],
      properties: {
        idTerritorio:     { bsonType: "number" },
        nombreTerritorio: { bsonType: "string", maxLength: 80 },
        tipoTerritorio:   { enum: ["nacional", "zona", "ciudad"] }
      }
    }
  }
});

// 2.9 Colección RamaActividad
db.createCollection("ramaActividad", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idRamaActividad", "nombreRama"],
      properties: {
        idRamaActividad: { bsonType: "number" },
        nombreRama:      { bsonType: "string", maxLength: 100 }
      }
    }
  }
});

// 2.10 Colección TipoIndicador
db.createCollection("tipoIndicador", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idTipoIndicador", "idPeriodo", "idSexo", "idRangoEdad", "idTerritorio",
                 "idRamaActividad", "nombreIndicador", "formula", "periodicidad"],
      properties: {
        idTipoIndicador: { bsonType: "number" },
        idPeriodo:       { bsonType: "number" },
        idSexo:          { bsonType: ["number", "null"] },
        idRangoEdad:     { bsonType: ["number", "null"] },
        idTerritorio:    { bsonType: ["number", "null"] },
        idRamaActividad: { bsonType: ["number", "null"] },
        nombreIndicador: { bsonType: "string", maxLength: 100 },
        formula:         { bsonType: "string" },
        periodicidad:    { enum: ["mensual", "anual"] }
      }
    }
  }
});

// 2.11 Colección Indicador
db.createCollection("indicador", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idIndicador", "idTipoIndicador", "idUsuario", "valorIndicador",
                 "cvIndicador", "fechaCalculoIndicador"],
      properties: {
        idIndicador:           { bsonType: "number" },
        idTipoIndicador:       { bsonType: "number" },
        idUsuario:             { bsonType: "number" },
        valorIndicador:        { bsonType: "number" },
        cvIndicador:           { bsonType: ["number", "null"], minimum: 0 },   // null si no se puede calcular el cv
        fechaCalculoIndicador: { bsonType: "date" }
      }
    }
  }
});

// 2.12 Colección AuditoriaIndicador
db.createCollection("auditoriaIndicador", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idAuditoria", "idIndicador", "accionAuditoria", "valorAnteriorIndicador",
                 "valorNuevoIndicador", "usuarioBD", "fechaAuditoria"],
      properties: {
        idAuditoria:            { bsonType: "number" },
        idIndicador:            { bsonType: "number" },
        accionAuditoria:        { enum: ["INSERT", "UPDATE", "DELETE"] },
        valorAnteriorIndicador: { bsonType: ["number", "null"] },
        valorNuevoIndicador:    { bsonType: ["number", "null"] },
        usuarioBD:              { bsonType: "string", maxLength: 100 },
        fechaAuditoria:         { bsonType: "date" }
      }
    }
  }
});


// 3. Inserciones en las colecciones

// 3.1 Colección Usuario (idUsuario se asigna en orden, como el auto_increment)
const usuarios = [
  { nombreUsuario: "Mariana Vargas", correoUsuario: "mariana@example.com", rolUsuario: "administrador", activo: 1 },
  { nombreUsuario: "Jessica Tellez", correoUsuario: "jessica@example.com", rolUsuario: "ingeniero de datos", activo: 1 },
  { nombreUsuario: "Jorge Díaz", correoUsuario: "jorge@example.com", rolUsuario: "ingeniero de datos", activo: 1 },
  { nombreUsuario: "Lina Parra", correoUsuario: "lina@example.com", rolUsuario: "ingeniero de datos", activo: 1 },
  { nombreUsuario: "Camila Ramírez Moreno", correoUsuario: "camila.ramirez01@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Andrés Cárdenas Peña", correoUsuario: "andres.cardenas02@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Valentina Rincón Torres", correoUsuario: "valentina.rincon03@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Santiago Montoya Quintero", correoUsuario: "santiago.montoya04@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Daniela Herrera Montoya", correoUsuario: "daniela.herrera05@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Sebastián Quintero Cárdenas", correoUsuario: "sebastian.quintero06@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Laura Suárez Ibáñez", correoUsuario: "laura.suarez07@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Juan Torres Vargas", correoUsuario: "juan.torres08@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Paula Mejía Duarte", correoUsuario: "paula.mejia09@example.com", rolUsuario: "investigador", activo: 0 },
  { nombreUsuario: "Felipe Peña Castro", correoUsuario: "felipe.pena10@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Natalia Franco Acosta", correoUsuario: "natalia.franco11@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "David Moreno Gómez", correoUsuario: "david.moreno12@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Carolina Salazar Salazar", correoUsuario: "carolina.salazar13@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Mateo Cortés Franco", correoUsuario: "mateo.cortes14@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Isabella Gómez Mejía", correoUsuario: "isabella.gomez15@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Nicolás Ortiz Suárez", correoUsuario: "nicolas.ortiz16@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Sofía Acosta Herrera", correoUsuario: "sofia.acosta17@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Daniel Lozano Rincón", correoUsuario: "daniel.lozano18@example.com", rolUsuario: "investigador", activo: 0 },
  { nombreUsuario: "María Castro Ramírez", correoUsuario: "maria.castro19@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Alejandro Pineda Beltrán", correoUsuario: "alejandro.pineda20@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Luisa Duarte Rojas", correoUsuario: "luisa.duarte21@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Tomás Rojas Pineda", correoUsuario: "tomas.rojas22@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Juliana Vargas Lozano", correoUsuario: "juliana.vargas23@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Esteban Beltrán Ortiz", correoUsuario: "esteban.beltran24@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Manuela Ibáñez Cortés", correoUsuario: "manuela.ibanez25@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Camila Ramírez Moreno", correoUsuario: "camila.ramirez26@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Andrés Cárdenas Peña", correoUsuario: "andres.cardenas27@example.com", rolUsuario: "investigador", activo: 0 },
  { nombreUsuario: "Valentina Rincón Torres", correoUsuario: "valentina.rincon28@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Santiago Montoya Quintero", correoUsuario: "santiago.montoya29@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Daniela Herrera Montoya", correoUsuario: "daniela.herrera30@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Sebastián Quintero Cárdenas", correoUsuario: "sebastian.quintero31@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Laura Suárez Ibáñez", correoUsuario: "laura.suarez32@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Juan Torres Vargas", correoUsuario: "juan.torres33@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Paula Mejía Duarte", correoUsuario: "paula.mejia34@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Felipe Peña Castro", correoUsuario: "felipe.pena35@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Natalia Franco Acosta", correoUsuario: "natalia.franco36@example.com", rolUsuario: "investigador", activo: 0 },
  { nombreUsuario: "David Moreno Gómez", correoUsuario: "david.moreno37@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Carolina Salazar Salazar", correoUsuario: "carolina.salazar38@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Mateo Cortés Franco", correoUsuario: "mateo.cortes39@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Isabella Gómez Mejía", correoUsuario: "isabella.gomez40@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Nicolás Ortiz Suárez", correoUsuario: "nicolas.ortiz41@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Sofía Acosta Herrera", correoUsuario: "sofia.acosta42@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Daniel Lozano Rincón", correoUsuario: "daniel.lozano43@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "María Castro Ramírez", correoUsuario: "maria.castro44@example.com", rolUsuario: "investigador", activo: 1 },
  { nombreUsuario: "Alejandro Pineda Beltrán", correoUsuario: "alejandro.pineda45@example.com", rolUsuario: "investigador", activo: 0 },
  { nombreUsuario: "Luisa Duarte Rojas", correoUsuario: "luisa.duarte46@example.com", rolUsuario: "investigador", activo: 1 }
];
db.usuario.insertMany(usuarios.map((u, i) => ({ idUsuario: i + 1, ...u })));

// 3.2 Colección Periodo (enero de 2022 a octubre de 2026)
const periodos = [];
for (let anio = 2022; anio <= 2026; anio++) {
  const ultimoMes = (anio === 2026) ? 10 : 12;
  for (let mes = 1; mes <= ultimoMes; mes++) {
    periodos.push({ idPeriodo: anio * 100 + mes, anio: anio, mes: mes });
  }
}
db.periodo.insertMany(periodos);

// 3.3 Colección Sexo
db.sexo.insertMany([
  { idSexo: 1, nombreSexo: "Hombre" },
  { idSexo: 2, nombreSexo: "Mujer" }
]);

// 3.4 Colección RangoEdad
db.rangoEdad.insertMany([
  { idRangoEdad: 1, nombreRangoEdad: "15-17",    edadInicial: 15, edadFinal: 17 },
  { idRangoEdad: 2, nombreRangoEdad: "18-28",    edadInicial: 18, edadFinal: 28 },
  { idRangoEdad: 3, nombreRangoEdad: "29-44",    edadInicial: 29, edadFinal: 44 },
  { idRangoEdad: 4, nombreRangoEdad: "45-59",    edadInicial: 45, edadFinal: 59 },
  { idRangoEdad: 5, nombreRangoEdad: "60 o más", edadInicial: 60, edadFinal: null }
]);

// 3.5 Colección Territorio
db.territorio.insertMany([
  { idTerritorio: 3,  nombreTerritorio: "Nacional",            tipoTerritorio: "nacional" },
  { idTerritorio: 1,  nombreTerritorio: "Urbano",              tipoTerritorio: "zona" },
  { idTerritorio: 2,  nombreTerritorio: "Resto",               tipoTerritorio: "zona" },
  { idTerritorio: 11, nombreTerritorio: "Bogotá D.C.",         tipoTerritorio: "ciudad" },
  { idTerritorio: 5,  nombreTerritorio: "Medellín y A.M.",     tipoTerritorio: "ciudad" },
  { idTerritorio: 76, nombreTerritorio: "Cali y A.M.",         tipoTerritorio: "ciudad" },
  { idTerritorio: 8,  nombreTerritorio: "Barranquilla y A.M.", tipoTerritorio: "ciudad" },
  { idTerritorio: 68, nombreTerritorio: "Bucaramanga y A.M.",  tipoTerritorio: "ciudad" },
  { idTerritorio: 17, nombreTerritorio: "Manizales y A.M.",    tipoTerritorio: "ciudad" },
  { idTerritorio: 66, nombreTerritorio: "Pereira y A.M.",      tipoTerritorio: "ciudad" },
  { idTerritorio: 54, nombreTerritorio: "Cúcuta y A.M.",       tipoTerritorio: "ciudad" },
  { idTerritorio: 52, nombreTerritorio: "Pasto",               tipoTerritorio: "ciudad" },
  { idTerritorio: 73, nombreTerritorio: "Ibagué",              tipoTerritorio: "ciudad" },
  { idTerritorio: 23, nombreTerritorio: "Montería",            tipoTerritorio: "ciudad" },
  { idTerritorio: 13, nombreTerritorio: "Cartagena",           tipoTerritorio: "ciudad" },
  { idTerritorio: 50, nombreTerritorio: "Villavicencio",       tipoTerritorio: "ciudad" }
]);

// 3.6 Colección RamaActividad
db.ramaActividad.insertMany([
  { idRamaActividad: 1,  nombreRama: "Agricultura, ganadería, caza, silvicultura y pesca" },
  { idRamaActividad: 2,  nombreRama: "Suministro de electricidad, gas, agua y gestión de desechos" },
  { idRamaActividad: 3,  nombreRama: "Industrias manufactureras" },
  { idRamaActividad: 4,  nombreRama: "Construcción" },
  { idRamaActividad: 5,  nombreRama: "Comercio y reparación de vehículos" },
  { idRamaActividad: 6,  nombreRama: "Alojamiento y servicios de comida" },
  { idRamaActividad: 7,  nombreRama: "Transporte y almacenamiento" },
  { idRamaActividad: 8,  nombreRama: "Información y comunicaciones" },
  { idRamaActividad: 9,  nombreRama: "Actividades financieras y de seguros" },
  { idRamaActividad: 10, nombreRama: "Actividades inmobiliarias" },
  { idRamaActividad: 11, nombreRama: "Actividades profesionales, científicas, técnicas y servicios administrativos" },
  { idRamaActividad: 12, nombreRama: "Administración pública y defensa, educación y atención de la salud humana" },
  { idRamaActividad: 13, nombreRama: "Actividades artísticas, entretenimiento, recreación y otras actividades de servicios" }
]);

// 3.7 Colección TipoIndicador
// Se arman los mismos 130 documentos del script SQL, en el mismo orden:
// 7 indicadores x 13 desagregaciones, y luego 3 indicadores x 13 ramas.
const indicadores = [
  { nombre: "PEA",                  formula: "Suma del factor de expansión de ocupados y desocupados" },
  { nombre: "TGP",                  formula: "PEA / PET x 100" },
  { nombre: "Tasa de ocupación",    formula: "Ocupados / PET x 100" },
  { nombre: "Tasa de desocupación", formula: "Desocupados / PEA x 100" },
  { nombre: "Salario promedio",     formula: "Promedio del ingreso laboral de los ocupados, ponderado por el factor de expansión" },
  { nombre: "Horas trabajadas",     formula: "Promedio de horas semanales trabajadas por los ocupados, ponderado por el factor de expansión" },
  { nombre: "Tasa de informalidad", formula: "Ocupados que no cotizan a pensión / ocupados x 100" }
];

const desagregaciones = [
  { idSexo: null, idRangoEdad: null, idTerritorio: 3 },    // nacional
  { idSexo: 1,    idRangoEdad: null, idTerritorio: 3 },    // hombres
  { idSexo: 2,    idRangoEdad: null, idTerritorio: 3 },    // mujeres
  { idSexo: null, idRangoEdad: null, idTerritorio: 1 },    // urbano
  { idSexo: null, idRangoEdad: null, idTerritorio: 2 },    // resto
  { idSexo: null, idRangoEdad: null, idTerritorio: 11 },   // Bogotá
  { idSexo: null, idRangoEdad: null, idTerritorio: 5 },    // Medellín
  { idSexo: null, idRangoEdad: null, idTerritorio: 76 },   // Cali
  { idSexo: null, idRangoEdad: 1,    idTerritorio: 3 },    // 15-17
  { idSexo: null, idRangoEdad: 2,    idTerritorio: 3 },    // 18-28
  { idSexo: null, idRangoEdad: 3,    idTerritorio: 3 },    // 29-44
  { idSexo: null, idRangoEdad: 4,    idTerritorio: 3 },    // 45-59
  { idSexo: null, idRangoEdad: 5,    idTerritorio: 3 }     // 60 o más
];

const tiposIndicador = [];
let idTipo = 1;

for (const ind of indicadores) {
  for (const d of desagregaciones) {
    tiposIndicador.push({
      idTipoIndicador: idTipo++, idPeriodo: 202601,
      idSexo: d.idSexo, idRangoEdad: d.idRangoEdad, idTerritorio: d.idTerritorio, idRamaActividad: null,
      nombreIndicador: ind.nombre, formula: ind.formula, periodicidad: "mensual"
    });
  }
}

// Indicadores por rama (solo salario, horas e informalidad, a nivel nacional)
for (const ind of indicadores.slice(4)) {
  for (let rama = 1; rama <= 13; rama++) {
    tiposIndicador.push({
      idTipoIndicador: idTipo++, idPeriodo: 202601,
      idSexo: null, idRangoEdad: null, idTerritorio: 3, idRamaActividad: rama,
      nombreIndicador: ind.nombre, formula: ind.formula, periodicidad: "mensual"
    });
  }
}
db.tipoIndicador.insertMany(tiposIndicador);


// 3.8 Colecciones Persona, Ocupado y Desocupado
// Nota: en la base real los datos de la GEIH ya filtrados (persona_AAAAMM.csv,
// ocupado_AAAAMM.csv y desocupado_AAAAMM.csv) se cargan directamente en MongoDB
// desde los CSV. Para el taller se usan datos inventados: 25 personas por periodo
// (enero y febrero de 2026), con sus ocupados y desocupados.
// idPersona = directorio (7) + secuencia_p (2) + orden (2)

// 3.8.1 Persona
db.persona.insertMany([
  { idPersona: "84739110101", idPeriodo: 202601, idSexo: 1, edad: 67, pet: 1, clase: 2, area: 41, factorExpansion: 151.7024 },
  { idPersona: "84739110102", idPeriodo: 202601, idSexo: 1, edad: 42, pet: 1, clase: 2, area: 41, factorExpansion: 151.7024 },
  { idPersona: "84739110103", idPeriodo: 202601, idSexo: 1, edad: 15, pet: 1, clase: 2, area: 41, factorExpansion: 151.7024 },
  { idPersona: "84739110104", idPeriodo: 202601, idSexo: 1, edad: 12, pet: 0, clase: 2, area: 41, factorExpansion: 151.7024 },
  { idPersona: "84739120101", idPeriodo: 202601, idSexo: 1, edad: 63, pet: 1, clase: 1, area: 5, factorExpansion: 151.1924 },
  { idPersona: "84739120102", idPeriodo: 202601, idSexo: 2, edad: 71, pet: 1, clase: 1, area: 5, factorExpansion: 151.1924 },
  { idPersona: "84739120103", idPeriodo: 202601, idSexo: 1, edad: 56, pet: 1, clase: 1, area: 5, factorExpansion: 151.1924 },
  { idPersona: "84739130101", idPeriodo: 202601, idSexo: 1, edad: 71, pet: 1, clase: 1, area: 11, factorExpansion: 324.7258 },
  { idPersona: "84739130102", idPeriodo: 202601, idSexo: 1, edad: 71, pet: 1, clase: 1, area: 11, factorExpansion: 324.7258 },
  { idPersona: "84739130103", idPeriodo: 202601, idSexo: 1, edad: 53, pet: 1, clase: 1, area: 11, factorExpansion: 324.7258 },
  { idPersona: "84739140101", idPeriodo: 202601, idSexo: 2, edad: 51, pet: 1, clase: 2, area: 73, factorExpansion: 244.9787 },
  { idPersona: "84739140102", idPeriodo: 202601, idSexo: 2, edad: 43, pet: 1, clase: 2, area: 73, factorExpansion: 244.9787 },
  { idPersona: "84739140103", idPeriodo: 202601, idSexo: 1, edad: 9, pet: 0, clase: 2, area: 73, factorExpansion: 244.9787 },
  { idPersona: "84739140104", idPeriodo: 202601, idSexo: 1, edad: 21, pet: 1, clase: 2, area: 73, factorExpansion: 244.9787 },
  { idPersona: "84739150101", idPeriodo: 202601, idSexo: 2, edad: 21, pet: 1, clase: 1, area: 76, factorExpansion: 201.2551 },
  { idPersona: "84739150102", idPeriodo: 202601, idSexo: 2, edad: 58, pet: 1, clase: 1, area: 76, factorExpansion: 201.2551 },
  { idPersona: "84739150103", idPeriodo: 202601, idSexo: 2, edad: 17, pet: 1, clase: 1, area: 76, factorExpansion: 201.2551 },
  { idPersona: "84739150104", idPeriodo: 202601, idSexo: 1, edad: 36, pet: 1, clase: 1, area: 76, factorExpansion: 201.2551 },
  { idPersona: "84739160101", idPeriodo: 202601, idSexo: 1, edad: 54, pet: 1, clase: 1, area: 11, factorExpansion: 320.6692 },
  { idPersona: "84739160102", idPeriodo: 202601, idSexo: 1, edad: 65, pet: 1, clase: 1, area: 11, factorExpansion: 320.6692 },
  { idPersona: "84739160103", idPeriodo: 202601, idSexo: 1, edad: 13, pet: 0, clase: 1, area: 11, factorExpansion: 320.6692 },
  { idPersona: "84739170101", idPeriodo: 202601, idSexo: 1, edad: 48, pet: 1, clase: 1, area: 11, factorExpansion: 483.9179 },
  { idPersona: "84739170102", idPeriodo: 202601, idSexo: 2, edad: 52, pet: 1, clase: 1, area: 11, factorExpansion: 483.9179 },
  { idPersona: "84739170103", idPeriodo: 202601, idSexo: 2, edad: 41, pet: 1, clase: 1, area: 11, factorExpansion: 483.9179 },
  { idPersona: "84739170104", idPeriodo: 202601, idSexo: 2, edad: 6, pet: 0, clase: 1, area: 11, factorExpansion: 483.9179 },
  { idPersona: "84812510101", idPeriodo: 202602, idSexo: 2, edad: 24, pet: 1, clase: 1, area: 11, factorExpansion: 278.3804 },
  { idPersona: "84812510102", idPeriodo: 202602, idSexo: 2, edad: 25, pet: 1, clase: 1, area: 11, factorExpansion: 278.3804 },
  { idPersona: "84812520101", idPeriodo: 202602, idSexo: 2, edad: 33, pet: 1, clase: 1, area: 17, factorExpansion: 189.268 },
  { idPersona: "84812520102", idPeriodo: 202602, idSexo: 1, edad: 48, pet: 1, clase: 1, area: 17, factorExpansion: 189.268 },
  { idPersona: "84812520103", idPeriodo: 202602, idSexo: 2, edad: 16, pet: 1, clase: 1, area: 17, factorExpansion: 189.268 },
  { idPersona: "84812530101", idPeriodo: 202602, idSexo: 2, edad: 28, pet: 1, clase: 1, area: 11, factorExpansion: 219.9179 },
  { idPersona: "84812530102", idPeriodo: 202602, idSexo: 1, edad: 43, pet: 1, clase: 1, area: 11, factorExpansion: 219.9179 },
  { idPersona: "84812530103", idPeriodo: 202602, idSexo: 2, edad: 10, pet: 0, clase: 1, area: 11, factorExpansion: 219.9179 },
  { idPersona: "84812540101", idPeriodo: 202602, idSexo: 2, edad: 28, pet: 1, clase: 1, area: 11, factorExpansion: 507.4388 },
  { idPersona: "84812540102", idPeriodo: 202602, idSexo: 2, edad: 58, pet: 1, clase: 1, area: 11, factorExpansion: 507.4388 },
  { idPersona: "84812550101", idPeriodo: 202602, idSexo: 1, edad: 24, pet: 1, clase: 1, area: 76, factorExpansion: 305.098 },
  { idPersona: "84812550102", idPeriodo: 202602, idSexo: 1, edad: 44, pet: 1, clase: 1, area: 76, factorExpansion: 305.098 },
  { idPersona: "84812550103", idPeriodo: 202602, idSexo: 2, edad: 15, pet: 1, clase: 1, area: 76, factorExpansion: 305.098 },
  { idPersona: "84812550104", idPeriodo: 202602, idSexo: 2, edad: 61, pet: 1, clase: 1, area: 76, factorExpansion: 305.098 },
  { idPersona: "84812560101", idPeriodo: 202602, idSexo: 2, edad: 46, pet: 1, clase: 2, area: 5, factorExpansion: 273.2294 },
  { idPersona: "84812560102", idPeriodo: 202602, idSexo: 2, edad: 48, pet: 1, clase: 2, area: 5, factorExpansion: 273.2294 },
  { idPersona: "84812560103", idPeriodo: 202602, idSexo: 1, edad: 12, pet: 0, clase: 2, area: 5, factorExpansion: 273.2294 },
  { idPersona: "84812570101", idPeriodo: 202602, idSexo: 2, edad: 26, pet: 1, clase: 2, area: 73, factorExpansion: 465.6404 },
  { idPersona: "84812570102", idPeriodo: 202602, idSexo: 1, edad: 63, pet: 1, clase: 2, area: 73, factorExpansion: 465.6404 },
  { idPersona: "84812570103", idPeriodo: 202602, idSexo: 1, edad: 58, pet: 1, clase: 2, area: 73, factorExpansion: 465.6404 },
  { idPersona: "84812580101", idPeriodo: 202602, idSexo: 1, edad: 67, pet: 1, clase: 1, area: 11, factorExpansion: 147.8016 },
  { idPersona: "84812580102", idPeriodo: 202602, idSexo: 1, edad: 69, pet: 1, clase: 1, area: 11, factorExpansion: 147.8016 },
  { idPersona: "84812580103", idPeriodo: 202602, idSexo: 2, edad: 51, pet: 1, clase: 1, area: 11, factorExpansion: 147.8016 },
  { idPersona: "84812590101", idPeriodo: 202602, idSexo: 2, edad: 70, pet: 1, clase: 2, area: 5, factorExpansion: 231.1919 },
  { idPersona: "84812590102", idPeriodo: 202602, idSexo: 2, edad: 50, pet: 1, clase: 2, area: 5, factorExpansion: 231.1919 }
]);

// 3.8.2 Ocupado (ingreso o idRama en null cuando la persona no informa)
db.ocupado.insertMany([
  { idPersona: "84739120101", idRama: 8, horasTrabajo: 48, ingreso: 964669, cotizaPension: 0 },
  { idPersona: "84739120103", idRama: 3, horasTrabajo: 48, ingreso: 2116066, cotizaPension: 1 },
  { idPersona: "84739130102", idRama: 12, horasTrabajo: 48, ingreso: 947775, cotizaPension: 0 },
  { idPersona: "84739130103", idRama: 12, horasTrabajo: 53, ingreso: 1790556, cotizaPension: 0 },
  { idPersona: "84739140101", idRama: 5, horasTrabajo: 40, ingreso: null, cotizaPension: 1 },
  { idPersona: "84739140102", idRama: 1, horasTrabajo: 48, ingreso: 1771120, cotizaPension: 0 },
  { idPersona: "84739140104", idRama: 1, horasTrabajo: 27, ingreso: 787048, cotizaPension: 0 },
  { idPersona: "84739150101", idRama: 13, horasTrabajo: 48, ingreso: 2108738, cotizaPension: 1 },
  { idPersona: "84739150102", idRama: 12, horasTrabajo: 40, ingreso: 559062, cotizaPension: 0 },
  { idPersona: "84739150104", idRama: 11, horasTrabajo: 48, ingreso: 5387974, cotizaPension: 1 },
  { idPersona: "84739160101", idRama: 1, horasTrabajo: 55, ingreso: 3450088, cotizaPension: 1 },
  { idPersona: "84739170101", idRama: 8, horasTrabajo: 48, ingreso: 2074020, cotizaPension: 1 },
  { idPersona: "84812510102", idRama: 1, horasTrabajo: 48, ingreso: 5551755, cotizaPension: 1 },
  { idPersona: "84812530101", idRama: 5, horasTrabajo: 27, ingreso: 1801077, cotizaPension: 0 },
  { idPersona: "84812530102", idRama: 11, horasTrabajo: 40, ingreso: null, cotizaPension: 1 },
  { idPersona: "84812550102", idRama: 5, horasTrabajo: 48, ingreso: 2587742, cotizaPension: 1 },
  { idPersona: "84812550103", idRama: 5, horasTrabajo: 48, ingreso: 827110, cotizaPension: 0 },
  { idPersona: "84812560102", idRama: null, horasTrabajo: 48, ingreso: 1403519, cotizaPension: 0 },
  { idPersona: "84812570102", idRama: 6, horasTrabajo: 48, ingreso: 5032474, cotizaPension: 1 },
  { idPersona: "84812580103", idRama: 7, horasTrabajo: 40, ingreso: 1402526, cotizaPension: 0 }
]);

// 3.8.3 Desocupado
db.desocupado.insertMany([
  { idPersona: "84739110102" },
  { idPersona: "84739170102" },
  { idPersona: "84812520102" },
  { idPersona: "84812560101" }
]);

// Cálculo de pet (población en edad de trabajar) para los datos que se
// importen desde los CSV, que no traen esta columna. Reemplaza la columna
// generada del SQL: 1 si la edad es 15 o más, 0 si no.
db.persona.updateMany(
  { pet: { $exists: false } },
  [ { $set: { pet: { $cond: [ { $gte: ["$edad", 15] }, 1, 0 ] } } } ]
);

// 3.9 Colección Indicador
// Datos de taller: los 7 indicadores de enero de 2026 para nacional, hombres,
// mujeres, urbano y resto (idTipoIndicador según el orden de la sección 3.7).
// Los valores salen de los datos inventados de persona, ocupado y desocupado;
// el cv es inventado.
db.indicador.insertMany([
  { idIndicador: 1, idTipoIndicador: 1, idUsuario: 3, valorIndicador: 3730.7452, cvIndicador: 4.3158, fechaCalculoIndicador: new Date("2026-03-05") },
  { idIndicador: 2, idTipoIndicador: 2, idUsuario: 2, valorIndicador: 2354.3597, cvIndicador: 3.0121, fechaCalculoIndicador: new Date("2026-03-03") },
  { idIndicador: 3, idTipoIndicador: 3, idUsuario: 2, valorIndicador: 1376.3855, cvIndicador: 2.7251, fechaCalculoIndicador: new Date("2026-03-06") },
  { idIndicador: 4, idTipoIndicador: 4, idUsuario: 2, valorIndicador: 2844.1067, cvIndicador: 5.4074, fechaCalculoIndicador: new Date("2026-03-06") },
  { idIndicador: 5, idTipoIndicador: 5, idUsuario: 4, valorIndicador: 886.6385, cvIndicador: 5.7181, fechaCalculoIndicador: new Date("2026-03-06") },
  { idIndicador: 6, idTipoIndicador: 14, idUsuario: 4, valorIndicador: 67.6361, cvIndicador: 3.2914, fechaCalculoIndicador: new Date("2026-03-02") },
  { idIndicador: 7, idTipoIndicador: 15, idUsuario: 3, valorIndicador: 71.276, cvIndicador: 1.5826, fechaCalculoIndicador: new Date("2026-03-04") },
  { idIndicador: 8, idTipoIndicador: 16, idUsuario: 4, valorIndicador: 62.2025, cvIndicador: 2.4328, fechaCalculoIndicador: new Date("2026-03-02") },
  { idIndicador: 9, idTipoIndicador: 17, idUsuario: 3, valorIndicador: 65.7465, cvIndicador: 8.7427, fechaCalculoIndicador: new Date("2026-03-06") },
  { idIndicador: 10, idTipoIndicador: 18, idUsuario: 4, valorIndicador: 74.5047, cvIndicador: 7.674, fechaCalculoIndicador: new Date("2026-03-02") },
  { idIndicador: 11, idTipoIndicador: 27, idUsuario: 2, valorIndicador: 56.1127, cvIndicador: 3.925, fechaCalculoIndicador: new Date("2026-03-02") },
  { idIndicador: 12, idTipoIndicador: 28, idUsuario: 4, valorIndicador: 66.6833, cvIndicador: 2.8602, fechaCalculoIndicador: new Date("2026-03-06") },
  { idIndicador: 13, idTipoIndicador: 29, idUsuario: 2, valorIndicador: 40.3329, cvIndicador: 3.5922, fechaCalculoIndicador: new Date("2026-03-03") },
  { idIndicador: 14, idTipoIndicador: 30, idUsuario: 3, valorIndicador: 54.5599, cvIndicador: 3.5395, fechaCalculoIndicador: new Date("2026-03-05") },
  { idIndicador: 15, idTipoIndicador: 31, idUsuario: 2, valorIndicador: 61.7571, cvIndicador: 2.9536, fechaCalculoIndicador: new Date("2026-03-06") },
  { idIndicador: 16, idTipoIndicador: 40, idUsuario: 2, valorIndicador: 17.0374, cvIndicador: 1.466, fechaCalculoIndicador: new Date("2026-03-02") },
  { idIndicador: 17, idTipoIndicador: 41, idUsuario: 4, valorIndicador: 6.4435, cvIndicador: 1.1027, fechaCalculoIndicador: new Date("2026-03-04") },
  { idIndicador: 18, idTipoIndicador: 42, idUsuario: 4, valorIndicador: 35.1586, cvIndicador: 2.7245, fechaCalculoIndicador: new Date("2026-03-03") },
  { idIndicador: 19, idTipoIndicador: 43, idUsuario: 2, valorIndicador: 17.0148, cvIndicador: 3.2813, fechaCalculoIndicador: new Date("2026-03-03") },
  { idIndicador: 20, idTipoIndicador: 44, idUsuario: 3, valorIndicador: 17.1098, cvIndicador: 8.9334, fechaCalculoIndicador: new Date("2026-03-04") },
  { idIndicador: 21, idTipoIndicador: 53, idUsuario: 4, valorIndicador: 2004439.3084, cvIndicador: 4.032, fechaCalculoIndicador: new Date("2026-03-05") },
  { idIndicador: 22, idTipoIndicador: 54, idUsuario: 3, valorIndicador: 2152922.312, cvIndicador: 1.7527, fechaCalculoIndicador: new Date("2026-03-02") },
  { idIndicador: 23, idTipoIndicador: 55, idUsuario: 3, valorIndicador: 1499323.0477, cvIndicador: 0.868, fechaCalculoIndicador: new Date("2026-03-02") },
  { idIndicador: 24, idTipoIndicador: 56, idUsuario: 2, valorIndicador: 2155017.6015, cvIndicador: 2.9717, fechaCalculoIndicador: new Date("2026-03-03") },
  { idIndicador: 25, idTipoIndicador: 57, idUsuario: 3, valorIndicador: 1279084.0, cvIndicador: 12.0607, fechaCalculoIndicador: new Date("2026-03-05") },
  { idIndicador: 26, idTipoIndicador: 66, idUsuario: 4, valorIndicador: 46.4343, cvIndicador: 2.6664, fechaCalculoIndicador: new Date("2026-03-05") },
  { idIndicador: 27, idTipoIndicador: 67, idUsuario: 4, valorIndicador: 47.4206, cvIndicador: 4.1173, fechaCalculoIndicador: new Date("2026-03-05") },
  { idIndicador: 28, idTipoIndicador: 68, idUsuario: 2, valorIndicador: 44.0, cvIndicador: 2.2819, fechaCalculoIndicador: new Date("2026-03-02") },
  { idIndicador: 29, idTipoIndicador: 69, idUsuario: 3, valorIndicador: 48.9568, cvIndicador: 2.7736, fechaCalculoIndicador: new Date("2026-03-05") },
  { idIndicador: 30, idTipoIndicador: 70, idUsuario: 2, valorIndicador: 38.3333, cvIndicador: 10.9879, fechaCalculoIndicador: new Date("2026-03-06") },
  { idIndicador: 31, idTipoIndicador: 79, idUsuario: 3, valorIndicador: 48.2002, cvIndicador: 0.8631, fechaCalculoIndicador: new Date("2026-03-06") },
  { idIndicador: 32, idTipoIndicador: 80, idUsuario: 4, valorIndicador: 47.471, cvIndicador: 1.0482, fechaCalculoIndicador: new Date("2026-03-03") },
  { idIndicador: 33, idTipoIndicador: 81, idUsuario: 3, valorIndicador: 50.0, cvIndicador: 1.91, fechaCalculoIndicador: new Date("2026-03-03") },
  { idIndicador: 34, idTipoIndicador: 82, idUsuario: 4, valorIndicador: 42.45, cvIndicador: 6.7712, fechaCalculoIndicador: new Date("2026-03-06") },
  { idIndicador: 35, idTipoIndicador: 83, idUsuario: 2, valorIndicador: 66.6667, cvIndicador: 7.1886, fechaCalculoIndicador: new Date("2026-03-03") }
]);


// 4. Índices
// Se crean sobre los campos que más se usan para consultar y calcular
// los indicadores. Los únicos reemplazan las llaves primarias del SQL.

// 4.1 Persona por periodo: todos los cálculos filtran por mes
db.persona.createIndex({ idPeriodo: 1 });

// 4.2 Persona por idPersona: cruce con ocupado y desocupado
db.persona.createIndex({ idPersona: 1 }, { unique: true });

// 4.3 Ocupado por idPersona: cruce con persona
db.ocupado.createIndex({ idPersona: 1 }, { unique: true });

// 4.4 TipoIndicador por nombre y periodo: buscar un indicador en un mes
db.tipoIndicador.createIndex({ nombreIndicador: 1, idPeriodo: 1 });

// 4.5 Indicador por tipo y fecha de cálculo: traer el último cálculo
db.indicador.createIndex({ idTipoIndicador: 1, fechaCalculoIndicador: -1 });

// Verificación de los índices creados
db.persona.getIndexes();
db.ocupado.getIndexes();
db.tipoIndicador.getIndexes();
db.indicador.getIndexes();


// 5. Historial
// Cada colección de historial guarda la versión anterior de un documento
// antes de modificarlo. Como mongosh no tiene triggers, la copia se inserta
// justo antes de cada updateOne.

// 5.1 Historial de Indicador (cambios en el valor o el cv)
db.createCollection("indicador_historico");
db.indicador_historico.createIndex({ idIndicador: 1, fechaHistorico: -1 });

// Ejemplo: se recalcula la tasa de ocupación nacional (idIndicador 11)
const indicadorAnterior = db.indicador.findOne({ idIndicador: 11 });
db.indicador_historico.insertOne({
  idIndicador: indicadorAnterior.idIndicador,
  valorAnterior: indicadorAnterior.valorIndicador,
  cvAnterior: indicadorAnterior.cvIndicador,
  accion: "UPDATE",
  fechaHistorico: new Date()
});
db.indicador.updateOne(
  { idIndicador: 11 },
  { $set: { valorIndicador: 56.4254, cvIndicador: 3.9036, fechaCalculoIndicador: new Date() } }
);

// 5.2 Historial de Usuario (inactivación o cambio de rol)
db.createCollection("usuario_historico");
db.usuario_historico.createIndex({ idUsuario: 1, fechaHistorico: -1 });

// Ejemplo: se inactiva un usuario
const usuarioAnterior = db.usuario.findOne({ idUsuario: 5 });
db.usuario_historico.insertOne({
  idUsuario: usuarioAnterior.idUsuario,
  rolAnterior: usuarioAnterior.rolUsuario,
  activoAnterior: usuarioAnterior.activo,
  accion: "UPDATE",
  fechaHistorico: new Date()
});
db.usuario.updateOne({ idUsuario: 5 }, { $set: { activo: 0 } });

// 5.3 Historial de TipoIndicador (cambio en la fórmula o definición)
db.createCollection("tipoIndicador_historico");
db.tipoIndicador_historico.createIndex({ idTipoIndicador: 1, fechaHistorico: -1 });

// Ejemplo: se ajusta la fórmula de la tasa de informalidad nacional
const tipoAnterior = db.tipoIndicador.findOne({ idTipoIndicador: 79 });
db.tipoIndicador_historico.insertOne({
  idTipoIndicador: tipoAnterior.idTipoIndicador,
  formulaAnterior: tipoAnterior.formula,
  accion: "UPDATE",
  fechaHistorico: new Date()
});
db.tipoIndicador.updateOne(
  { idTipoIndicador: 79 },
  { $set: { formula: "Ocupados que no cotizan a pensión / total de ocupados x 100, ponderado por el factor de expansión" } }
);

// Consulta del historial: cambios más recientes primero
db.indicador_historico.find().sort({ fechaHistorico: -1 });
db.usuario_historico.find().sort({ fechaHistorico: -1 });
db.tipoIndicador_historico.find().sort({ fechaHistorico: -1 });