// s4_historico.js · Genera 100.000 pedidos históricos de SaborYa (siempre los mismos: generador con semilla fija)
// Ejecutar en la consola mongosh de Compass con load("ruta/s4_historico.js") o pegándolo completo. Tarda entre 20 y 90 segundos.
db = db.getSiblingDB("saborya")
db.pedidos_historico.drop()

function mulberry32(a) { return function () { a |= 0; a = a + 0x6D2B79F5 | 0; let t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
const rnd = mulberry32(2026);
const REST = [{"id":"R01","nombre":"Arepas La 19","ciudad":"Bogotá","menu":[["P01","Arepa de choclo con queso",9500],["P02","Arepa rellena de carne",14000],["P03","Jugo de lulo",6000]]},{"id":"R02","nombre":"Sushi Nikko","ciudad":"Bogotá","menu":[["P04","Combo Sake",41000],["P05","Ramen tonkotsu",36000],["P06","Té verde",7000]]},{"id":"R03","nombre":"Pizzería Napoli","ciudad":"Bogotá","menu":[["P07","Pizza hawaiana mediana",32000],["P08","Pizza margarita grande",38000]]},{"id":"R04","nombre":"Burger Norte","ciudad":"Bogotá","menu":[["P10","Hamburguesa clásica",22000],["P11","Papas a la francesa",8000]]},{"id":"R05","nombre":"Ajiaco & Co","ciudad":"Bogotá","menu":[["P12","Ajiaco santafereño",28000],["P13","Chocolate con queso",9000]]},{"id":"R06","nombre":"Verde Vivo","ciudad":"Medellín","menu":[["P14","Bowl de quinua",26000],["P15","Hamburguesa de lentejas",24000]]},{"id":"R07","nombre":"Bandeja Paisa Doña Rosa","ciudad":"Medellín","menu":[["P16","Bandeja paisa",34000],["P17","Arepa con hogao",8000]]},{"id":"R08","nombre":"Taco Loco","ciudad":"Medellín","menu":[["P18","Tacos al pastor x3",21000],["P19","Burrito de pollo",25000]]},{"id":"R09","nombre":"Brasa Caribe","ciudad":"Barranquilla","menu":[["P20","Picada para dos",58000],["P21","Costillas BBQ",45000]]},{"id":"R10","nombre":"Mar y Coco","ciudad":"Barranquilla","menu":[["P22","Cazuela de mariscos",52000],["P23","Arroz con coco y pescado",39000],["P24","Limonada de coco",9000]]}];
const DESDE = Date.parse("2025-01-01T05:00:00Z"), HASTA = Date.parse("2026-10-26T05:00:00Z");
function estado(x) { return x < 0.80 ? "entregado" : x < 0.90 ? "cancelado" : x < 0.95 ? "en_camino" : "pendiente"; }
function pago(x) { return x < 0.5 ? "tarjeta" : x < 0.8 ? "nequi" : "efectivo"; }
function pedido(n) {
  const r = REST[Math.floor(rnd() * REST.length)];
  const nItems = 1 + Math.floor(rnd() * Math.min(3, r.menu.length));
  const items = [];
  for (let k = 0; k < nItems; k++) {
    const p = r.menu[(Math.floor(rnd() * r.menu.length) + k) % r.menu.length];
    if (items.some(i => i.producto_id === p[0])) continue;
    items.push({ producto_id: p[0], nombre: p[1], precio: p[2], cantidad: 1 + Math.floor(rnd() * 3) });
  }
  const cid = 1 + Math.floor(rnd() * 20000);
  return {
    numero: n,
    cliente: { id: "H" + String(cid).padStart(5, "0") },
    restaurante: { id: r.id, nombre: r.nombre, ciudad: r.ciudad },
    fecha: new Date(DESDE + Math.floor(rnd() * (HASTA - DESDE))),
    estado: estado(rnd()),
    metodo_pago: pago(rnd()),
    items: items,
    total: items.reduce((s, i) => s + i.precio * i.cantidad, 0)
  };
}

const TOTAL = 100000, LOTE = 5000;
for (let inicio = 1; inicio <= TOTAL; inicio += LOTE) {
  const lote = [];
  for (let n = inicio; n < inicio + LOTE; n++) lote.push(pedido(n));
  db.pedidos_historico.insertMany(lote, { ordered: false });
  print("Insertados: " + (inicio + LOTE - 1));
}
print("Total en pedidos_historico: " + db.pedidos_historico.countDocuments());
