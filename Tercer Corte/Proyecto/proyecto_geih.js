// =====================================================================
// Proyecto GEIH - Implementación en MongoDB 
// =====================================================================

// 1. Creación y uso de la base de datos
use proyecto_geih
db.dropDatabase();

// 2. Creación de las colecciones según el modelo de BD

// 2.1 Colección Persona
db.createCollection("persona", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["idPersona", "idPeriodo", "idSexo", "edad", "pet", "clase", "area", "factorExpansion"],
      properties: {
        idPersona:       { bsonType: "string", maxLength: 12 },
        idPeriodo:       { bsonType: "number" },
        idSexo:          { bsonType: "number" },
        edad:            { bsonType: "number", minimum: 0, maximum: 120 },
        pet:             { bsonType: "number", enum: [0, 1] },   // población en edad de trabajar (edad >= 15)
        clase:           { bsonType: "number", enum: [1, 2] },
        area:            { bsonType: "number" },
        factorExpansion: { bsonType: "number", exclusiveMinimum: 0 }
      }
    }
  }
});
db.persona.createIndex({ idPersona: 1 }, { unique: true });

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
db.ocupado.createIndex({ idPersona: 1 }, { unique: true });

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
db.desocupado.createIndex({ idPersona: 1 }, { unique: true });

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
db.usuario.createIndex({ idUsuario: 1 }, { unique: true });
db.usuario.createIndex({ correoUsuario: 1 }, { unique: true });

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
db.periodo.createIndex({ idPeriodo: 1 }, { unique: true });
db.periodo.createIndex({ anio: 1, mes: 1 }, { unique: true });

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
db.sexo.createIndex({ idSexo: 1 }, { unique: true });
db.sexo.createIndex({ nombreSexo: 1 }, { unique: true });

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
db.rangoEdad.createIndex({ idRangoEdad: 1 }, { unique: true });
db.rangoEdad.createIndex({ nombreRangoEdad: 1 }, { unique: true });

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
db.territorio.createIndex({ idTerritorio: 1 }, { unique: true });

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
db.ramaActividad.createIndex({ idRamaActividad: 1 }, { unique: true });

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
db.tipoIndicador.createIndex({ idTipoIndicador: 1 }, { unique: true });

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
db.indicador.createIndex({ idIndicador: 1 }, { unique: true });

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
db.auditoriaIndicador.createIndex({ idAuditoria: 1 }, { unique: true });


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
// Nota: los datos de la GEIH ya filtrados (persona_AAAAMM.csv, ocupado_AAAAMM.csv
// y desocupado_AAAAMM.csv) se cargan directamente en MongoDB desde los CSV,
// periodo por periodo. Aquí solo se deja una inserción de ejemplo por colección
// para mostrar la estructura de los documentos.

db.persona.insertMany([
  { idPersona: "84739170102", idPeriodo: 202601, idSexo: 2, edad: 34, pet: 1,
    clase: 1, area: 11, factorExpansion: 245.3812 },
  { idPersona: "84739170103", idPeriodo: 202601, idSexo: 1, edad: 22, pet: 1,
    clase: 1, area: 11, factorExpansion: 245.3812 }
]);

db.ocupado.insertOne({
  idPersona: "84739170102", idRama: 5, horasTrabajo: 48, ingreso: 1750905, cotizaPension: 1
});

db.desocupado.insertOne({
  idPersona: "84739170103"
});

// 3.9 Colección Indicador
// Igual que en SQL, se llena después, cuando se calculen los indicadores
// a partir de persona, ocupado y desocupado.