# Análisis multi-ómico de la enfermedad de Crohn

Análisis integrado de datos transcriptómicos y metagenómicos de pacientes con enfermedad de Crohn (EC) frente a controles sanos, mediante análisis estadístico en R y Galaxy.

## Estructura del repositorio

```
analisis-multiomico-crohn/
├── transcriptomica_mod_a/       # Módulo A: RNA-seq y expresión diferencial
├── metagenomica_mod_b/          # Módulo B: metagenómica shotgun
└── informe.pdf                  # Informe final integrado
```


---

## Módulo A — Transcriptómica (`transcriptomica_mod_a/`)

```
transcriptomica_mod_a/
├── Databases/                   # Metadatos y ficheros SraRunInfo descargados de GEO/SRA
├── Extraer muestras/            # Scripts de selección y filtrado de muestras (R Markdown)
├── Galaxy/                      # Resultados del análisis DESeq2 ejecutado en Galaxy
├── Volcano/                     # Volcano plot (R Markdown + script)
└── Nextflow_moduloA.zip         # Pipeline Nextflow DSL2 (comprimido para despliegue en servidor)
```

## Módulo B — Metagenómica (`metagenomica_mod_b/`)

```
metagenomica_mod_b/
├── seleccion_muestras/          # Selección y filtrado de muestras (R Markdown)
├── nextflow_metagenomica/       # Pipeline Nextflow DSL2 
├── analisis_metagenomico/       # Análisis estadístico y figuras (R Markdown)
└── multiqc_reports/             # Informes MultiQC
```

