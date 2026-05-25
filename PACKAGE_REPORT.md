# Rapport du package `aviculture`

Ce document résume les méthodes implémentées et l'architecture du package `aviculture` afin de faciliter la rédaction d'un rapport technique et la mise en ligne sur GitHub.

## Structure du dépôt

- `R/` : code source R principal (implémentation du modèle, solveur, utilitaires, graphiques).
- `man/` : pages de documentation (Rd) générées.
- `inst/`, `vignettes/` : ressources utilisateur et exemples.
- `tests/` : tests unitaires et infrastructure de test.

Fichiers R principaux :

- `R/aviculture-package.R` : méta-documentation du package.
- `R/grid.R` : création et validation de la grille de simulation (`create_grid()`).
- `R/defaults.R` : définitions des fonctions et constantes par défaut (gamma, coûts, demandes, etc.).
- `R/controls.R` : création d'objets de contrôle temporels (`create_controls()`), conversion scalaire→fonction temporelle.
- `R/parameters.R` : création et validation des paramètres biologiques/économiques (`create_parameters()`).
- `R/solver_pde.R` : résolveur explicite upwind pour le modèle âge-masse (`solve_aviculture()`).
- `R/solver_utils.R` : utilitaires internes (évaluation de fonctions sur la grille, pondérations, etc.).
- `R/optimization.R` : optimisation du calendrier de fourniture (`optimize_supply()`).
- `R/indicators.R` : extraction d'indicateurs et objectifs (`compute_indicators()`, `compute_objectives()`).
- `R/plotting.R` : fonctions de visualisation (`plot_population()`, `plot_profiles()`, `plot_heatmap()`, `plot_economics()`, `plot_demand()`).
- `R/sensitivity.R` : analyse de sensibilité univariée (`run_sensitivity()`, `plot_sensitivity()`).
- `R/validation.R` : fonctions de validation et assertions internes.
- `R/methods.R` : méthodes S3 exportées (`print`, `summary`, `plot` pour les objets `aviculture_simulation`).

## Principales méthodes et leur rôle

- `create_grid(t_max, a_min, a_max, m_min, m_max, h_t, h_a, h_m, gamma_upper)`
  - Construit la discrétisation temporelle, d'âge et de masse utilisée par le solveur.

- `create_parameters(...)`
  - Construit l'objet `aviculture_parameters` contenant : `rho`, `market_mass`, `gamma1`, `gamma2`, `mortality`, `sale_rate`, `competition`, `feed_cost`, `death_cost`, `fixed_cost`.
  - Valide les types et fournit des comportements par défaut lorsque nécessaire.

- `create_controls(grid, supply, demand, price, supply_cost, name)`
  - Transforme entrées scalaires/vecteurs en fonctions de temps (via `.as_time_function`) et retourne un objet `aviculture_controls`.

- `solve_aviculture(grid, parameters, controls, initial_healthy, initial_stunted, store_states)`
  - Résout le système PDE âge–masse avec un schéma explicite upwind.
  - Stocke (optionnellement) les états temps×âge×masse pour les profils et heatmaps.
  - Calcule séries temporelles d'indicateurs économiques et biologiques (vente, décès, biomasse, profit, etc.) et deux objectifs : `J1` (coûts/profit) et `J2` (somme des carrés du déficit de demande).

- `optimize_supply(grid, parameters, controls, objective, blocks, lower, upper, initial)`
  - Optimise une stratégie de fourniture piècewise-constante via `stats::optim` (L-BFGS-B).
  - Retourne le contrôle optimisé, la simulation correspondante et la sortie de l'optimiseur.

- `run_sensitivity(grid, parameters, controls, variables, values)`
  - Exécute des scénarios univariés (variation d'un paramètre ou d'un facteur d'échelle sur les contrôles), résume les résultats et fournit un tableau tidy exploitable pour visualisation.

- Fonctions de tracé : `plot_population()`, `plot_profiles()`, `plot_heatmap()`, `plot_economics()`, `plot_demand()`, `plot_sensitivity()` — conçues pour travailler directement sur l'objet simulation.

## Architecture logicielle

- Paradigme : programmation fonctionnelle R avec objets S3 pour représenter `aviculture_grid`, `aviculture_parameters`, `aviculture_controls` et `aviculture_simulation`.
- Couche « interface utilisateur » : fonctions `create_*`, `run_sensitivity`, `optimize_supply`, et fonctions de plot qui exposent l'API publique.
- Couche « calcul » : `solve_aviculture()` (schéma numérique), aides internes dans `solver_utils.R` (pesées spatiales, évaluation des fonctions paramétriques sur la grille, masques de marché).
- Couche « utilitaires » : validations (`validation.R`), valeurs par défaut (`defaults.R`), conversion des contrôles temporels (`controls.R`).
- Tests : le dossier `tests/` contient infrastructure et tests via `testthat`.

## Points importants pour un rapport

- Décrire le modèle PDE : variables d'état (sains/stuntés), discrétisation âge–masse–temps, termes modélisés (croissance gamma, mortalité, vente, transition stunting `rho`).
- Expliquer le schéma numérique : explicite upwind, conditions aux frontières (approvisionnement en bas âge/mass), stabilité CFL-like vérifiée via `gamma_upper` et checks.
- Présenter les indicateurs économiques calculés (revenu, coût d'achat, coût d'alimentation, coût de mort, profit cumulé, potentiel économique) et les objectifs d'optimisation.
- Documenter les jeux de fonctions paramétriques (gamma1 polynomiale par défaut et possibilité de fournir ses propres fonctions), et la logique de conversion des scalaires/vecteurs en fonctions de temps pour les contrôles.

## Emplacement des éléments utiles pour rédaction

- Code principal : `R/`.
- Documentation Rd : `man/`.
- Scripts d'exemple et données : `inst/extdata/` et `vignettes/`.
- Tests : `tests/testthat/`.

## Préparer le push vers GitHub

J'ai ajouté ce fichier `PACKAGE_REPORT.md` au dépôt. Pour finaliser et pousser vers
`https://github.com/AdrienDEFO/aviculture`, voici les commandes recommandées (exécuter depuis la racine du projet) :

```bash
# afficher la branche courante et la configuration distante
git rev-parse --abbrev-ref HEAD
git remote -v

# ajouter et committer le rapport
git add PACKAGE_REPORT.md
git commit -m "Add PACKAGE_REPORT.md: rapport des méthodes et architecture"

# (si nécessaire) définir ou mettre à jour la remote 'origin'
git remote add origin https://github.com/AdrienDEFO/aviculture || git remote set-url origin https://github.com/AdrienDEFO/aviculture

# pousser sur la branche principale (remplacez 'main' par 'master' si besoin)
git push -u origin main
```

Remarques :
- Le `git push` demandera une authentification (token ou clé SSH selon votre configuration).
- Vérifiez le nom de la branche (souvent `main` ou `master`) et adaptez la commande si nécessaire.

---

Si vous voulez que j'exécute le commit localement et/ou tente le `git push` depuis cet environnement, dites-le et je le ferai (attention aux authentifications interactives). Sinon, je peux créer un petit script `scripts/push_report.sh` pour automatiser ces commandes.
