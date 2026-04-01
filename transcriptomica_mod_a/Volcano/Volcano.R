library(ggplot2)
library(ggrepel)

# Leer archivo tabular directamente
data <- read.table("Galaxy94-DESeq2.tabular", header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# Seleccionar columnas necesarias
data_subset <- data[, c("GeneID", "log2.FC.", "P.adj")]

# Convertir a numérico
data_subset$P.adj <- as.numeric(data_subset$P.adj)
data_subset$log2.FC. <- as.numeric(data_subset$log2.FC.)

# Crear columna Status para categorías
data_subset$Status <- "Not Significant"
data_subset$Status[data_subset$P.adj < 0.05 & data_subset$log2.FC. > 0] <- "Upregulated in CD"
data_subset$Status[data_subset$P.adj < 0.05 & data_subset$log2.FC. < 0] <- "Upregulated in Control"

# Subconjunto solo con genes significativos para etiquetas
sig_genes <- subset(data_subset, P.adj < 0.05)

# Definir colores
colors <- c("Upregulated in CD" = "red",
            "Upregulated in Control" = "blue",
            "Not Significant" = "grey70")

# Plot con etiquetas solo en genes significativos
ggplot(data_subset, aes(x = log2.FC., y = -log10(P.adj), color = Status)) +
  geom_point(alpha = 0.7, size = 2) +
  
  geom_vline(xintercept = 0, linetype = "dashed", color = "black") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "black") +
  
  geom_text_repel(data = sig_genes,
                  aes(label = GeneID),
                  size = 3,
                  box.padding = 0.4,
                  point.padding = 0.3,
                  max.overlaps = 20) +  # Ajusta para evitar demasiados solapamientos
  
  scale_color_manual(values = colors) +
  labs(title = "Volcano Plot: CD vs Control",
       x = "Log2 Fold Change",
       y = "-Log10 adjusted p-value",
       color = "") +
  theme_minimal() +
  theme(legend.position = "right")

