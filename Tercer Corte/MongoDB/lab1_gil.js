// Laboratorio 1- Jessica Gil - Mongo DB
// A1. Comprobación
show databases
use saborya
show collections

// A2. Conteo de documentos
db.clientes.countDocuments()
// Resultado: 9 clientes
db.pedidos.countDocuments()
// Resultado: 20 pedidos
db.productos.countDocuments()
// 24 productos
db.restaurante.countDocuments()
// Resultado: 10 restaurantes

// A3. Insertar restaurante
db.restaurante.insertOne({ _id: "R11", nombre: "Café Arriero", categoria: "Cafetería", ciudad: "Medellín", barrio: "Laureles", calificacion: 4.5, domicilio: true, ubicacion: { type: "Point", coordinates: [-75.5925, 6.2442] }, etiquetas: ["café", "postres"]})

// A4. Insertar dos productos
db.productos.insertMany([
  { _id: "P25", restaurante_id: "R11", nombre: "Tinto campesion", tipo: "bebida", precio: 3500, stock: 100, disponible: true, descripcion: "Tinto campesino con canela y panela", volumen_ml: 200},{ _id: "P26", restaurante_id: "R11", nombre: "Torta de zanahoria", tipo: "postre", precio: 9000, stock: 20, disponible: true, descripcion: "Torta de zanahoria grande" }])

// A5. Mostrar los restaurantes de medellin y contar los productos del R11
db.restaurante.find({ ciudad: "Medellín" })
// Resultado: 4 restaurantes
db.productos.countDocuments({ restaurante_id: "R11" })
// Resultado: 2 productos

// B1.  Comprueba con $type que la fecha de todos los pedidos está guardada como tipo Date
// que ningún precio de producto está guardado como texto.
db.pedidos.countDocuments({ fecha: { $not: { $type: "date" } } })
// Resultado: 0 pedidos con una fecha que no sea Date
db.productos.countDocuments({ precio: { $type: "string" } })
// Resultado: 0 productos con el precio guardado como texto

// B2.
// * Reseñas en colección propia o dentro del restaurante
// Guardaría las reseñas en una colección propia (resenas) y no dentro del documento del restaurante.
// Con una colección propia se piden las últimas reseñas con sort y limit, y cada reseña nueva es un insert independiente que no reescribe el documento del restaurante.

// * Límite de 16 MB: un restaurante puede acumular miles de reseñas con texto y fotos. Un arreglo que crece
// sin limite dentro del restaurante terminaría acercándose a los 16 MB por documento y haría más pesada cada lectura.
// por lo tanto, copiaría solo el id y el nombre, que es lo que pide el esquema. El nombre es lo que se muestra
// junto a cada reseña, y copiarlo evita buscar al cliente en otra colección por cada reseña; el id permite llegar
// al cliente completo si hace falta. No copiaría email, puntos ni direcciones: no se muestran en la reseña,
// cambian con frecuencia y repetirían datos personales sin necesidad.

// B3. Colección resenas con validación
db.createCollection("resenas", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["restaurante_id", "cliente", "calificacion", "texto", "fecha"],
      properties: {
        restaurante_id: { bsonType: "string" },
        cliente: {
          bsonType: "object",
          required: ["id", "nombre"],
          properties: {
            id: { bsonType: "string" },
            nombre: { bsonType: "string" }
          }
        },
        calificacion: { bsonType: "int", minimum: 1, maximum: 5 },
        texto: { bsonType: "string", minLength: 5 },
        fecha: { bsonType: "date" },
        fotos: { bsonType: "array", maxItems: 4, items: { bsonType: "string" } }
      }
    }
  }
})

// B4. Cuatro reseñas válidas
db.resenas.insertMany([
  { restaurante_id: "R02", cliente: { id: "C01", nombre: "Laura Gómez" }, calificacion: 5, texto: "El ramen llegó caliente y bien empacado", fecha: new Date("2026-10-15T20:10:00-05:00") },
  { restaurante_id: "R02", cliente: { id: "C08", nombre: "Julián Castro" }, calificacion: 4, texto: "Buen sushi, pero tardó 50 minutos", fecha: new Date("2026-10-16T21:30:00-05:00") },
  { restaurante_id: "R10", cliente: { id: "C07", nombre: "Daniela Martínez" }, calificacion: 5, texto: "La cazuela es abundante", fotos: ["https://cdn.saborya.co/r/301.jpg", "https://cdn.saborya.co/r/302.jpg"], fecha: new Date("2026-10-17T13:45:00-05:00") },
  { restaurante_id: "R04", cliente: { id: "C03", nombre: "Valentina Ríos" }, calificacion: 2, texto: "Las papas llegaron frías", fecha: new Date("2026-10-18T19:05:00-05:00") }
])
// Resultado: 4 reseñas insertadas

