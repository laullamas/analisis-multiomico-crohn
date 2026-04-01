/*
 * MERGE_BRACKEN — Tabla de abundancias relativas combinada (módulo local)
 *
 * Combina los outputs individuales de Bracken (un TSV por muestra) en una
 * única matriz especie×muestra, equivalente al perfil combinado que genera
 * nf-core/taxprofiler como output final.
 *
 * Formato de salida (merged_bracken_abundance.tsv):
 *   - Filas: especies (nombre científico + taxonomy_id)
 *   - Columnas: una por muestra (new_est_reads = abundancia re-estimada)
 *   - Primera fila: cabecera con IDs de muestra
 *
 * Este archivo es el punto de entrada para el análisis downstream en R
 * con phyloseq (analisis_metagenomico_moduloB.Rmd).
 */
process MERGE_BRACKEN {
    label 'process_low'

    conda 'conda-forge::python=3.10 conda-forge::pandas=2.0'

    publishDir "${params.outdir}/bracken", mode: 'copy'

    input:
    path bracken_tsvs   // todos los archivos .bracken_species.txt de todas las muestras

    output:
    path "merged_bracken_abundance.tsv", emit: merged
    path "versions.yml",                 emit: versions

    script:
    """
    python3 <<'EOF'
import pandas as pd
import glob
import os

# Leer todos los TSV de Bracken
files = sorted(glob.glob("*.bracken_species.txt"))
dfs   = []

for f in files:
    sample = f.replace(".bracken_species.txt", "")
    df = pd.read_csv(f, sep="\t")
    # Columnas Bracken: name, taxonomy_id, taxonomy_lvl, kraken_assigned_reads,
    #                   added_reads, new_est_reads, fraction_total_reads
    df = df[["name", "taxonomy_id", "new_est_reads"]].rename(
        columns={"new_est_reads": sample}
    )
    df = df.set_index(["name", "taxonomy_id"])
    dfs.append(df)

# Combinar en una matriz (outer join: 0 donde la especie no aparece en la muestra)
merged = pd.concat(dfs, axis=1).fillna(0).astype(int)
merged.to_csv("merged_bracken_abundance.tsv", sep="\t")
print(f"Merged {len(files)} samples, {len(merged)} species.")
EOF

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | sed 's/Python //')
        pandas: \$(python3 -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """

    stub:
    """
    touch merged_bracken_abundance.tsv
    touch versions.yml
    """
}
