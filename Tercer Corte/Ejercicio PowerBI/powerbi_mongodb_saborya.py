# powerbi_mongodb_saborya.py
# Script de origen de datos para Power BI Desktop: Obtener datos > Más... > Script de Python.
# Lee la base saborya de MongoDB y entrega tres tablas (DataFrames) a Power BI:
#   pedidos       -> un registro por pedido de pedidos_historico (100.000)
#   items         -> un registro por producto vendido dentro de cada pedido
#   restaurantes  -> los 10 restaurantes con su ubicación
# Requisitos en el equipo: Python 3, pandas, matplotlib y pymongo
#   pip install pandas matplotlib pymongo
# Datos requeridos en MongoDB: s3_datos.js y s4_historico.js ejecutados.

import pandas as pd
from pymongo import MongoClient

URI = "mongodb://localhost:27017/?directConnection=true"   # Atlas: pega aquí tu cadena mongodb+srv://
BASE = "saborya"

cliente = MongoClient(URI, serverSelectionTimeoutMS=10000)
db = cliente[BASE]


def a_hora_colombia(serie):
    # MongoDB guarda las fechas en UTC; Power BI debe mostrarlas en hora de Colombia
    return pd.to_datetime(serie, utc=True).dt.tz_convert("America/Bogota").dt.tz_localize(None)


# 1. Pedidos: el pipeline se ejecuta dentro de MongoDB y solo viajan los campos necesarios
pipeline_pedidos = [
    {"$project": {
        "_id": 0,
        "numero": 1,
        "fecha": 1,
        "estado": 1,
        "metodo_pago": 1,
        "cliente_id": "$cliente.id",
        "restaurante_id": "$restaurante.id",
        "ciudad": "$restaurante.ciudad",
        "total": 1,
        "unidades": {"$sum": "$items.cantidad"},
    }}
]
pedidos = pd.DataFrame(list(db.pedidos_historico.aggregate(pipeline_pedidos)))
pedidos["fecha"] = a_hora_colombia(pedidos["fecha"])
pedidos = pedidos[["numero", "fecha", "estado", "metodo_pago", "cliente_id",
                   "restaurante_id", "ciudad", "unidades", "total"]]

# 2. Items: $unwind convierte el arreglo de productos en un registro por producto
pipeline_items = [
    {"$unwind": "$items"},
    {"$project": {
        "_id": 0,
        "numero": 1,
        "producto_id": "$items.producto_id",
        "producto": "$items.nombre",
        "precio": "$items.precio",
        "cantidad": "$items.cantidad",
        "subtotal": {"$multiply": ["$items.precio", "$items.cantidad"]},
    }}
]
items = pd.DataFrame(list(db.pedidos_historico.aggregate(pipeline_items)))
items = items[["numero", "producto_id", "producto", "precio", "cantidad", "subtotal"]]

# 3. Restaurantes: las coordenadas GeoJSON vienen como [longitud, latitud]
filas = []
for r in db.restaurantes.find({}, {"nombre": 1, "categoria": 1, "ciudad": 1, "barrio": 1,
                                   "calificacion": 1, "domicilio": 1, "ubicacion": 1}):
    coordenadas = (r.get("ubicacion") or {}).get("coordinates", [None, None])
    filas.append({
        "restaurante_id": r["_id"],
        "restaurante": r["nombre"],
        "categoria": r.get("categoria"),
        "ciudad": r.get("ciudad"),
        "barrio": r.get("barrio"),
        "calificacion": r.get("calificacion"),
        "domicilio": r.get("domicilio"),
        "longitud": coordenadas[0],
        "latitud": coordenadas[1],
    })
restaurantes = pd.DataFrame(filas)

cliente.close()