// B5. Reseña inválida (calificación 6)
db.resenas.insertOne({ restaurante_id: "R01", cliente: { id: "C02", nombre: "Andrés Rojas" }, calificacion: 6, texto: "Las arepas estaban buenas", fecha: new Date("2026-10-19T09:20:00-05:00") })
// Error: MongoServerError: Document failed validation.
// La reseña cumple todo lo demás; falla únicamente por la regla maximum: 5 de la propiedad calificacion
// dentro del $jsonSchema. El valor 6 supera el máximo permitido (el rango válido es de 1 a 5).

// B6. Reseñas de Laura Gómez y reseñas con al menos una foto
db.resenas.find({ "cliente.id": "C01" })
// Resultado: 1 reseña de Laura Gómez (R02, calificación 5)
db.resenas.find({ "fotos.0": { $exists: true } })
// Resultado: 1 reseña de Daniela Martínez (R10, calificación 5, 2 fotos)

// B7. Resumen de reseñas en el restaurante R02
// R02 tiene 2 reseñas
db.resenas.countDocuments({ restaurante_id: "R02" })
// Resultado: 2
// promedio = (5 + 4) / 2 = 4.5
db.restaurante.updateOne({ _id: "R02" }, { $set: { resumen_resenas: { promedio: 4.5, total: 2 } } })
db.restaurante.find({ _id: "R02" }, { nombre: 1, resumen_resenas: 1 })

// B8. Restaurantes distintos con reseñas
db.resenas.distinct("restaurante_id")
// Resultado: [ 'R02', 'R04', 'R10' ] (3 restaurantes)


// C1. Platos disponibles con stock menor a 20
db.productos.find({ tipo: "plato", disponible: true, stock: { $lt: 20 } }, { nombre: 1, stock: 1, _id: 0 }).sort({ stock: 1 })
// Resultado: 6 documentos

// C2. Pedidos entre 50.000 y 80.000 pagados en efectivo o nequi
db.pedidos.find({ total: { $gte: 50000, $lte: 80000 }, metodo_pago: { $in: ["efectivo", "nequi"] } }, { total: 1, metodo_pago: 1 })
// Resultado: 6 documentos

// C3. Los 3 restaurantes de Bogotá con mejor calificación
db.restaurante.find({ ciudad: "Bogotá" }, { nombre: 1, calificacion: 1, _id: 0 }).sort({ calificacion: -1 }).limit(3)
// Resultado: Sushi Nikko, Arepas La 19 y Ajiaco & Co

// C4. Clientes de Bogotá con más de 100 puntos
db.clientes.find({ ciudad: "Bogotá", puntos: { $gt: 100 } }, { nombre: 1, ciudad: 1, puntos: 1, _id: 0 })
// Resultado: Laura Gómez, Andrés Rojas, Julián Castro, Jessica Gil 

// C5. Pedidos del 12 al 14 de octubre de 2026 (hora de Colombia) que no estén entregados
// Se usa $lt con el 15 de octubre a las 00:00 para que el 14 quede completo.
db.pedidos.find({ fecha: { $gte: new Date("2026-10-12T00:00:00-05:00"), $lt: new Date("2026-10-15T00:00:00-05:00") }, estado: { $ne: "entregado" } }, { estado: 1, fecha: 1, total: 1 })
// Resultado: 5 documentos

// C6. Ítem de precio menor a 10.000 y cantidad de 2 o más en el mismo ítem
db.pedidos.find({ items: { $elemMatch: { precio: { $lt: 10000 }, cantidad: { $gte: 2 } } } }, { items: 1 })
// Resultado: 5 documentos
db.pedidos.find({ "items.precio": { $lt: 10000 }, "items.cantidad": { $gte: 2 } }, { items: 1 })
// Resultado: 6 documentos
// El resultado cambia porque sin $elemMatch cada condición se evalúa por separado sobre todo el arreglo:
// un ítem puede cumplir el precio y otro distinto cumplir la cantidad. El pedido PD005 aparece solo en la
// segunda consulta: la arepa con hogao cuesta 8.000 (cantidad 1) y la bandeja paisa tiene cantidad 2 (precio 34.000).
// Con $elemMatch las dos condiciones tienen que cumplirse en el mismo ítem.

// C7. Catálogo del más caro al más barato, página 2 de 6 productos
// Se desempata por _id para que el orden sea el mismo cuando hay precios repetidos y las páginas no se solapen.
db.productos.find({}, { nombre: 1, precio: 1 }).sort({ precio: -1, _id: 1 }).skip(6).limit(6)
// Resultado: 6 documentos

// C8. Restaurantes que tienen el campo horario o el campo menu_vegano
db.restaurante.find({ $or: [{ horario: { $exists: true } }, { menu_vegano: { $exists: true } }] }, { nombre: 1, horario: 1, menu_vegano: 1, _id: 0 })
// Resultado: 2 restaurantes Sushi Nikko y Verde Vivo