# Pipeline Metagenómico — Módulo B
**Enfermedad de Crohn vs nonIBD · PRJNA389280 · Laura Llamas López · María Sánchez Vivo**

Implementación en Nextflow DSL2 del pipeline de metagenómica shotgun:

```
                ┌─→ FALCO_RAW ─────────────────────────────────────┐
                │                                                         ↓
samplesheet.csv ─→ FASTP → FALCO_TRIMMED → BOWTIE2_ALIGN → KRAKEN2 → BRACKEN
                                                                           │
                                                           MERGE_BRACKEN ←┈┈┤ ← TSV especie×muestra
                                                           MULTIQC       ←┈┈┘ ← HTML informe QC
```

Reproduce exactamente el pipeline ejecutado en Galaxy (usegalaxy.eu),
automatizando todos los pasos con paralelización por muestra y gestión
de recursos SLURM en el clúster Dayhoff.

## Cómo se construyó este pipeline

Siguiendo el flujo de trabajo visto en clase:

```bash
# 1. Crear la pipeline con nf-core
nf-core pipelines create

# 2. Instalar los módulos nf-core necesarios
nf-core modules install falco
nf-core modules install fastp
nf-core modules install bowtie2/align
nf-core modules install kraken2/kraken2
nf-core modules install bracken/bracken
nf-core modules install multiqc

# 3. Crear módulo local (custom) para la tabla combinada de Bracken
#    modules/local/merge_bracken/main.nf

# 4. Editar main.nf para importar y conectar los módulos (ver main.nf)
```

Los módulos se guardan en `modules/nf-core/TOOL/SUBTOOL/main.nf` y se
importan en el workflow principal con la sintaxis `include { PROCESO } from`.

## Estructura

```
moduloB/
├── main.nf                              ← workflow principal (DSL2)
├── nextflow.config                      ← parámetros y perfiles SLURM/conda
├── samplesheet.csv                      ← las 8 muestras con rutas y grupo
└── modules/
    ├── nf-core/
    │   ├── falco/main.nf                ← QC inicial y post-trimming (alias DSL2)
    │   ├── fastp/main.nf                ← trimming + filtrado
    │   ├── bowtie2/align/main.nf        ← descontaminación huésped (GRCh38)
    │   ├── kraken2/kraken2/main.nf      ← clasificación taxonómica
    │   ├── bracken/bracken/main.nf      ← re-estimación de abundancias
    │   └── multiqc/main.nf              ← informe HTML de QC agregado
    └── local/
        └── merge_bracken/main.nf        ← tabla especie×muestra final (TSV)
```

## Conceptos DSL2 implementados

| Elemento | Dónde | Descripción |
|----------|-------|-------------|
| `nf-core modules install` | terminal | Instala módulos nf-core oficiales en `modules/nf-core/` |
| `include { FALCO as FALCO_RAW }` | `main.nf` | Alias DSL2: el mismo módulo importado dos veces con distinto nombre |
| `Channel.fromPath().splitCsv().map{}` | `main.nf` | Lee el samplesheet y construye el canal de reads |
| `tuple val(meta), path(reads)` | cada módulo | Patrón nf-core: metadatos en memoria + archivos en disco |
| `FASTP.out.reads` | `main.nf` | Conecta la salida de FASTP como entrada de BOWTIE2_ALIGN |
| `emit: reads / report / tsv` | cada módulo | Salidas nombradas para conectar procesos entre sí |
| `.map { meta, tsv -> tsv }.collect()` | `main.nf` | Elimina el meta y recoge todos los TSV en una lista para MERGE_BRACKEN |
| `task.ext.args` | cada módulo | Permite sobrescribir argumentos desde `nextflow.config` |
| `withLabel: 'process_high_memory'` | `nextflow.config` | Kraken2 pide 110 GB RAM en `eck-q` |
| `-resume` | ejecución | Reanuda desde el punto de fallo usando caché de `work/` |

## Configuración antes de ejecutar en Dayhoff (en el caso de que se ejecutase realmente)

**1. Actualizar `samplesheet.csv`** con las rutas reales a los FASTQs en Dayhoff.

**2. Ajustar rutas en `nextflow.config`** (buscar `TODO`):

```groovy
bowtie2_index = "/ruta/real/en/dayhoff/bowtie2/GRCh38"
kraken2_db    = "/ruta/real/en/dayhoff/kraken2_standard_full"
```

## Ejecución en Dayhoff

```bash
# Subir archivos al servidor

# En Dayhoff: activar conda con nf-core y nextflow
conda activate nf-core

# Lanzar el pipeline
nextflow run main.nf -profile dayhoff -resume
```

O como job SLURM (recomendado para evitar corte de sesión):

```bash
#!/bin/bash
#SBATCH --job-name=moduloB
#SBATCH --output=logs/nf_%j.log
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=1-00:00:00
#SBATCH --partition=eck-q

conda activate nf-core
mkdir -p logs
nextflow run main.nf -profile dayhoff -resume
```

## Resultados esperados

```
results/
├── falco/
│   ├── raw/
│   │   └── SRR5947807_*_fastqc.html    ← QC pre-trimming por muestra
│   └── trimmed/
│       └── SRR5947807_*_fastqc.html    ← QC post-trimming por muestra
├── fastp/
│   ├── SRR5947807.fastp.html        ← QC post-trimming por muestra
│   └── SRR5947807.fastp.json
├── bowtie2/
│   └── SRR5947807_bowtie2.log       ← % reads humanas eliminadas (< 1.46%)
├── kraken2/
│   └── SRR5947807.kraken2.report.txt
├── bracken/
│   ├── SRR5947807.bracken.report.txt    ← report por muestra para downstream R
│   ├── SRR5947807.bracken_species.txt   ← TSV individual por muestra
│   └── merged_bracken_abundance.tsv     ← TABLA FINAL: especie×muestra (8 columnas)
└── multiqc/
    └── multiqc_report.html          ← informe QC agregado de todas las muestras
```

El `merged_bracken_abundance.tsv` es el equivalente al perfil combinado de
nf-core/taxprofiler: filas = especies, columnas = muestras, valores =
abundancias re-estimadas por Bracken. Es el punto de entrada directo para
el análisis R con phyloseq (`analisis_metagenomico_moduloB.Rmd`).

El `multiqc_report.html` contiene gráficos comparativos de las 8 muestras:
Calidad de bases Falco (pre y post), reads antes/después del trimming (fastp)
y % reads humanas descartadas (Bowtie2).
