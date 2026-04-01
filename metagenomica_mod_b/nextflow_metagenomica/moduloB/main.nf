#!/usr/bin/env nextflow

/*
 * =========================================================
 * Módulo B — Pipeline metagenómico: CD vs nonIBD
 * PRJNA389280 · IBDMDB / HMP2 · Lloyd-Price et al. 2019
 * =========================================================
 * Pasos:
 *
 *   FASTQ → FALCO (pre) → FASTP → FALCO (post) → BOWTIE2_ALIGN
 *         → KRAKEN2_KRAKEN2 → BRACKEN_BRACKEN → MERGE_BRACKEN (TSV)
 *                                              → MULTIQC (HTML)
 *
 * Módulos nf-core instalados con:
 *   nf-core modules install falco
 *   nf-core modules install fastp
 *   nf-core modules install bowtie2/align
 *   nf-core modules install kraken2/kraken2
 *   nf-core modules install bracken/bracken
 *   nf-core modules install multiqc
 *
 * Módulo local custom:
 *   modules/local/merge_bracken/main.nf  → tabla especie×muestra final (TSV)
 * =========================================================
 * Uso:
 *   nextflow run main.nf -profile conda --outdir results/
 *   nextflow run main.nf -profile dayhoff --outdir results/
 */

nextflow.enable.dsl = 2

// ---------------------------------------------------------------------------
// Importar módulos nf-core
// FALCO se importa dos veces con alias DSL2: pre-trimming y post-trimming
// ---------------------------------------------------------------------------
include { FALCO as FALCO_RAW     } from './modules/nf-core/falco/main'
include { FALCO as FALCO_TRIMMED } from './modules/nf-core/falco/main'
include { FASTP                  } from './modules/nf-core/fastp/main'
include { BOWTIE2_ALIGN          } from './modules/nf-core/bowtie2/align/main'
include { KRAKEN2_KRAKEN2        } from './modules/nf-core/kraken2/kraken2/main'
include { BRACKEN_BRACKEN        } from './modules/nf-core/bracken/bracken/main'
include { MULTIQC                } from './modules/nf-core/multiqc/main'

// Módulo local (custom, no nf-core)
include { MERGE_BRACKEN          } from './modules/local/merge_bracken/main'

// ---------------------------------------------------------------------------
// Workflow principal
// ---------------------------------------------------------------------------
workflow {

    // -------------------------------------------------------------------
    // 1. Leer el samplesheet CSV y construir el canal de reads
    //    Cada elemento: [ meta (Map con id y group), [ read1, read2 ] ]
    // -------------------------------------------------------------------
    ch_reads = Channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true)
        .map { row ->
            def meta = [ id: row.sample, group: row.group ]
            [ meta, [ file(row.fastq_1), file(row.fastq_2) ] ]
        }

    // -------------------------------------------------------------------
    // 2. QC de las lecturas crudas con FALCO (pre-trimming)
    //    Equivalente al Falco/FastQC inicial en Galaxy y taxprofiler
    // -------------------------------------------------------------------
    FALCO_RAW(ch_reads)

    // -------------------------------------------------------------------
    // 3. Trimming y filtrado con FASTP
    //    Adaptadores Nextera XT, Q15, longitud mínima 50 bp,
    //    filtro de baja complejidad, corrección por solapamiento PE
    // -------------------------------------------------------------------
    FASTP(ch_reads)

    // -------------------------------------------------------------------
    // 4. QC de las lecturas limpias con FALCO (post-trimming)
    //    Permite comparar la calidad antes y después del preprocesamiento
    //    El alias 'FALCO_TRIMMED' usa el mismo módulo que FALCO_RAW
    // -------------------------------------------------------------------
    FALCO_TRIMMED(FASTP.out.reads)

    // -------------------------------------------------------------------
    // 5. Descontaminación del huésped con BOWTIE2_ALIGN (hg38 Full)
    //    Se retienen solo las reads que NO alinean al genoma humano
    //    Tasa de alineamiento humano obtenida en Galaxy: < 1.46%
    // -------------------------------------------------------------------
    BOWTIE2_ALIGN(
        FASTP.out.reads,
        Channel.value(file(params.bowtie2_index))
    )

    // -------------------------------------------------------------------
    // 6. Clasificación taxonómica con KRAKEN2_KRAKEN2
    //    BD Standard-Full 2024-09-04, umbral de confianza 0.1
    //    Tasa de clasificación obtenida en Galaxy: ~57.5%
    // -------------------------------------------------------------------
    KRAKEN2_KRAKEN2(
        BOWTIE2_ALIGN.out.reads,
        Channel.value(file(params.kraken2_db))
    )

    // -------------------------------------------------------------------
    // 7. Re-estimación de abundancias con BRACKEN_BRACKEN
    //    Nivel especie (S), lectura 100 bp, umbral 10 reads
    //    Genera reportes equivalentes a los descargados desde Galaxy
    // -------------------------------------------------------------------
    BRACKEN_BRACKEN(
        KRAKEN2_KRAKEN2.out.report,
        Channel.value(file(params.kraken2_db))
    )

    // -------------------------------------------------------------------
    // 8. Tabla de abundancias combinada: MERGE_BRACKEN (módulo local)
    //    Une los TSV individuales de Bracken en una matriz especie×muestra
    //    Equivalente al perfil combinado de nf-core/taxprofiler
    //    Output: merged_bracken_abundance.tsv → input para R/phyloseq
    // -------------------------------------------------------------------
    MERGE_BRACKEN(
        BRACKEN_BRACKEN.out.tsv.collect()
    )

    // -------------------------------------------------------------------
    // 9. Informe agregado de QC con MULTIQC
    //    Recoge: Falco pre + Falco post + fastp JSON + Bowtie2 logs
    //    Output: multiqc_report.html con gráficos de todas las muestras
    // -------------------------------------------------------------------
    ch_multiqc = Channel.empty()
    ch_multiqc = ch_multiqc.mix(FALCO_RAW.out.txt.map     { meta, txt -> txt })
    ch_multiqc = ch_multiqc.mix(FALCO_TRIMMED.out.txt.map { meta, txt -> txt })
    ch_multiqc = ch_multiqc.mix(FASTP.out.json.map         { meta, json -> json })
    ch_multiqc = ch_multiqc.mix(BOWTIE2_ALIGN.out.log)

    MULTIQC(ch_multiqc.collect())
}

// ---------------------------------------------------------------------------
// Al finalizar: resumen de resultados
// ---------------------------------------------------------------------------
workflow.onComplete {
    log.info """
    ╔══════════════════════════════════════════════════════╗
    ║  Pipeline finalizado: ${workflow.success ? 'OK ✓' : 'FALLIDO ✗'}
    ║  Duración    : ${workflow.duration}
    ║  Resultados  : ${params.outdir}
    ╚══════════════════════════════════════════════════════╝
    """.stripIndent()
}
