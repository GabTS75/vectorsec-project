#!/bin/bash
# ============================================================
# VectorSec — vectorsec_gestion
# backup_vectorsec_gestion.sh
#
# Genera un volcado (dump) de la base de datos y lo envía al
# recurso compartido de SRV-NAS, integrándose con la política
# de copias ya definida en el Módulo 1 (incremental diaria +
# completa semanal) y protegido por el RAID 5 + Hot Spare
# configurado en SRV-NAS (Módulo 2).
#
# Programación recomendada (crontab -e en SRV-APP01):
#   30 3 * * *  /opt/scripts/backup_vectorsec_gestion.sh >> /var/log/vectorsec-backup.log 2>&1
# ============================================================

set -euo pipefail

# --- Configuración ---
DB_NAME="vectorsec_gestion"
DB_USER="app_vectorsec"
DB_HOST="192.168.60.11"
FECHA=$(date +%Y%m%d)
DIR_LOCAL="/var/backups/postgresql"
ARCHIVO="vectorsec_gestion_${FECHA}.dump"
NAS_MONTPOINT="/mnt/nas-backups"          # punto de montaje del recurso SMB de SRV-NAS
NAS_DESTINO="${NAS_MONTPOINT}/postgresql"

# --- Preparar carpeta local temporal ---
mkdir -p "${DIR_LOCAL}"

# --- Generar el volcado en formato personalizado (-Fc) ---
# El formato personalizado permite restauraciones selectivas
# (por ejemplo, una sola tabla) en lugar de tener que restaurar
# el volcado completo, a diferencia de un simple .sql en texto plano
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando backup de ${DB_NAME}..."

pg_dump -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -Fc -f "${DIR_LOCAL}/${ARCHIVO}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Volcado generado: ${DIR_LOCAL}/${ARCHIVO}"

# --- Copiar al recurso compartido de SRV-NAS ---
if mountpoint -q "${NAS_MONTPOINT}"; then
    rsync -av "${DIR_LOCAL}/${ARCHIVO}" "${NAS_DESTINO}/"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Copia sincronizada con SRV-NAS."
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] AVISO: ${NAS_MONTPOINT} no está montado. El backup queda solo en local." >&2
    exit 1
fi

# --- Retención local: conservar solo los últimos 7 días en SRV-APP01 ---
# (SRV-NAS conserva su propio histórico según la política de copias del Módulo 1)
find "${DIR_LOCAL}" -name "vectorsec_gestion_*.dump" -mtime +7 -delete

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup completado correctamente."
