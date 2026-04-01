# Análisis multi-ómico de la enfermedad de Crohn

Análisis integrado de datos transcriptómicos y metagenómicos de pacientes con enfermedad de Crohn (EC) frente a controles sanos, aplicando pipelines reproducibles en Nextflow y análisis estadístico en R.

## Estructura del repositorio

```
analisis-multiomico-crohn/
├── transcriptomica_mod_a/       # Módulo A: RNA-seq e expresión diferencial
├── metagenomica_mod_b/          # Módulo B: metagenómica shotgun
└── informe.pdf                  # Informe final integrado
```

> **Nota:** `transcriptomica_mod_a/` e `informe.pdf` se añadirán próximamente.

## Módulos

### Módulo A — Transcriptómica (RNA-seq)

Análisis de expresión diferencial en mucosa ileal de pacientes con EC frente a controles sanos.

- **Datos:** GEO GSE193677 (BioProject PRJNA797175), cohorte MSCCR
- **Pipeline:** Nextflow DSL2 — fastp → HISAT2 → featureCounts → Falco → DESeq2
- **Resultados:** 7 genes diferencialmente expresados (p-adj < 0,05; |log₂FC| > 1), incluyendo *NCF4*, *MUC1* e *IL20RA*

### Módulo B — Metagenómica shotgun

Caracterización taxonómica del microbioma fecal mediante clasificación con Kraken2/Bracken.

- **Datos:** NCBI SRA BioProject PRJNA389280 (IBDMDB, Lloyd-Price et al. 2019)
- **Pipeline:** Nextflow DSL2 — Falco → fastp → Bowtie2 → Kraken2 → Bracken → MultiQC
- **Resultados:** 1775 especies identificadas; depleción de productores de butirato (*A. rectalis*, *R. intestinalis*) y enriquecimiento de patobiontes (*E. coli*, *V. parvula*) en EC

## Contenido de `metagenomica_mod_b/`

```
metagenomica_mod_b/
├── seleccion_muestras/          # Selección y filtrado de muestras (R Markdown)
├── nextflow_metagenomica/       # Pipeline Nextflow DSL2
└── analisis_metagenomico/       # Análisis estadístico y figuras (R Markdown)
```

## Tecnologías

| Herramienta | Uso |
|-------------|-----|
| Nextflow DSL2 | Orquestación de pipelines |
| nf-core modules | Módulos reutilizables (falco, fastp, bowtie2, kraken2, bracken, multiqc) |
| Kraken2 + Bracken | Clasificación taxonómica y re-estimación de abundancias |
| DESeq2 | Expresión diferencial |
| R (vegan, ggplot2) | Diversidad alfa/beta y visualización |

## Referencia principal

Lloyd-Price J, et al. Multi-omics of the gut microbial ecosystem in inflammatory bowel diseases. *Nature.* 2019;569:655–62.
