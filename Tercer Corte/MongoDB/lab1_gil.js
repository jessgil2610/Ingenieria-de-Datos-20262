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

// B1.  Comprueba con $type que la fecha de todos los pedidos está guardada como tipo Date y que ningún precio de producto está guardado como texto.
db.pedidos.find({ fecha: { $type: "date" } })
db.productos.find({ precio: { $type: "number" } })
