// Quiz 2 - 5/11/2026 - Jessica Gil

// 1. ventas de pedios entregados por metodo de pago
db.pedidos.aggregate([{ $match: { estado: "entregado" } },{ $group: { _id: "$metodo_pago", ventas: { $sum: "$total" }, pedidos: { $sum: 1 } } },{ $sort: { ventas: -1 } }])

// 2. Cuántos pedidos se cancelaron
db.pedidos.aggregate([{ $match: { estado: "cancelado" } },{ $group: { _id: "$estado", total: { $sum: 1 } } }])

// 3. Menú disponible por restaurante, con precio máximo -primeros 3 por _id
db.productos.aggregate([{ $match: { disponible: true } },{ $group: { _id: "$restaurante_id", menu: { $push: "$nombre" }, precio_maximo: { $max: "$precio" } } },{ $sort: { _id: 1 } },{ $limit: 3 }])

// 4. Productos por tipo con precio promedio
db.productos.aggregate([{ $group: { _id: "$tipo", precio_promedio: { $avg: "$precio" }, productos: { $sum: 1 } } },{ $sort: { precio_promedio: -1 } }])

// 5. Clientes con mayor gasto en pedidos entregados
db.pedidos.aggregate([{ $match: { estado: "entregado" } },{ $group: { _id: { id: "$cliente.id", nombre: "$cliente.nombre" }, gasto_total: { $sum: "$total" }, pedidos: { $sum: 1 } } },{ $sort: { gasto_total: -1 } },{ $limit: 3 }])

// 6.Restaurantes con ventas entregadas superiores a 70.000
db.pedidos.aggregate([{ $match: { estado: "entregado" } },{ $group: { _id: { id: "$restaurante.id", nombre: "$restaurante.nombre" }, ventas: { $sum: "$total" } } },{ $match: { ventas: { $gt: 70000 } } },{ $sort: { ventas: -1 } }])

// 7. Pedidos pendientes o en camino con el email del cliente
db.pedidos.aggregate([{ $match: { estado: { $in: ["pendiente", "en_camino"] } } },{ $lookup: { from: "clientes", localField: "cliente.id", foreignField: "_id", as: "datos_cliente" } },{ $unwind: "$datos_cliente" },{ $project: { estado: 1, total: 1, nombre: "$cliente.nombre", email: "$datos_cliente.email" } }])