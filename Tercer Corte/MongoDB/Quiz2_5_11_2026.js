// 1.
db.pedidos.aggregate([
  { $match: { estado: "entregado" } },
  { $group: { _id: "$metodo_pago", ventas: { $sum: "$total" }, pedidos: { $sum: 1 } } },
  { $sort: { ventas: -1 } }
])
//2.
db.pedidos.aggregate([
  { $match: { estado: "cancelado" } },
  { $group: { _id: "$estado", total: { $sum: 1 } } }
])
//3.
db.productos.aggregate([
  { $match: { disponible: true } },
  { $group: { _id: "$restaurante_id", menu: { $push: "$nombre" }, precio_maximo: { $max: "$precio" } } },
  { $sort: { _id: 1 } },
  { $limit: 3 }
])