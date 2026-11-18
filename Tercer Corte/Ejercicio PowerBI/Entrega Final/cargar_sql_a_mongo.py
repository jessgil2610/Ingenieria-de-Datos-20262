# cargar_sql_a_mongo.py
# Lee saborya_finanzas.sql y carga sus tres tablas como colecciones de MongoDB en la base saborya:
#   comisiones, metas_mensuales, facturas
# No necesita MySQL ni MariaDB: solo lee el archivo .sql como texto.
#
# Uso (en una terminal, con el .sql en la misma carpeta que este script):
#   python cargar_sql_a_mongo.py
#   python cargar_sql_a_mongo.py "C:\SaborYa\saborya_finanzas.sql"
#   python cargar_sql_a_mongo.py --dry-run        (solo lee y cuenta, no toca MongoDB)
# Requisito: pip install pymongo

import re
import sys
from datetime import datetime, timedelta

URI = "mongodb://localhost:27017/?directConnection=true"   # Atlas: pega aquí tu cadena mongodb+srv://
BASE = "saborya"

args = [a for a in sys.argv[1:] if not a.startswith("--")]
DRY_RUN = "--dry-run" in sys.argv
RUTA_SQL = args[0] if args else "saborya_finanzas.sql"

# Cada fila de un INSERT es una tupla entre paréntesis: (1, 'FE-000001', '2025-05-28 02:00:14', ...)
FILA = re.compile(r"^\((.*)\),?;?\s*$")
VALOR = re.compile(r"'((?:[^']|'')*)'|(-?\d+(?:\.\d+)?)")


def valores(texto):
    salida = []
    for m in VALOR.finditer(texto):
        if m.group(1) is not None:
            salida.append(m.group(1).replace("''", "'"))
        else:
            n = m.group(2)
            salida.append(float(n) if "." in n else int(n))
    return salida


def leer_tablas(ruta):
    tablas = {"comisiones": [], "metas_mensuales": [], "facturas": []}
    actual = None
    with open(ruta, encoding="utf-8") as f:
        for linea in f:
            linea = linea.rstrip("\n")
            m = re.match(r"INSERT INTO (\w+) VALUES", linea)
            if m:
                actual = m.group(1)
                continue
            if actual:
                fila = FILA.match(linea)
                if fila:
                    tablas[actual].append(valores(fila.group(1)))
                if linea.rstrip().endswith(";"):
                    actual = None
    return tablas


def a_utc(texto):
    # En MySQL las fechas están en hora de Colombia (UTC-5, sin horario de verano).
    # MongoDB las guarda en UTC; el script de Power BI las vuelve a pasar a hora de Colombia.
    return datetime.strptime(texto, "%Y-%m-%d %H:%M:%S") + timedelta(hours=5)


tablas = leer_tablas(RUTA_SQL)

comisiones = [{"_id": r[0], "restaurante_id": r[0], "porcentaje_comision": float(r[1])}
              for r in tablas["comisiones"]]
metas = [{"ciudad": r[0], "anio": int(r[1]), "mes": int(r[2]), "meta_ventas": int(r[3])}
         for r in tablas["metas_mensuales"]]
facturas = [{"_id": int(r[0]), "numero_pedido": int(r[0]), "numero_factura": r[1],
             "fecha_emision": a_utc(r[2]), "base": int(r[3]), "impoconsumo": int(r[4]),
             "total": int(r[5]), "estado_dian": r[6]}
            for r in tablas["facturas"]]

print("Leído del .sql -> comisiones:", len(comisiones), "| metas_mensuales:", len(metas),
      "| facturas:", len(facturas))
estados = {}
for fa in facturas:
    estados[fa["estado_dian"]] = estados.get(fa["estado_dian"], 0) + 1
print("Facturas por estado_dian:", estados)

if DRY_RUN:
    print("Modo --dry-run: no se escribió nada en MongoDB.")
    sys.exit(0)

from pymongo import MongoClient

cliente = MongoClient(URI, serverSelectionTimeoutMS=10000)
db = cliente[BASE]
for nombre, docs in (("comisiones", comisiones), ("metas_mensuales", metas), ("facturas", facturas)):
    db[nombre].drop()                       # se puede repetir: borra y recarga, nunca duplica
    for i in range(0, len(docs), 5000):
        db[nombre].insert_many(docs[i:i + 5000], ordered=False)
    print("Cargado en MongoDB:", nombre, "->", db[nombre].count_documents({}))
db.facturas.create_index("numero_pedido")
cliente.close()
print("Listo. Comprueba en Compass: base saborya, colecciones comisiones (10), "
      "metas_mensuales (66) y facturas (79824).")
