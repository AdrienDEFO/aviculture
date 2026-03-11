# Script d'installation automatique pour aviculture dans RStudio
# Simplement copier-coller ce script dans la console RStudio et appuyer sur ENTRÉE

# ========================================================================
# INSTALLATION AUTOMATIQUE DU PACKAGE AVICULTURE
# ========================================================================

cat("\n")
cat(strrep("=", 73), "\n", sep="")
cat("Installation du package aviculture dans RStudio\n")
cat(strrep("=", 73), "\n\n", sep="")

# Vérifier si devtools est installé
cat("1. Vérification de devtools...\n")
if (!require("devtools", quietly = TRUE)) {
  cat("   > Installation de devtools...\n")
  install.packages("devtools")
} else {
  cat("   * devtools est déjà installé\n")
}

# Vérifier si les dépendances requises sont installées
cat("\n2. Installation des dépendances...\n")
packages_needed <- c("reticulate", "jsonlite", "roxygen2")
packages_to_install <- packages_needed[!sapply(packages_needed, require, quietly = TRUE)]

if (length(packages_to_install) > 0) {
  cat("   > Installation de:", paste(packages_to_install, collapse = ", "), "\n")
  install.packages(packages_to_install)
} else {
  cat("   * Toutes les dépendances sont installées\n")
}

# Installer le package aviculture
cat("\n3. Installation du package aviculture...\n")
tryCatch({
  devtools::install_local(
    "D:/projet/Avipro/aviculture",
    dependencies = TRUE,
    force = TRUE
  )
  cat("   * Installation réussie!\n")
}, error = function(e) {
  cat("   * Erreur lors de l'installation:", e$message, "\n")
})

# Charger le package pour vérifier
cat("\n4. Vérification du package...\n")
tryCatch({
  library(aviculture)
  cat("   * Package chargé avec succès\n")
  cat("   * Version:", paste(packageVersion("aviculture")), "\n")
  cat("   * Fonctions disponibles:", length(ls("package:aviculture")), "\n")
}, error = function(e) {
  cat("   * Erreur lors du chargement:", e$message, "\n")
})

cat("\n", strrep("=", 73), "\n", sep="")
cat("Installation terminée!\n")
cat("\nPour utiliser le package, tapez: library(aviculture)\n")
cat(strrep("=", 73), "\n\n", sep="")



