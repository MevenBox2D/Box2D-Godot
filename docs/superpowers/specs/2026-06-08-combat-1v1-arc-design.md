# Combat 1V1 — Système de base + arme "Arc" (design)

## Contexte

Projet Godot 4.6 utilisant le moteur physique Rapier2D (plugin `addons/godot-rapier2d`).
Objectif : poser les fondations d'un système de combat 1V1 entre personnages-cercles
destiné à produire des vidéos de simulations regardées (façon "physics battle simulator") :
le combat se joue tout seul, IA contre IA, le chaos vient principalement de la physique
(gravité, rebonds, collisions). Chaque personnage a 100 PV de base et possède une arme
spécifique avec ses propres particularités.

Cette première itération vise à valider le pipeline complet (arène, personnage, dégâts,
fin de combat, attache d'arme par joint, animation d'arme, projectile) à travers une
seule arme : **l'arc**. Les autres armes (club, etc.) viendront ensuite en réutilisant
cette base commune.

## Portée de cette spec

Inclus :
- Arène carrée fermée empêchant les personnages d'en sortir.
- Personnage circulaire (corps rigide Rapier), 100 PV, barre de vie visible.
- Système de dégâts générique (`take_damage`) et fin de combat (K.O. à 0 PV).
- Une arme : l'arc, attachée par un joint physique Rapier, qui vise l'adversaire,
  joue une animation de bandage, puis tire une flèche-projectile infligeant des dégâts.
- Spawn des deux personnages à des positions opposées fixes dans l'arène.

Exclus (hors scope, pour itérations futures) :
- Autres types d'armes (club, lance, etc.).
- IA de déplacement actif (le mouvement vient uniquement de la physique : gravité, chocs).
- Multijoueur / contrôle clavier-manette.
- Menus, sélection de personnage, replay, etc.

## Architecture

### 1. Arène

- Scène contenant 4 `RapierStaticBody2D` formant un carré fermé (sol, plafond, murs
  gauche/droite), chacun avec un `CollisionShape2D` rectangulaire.
- Dimensions suffisantes pour laisser les personnages tomber/rebondir sans sortir du cadre
  visible par la caméra.
- Deux marqueurs de spawn (`Marker2D` ou positions codées en dur) à des emplacements
  opposés fixes (ex. coin bas-gauche / coin bas-droit), utilisés à chaque combat.

### 2. Personnage (`Character`)

- Scène basée sur `RapierRigidBody2D` avec :
  - `CollisionShape2D` de forme circulaire (le cercle est à la fois la forme physique
    et la représentation visuelle, via `Sprite2D` ou dessin procédural `_draw`).
  - Un point d'attache (`Marker2D` ou position relative) pour le joint de l'arme.
- Script `character.gd` exposant :
  - `const MAX_HP := 100`
  - `var current_hp: int`
  - `func take_damage(amount: int) -> void` : décrémente `current_hp`, clamp à 0,
    met à jour la barre de vie, émet `hp_changed` ; si `current_hp == 0`, émet `died`.
  - `var opponent: Character` : référence à l'adversaire, assignée par le `GameManager`
    au lancement du combat (sert de cible pour l'arme — "l'adversaire le plus proche"
    se réduit ici à "l'unique adversaire").
- Barre de vie : nœud séparé, **non rattaché à la hiérarchie du corps physique**
  (ex. enfant direct de la scène de combat ou d'un `CanvasLayer`), repositionné chaque
  frame sur la position du personnage (`global_position`) sans copier sa rotation —
  ce qui évite tout calcul de contre-rotation et garde la barre toujours horizontale.

### 3. Arme — Arc (`BowWeapon`)

- Scène attachée au personnage via un `RapierPinJoint2D` (pivot proche du centre du
  cercle), configuré en mode **"Motor Position"** (le joint expose `target_angle`,
  `stiffness`, `damping`) : c'est ce moteur du joint — et non une rotation directe du
  nœud — qui pilote l'orientation de l'arme. Cela permet à l'arme de rester
  physiquement solidaire (réagit aux chocs, débattement limité par `stiffness`/
  `damping`) tout en étant activement orientée par le script. Le script de l'arme se
  contente de mettre à jour `target_angle` selon l'état courant ; le joint se charge
  de la convergence physique vers cet angle.
- Script `bow_weapon.gd` piloté par une **machine à états** :

  | État | Comportement |
  |---|---|
  | `TRACKING` | Met à jour en continu `joint.target_angle` vers la direction de `character.opponent` (le moteur du joint assure une convergence progressive et physiquement plausible). Après un délai/cooldown, transition vers `DRAWING`. |
  | `DRAWING` | Joue une animation (`AnimationPlayer`) de bandage de la corde ; `target_angle` est **figé** à sa dernière valeur (pas de poursuite de cible pendant cette phase, pour un ressenti de "concentration du tir" net et prévisible). À la fin de l'animation, transition vers `FIRING`. |
  | `FIRING` | Instancie une flèche (scène `Arrow`) au niveau de l'encoche, lui applique une vitesse initiale dans la direction visée, puis transition vers `COOLDOWN`. |
  | `COOLDOWN` | Pause avant de revenir en `TRACKING`. |

- Flèche (`Arrow`) :
  - `RapierRigidBody2D` de forme simple (cercle ou capsule), affectée par la gravité
    une fois lancée (trajectoire balistique).
  - Porte une valeur `damage: int` et une zone de détection (`RapierArea2D`) en hitbox.
    `RapierArea2D` étend directement `Area2D` sans redéfinir ses signaux : on utilise
    donc le signal natif `body_entered(body)` pour détecter le contact avec un
    personnage ou un mur, exactement comme avec un `Area2D` standard.
  - **Anti-auto-collision** : la flèche est assignée aux calques de collision
    (`collision_layer`/`collision_mask`) de façon à ignorer son tireur dès
    l'instanciation (elle ne peut entrer en collision qu'avec l'adversaire et les murs
    de l'arène). Au contact d'un personnage adverse : appelle `take_damage(damage)`
    puis se détruit (`queue_free`). Au contact de l'arène : se détruit sans infliger
    de dégâts.

### 4. Système de dégâts et fin de combat

- Flux générique : toute source de dégâts (flèche, futur club, etc.) appelle
  `Character.take_damage(amount)`.
- `GameManager` (script de la scène principale du combat) :
  - Instancie les deux personnages à leurs positions de spawn fixes, assigne
    `opponent` réciproquement.
  - Écoute le signal `died` de chaque personnage.
  - À réception de `died` : désactive les armes (arrêt de la state machine), stoppe
    le combat, affiche un message de victoire pour l'adversaire restant.
  - **Cas du double K.O.** (les deux `died` arrivent dans la même frame, ex. deux
    flèches simultanées) : le combat se termine sur un **match nul**, signalé par un
    message dédié plutôt qu'une "victoire" — aucun des deux personnages n'est désigné
    vainqueur.

## Paramètres à calibrer expérimentalement

Cette spec ne fixe pas de valeurs numériques précises : elles devront être ajustées
en jeu pour obtenir un combat lisible et intéressant à regarder. À exposer comme
constantes/`@export` facilement réglables :
- Dégâts par flèche (`damage`), vitesse initiale du projectile.
- Durées des états `TRACKING` (avant bandage), `DRAWING` (durée de l'animation),
  `COOLDOWN` (avant de reviser).
- `stiffness`/`damping` du joint de l'arme (réactivité vs stabilité du tracking).
- Dimensions de l'arène et distance entre les deux points de spawn.

## Notes d'implémentation

- Toutes les interactions physiques (corps, joints, zones) utilisent les nœuds du
  plugin Rapier2D déjà présents (`RapierRigidBody2D`, `RapierStaticBody2D`,
  `RapierPinJoint2D`, `RapierArea2D`) plutôt que les nœuds physiques natifs de Godot,
  pour rester cohérent avec la configuration du projet (`2d/physics_engine="Rapier2D"`).
- La structure (Character / Weapon attaché par joint / state machine / projectile)
  est conçue pour être réutilisée telle quelle par les futures armes (club, etc.),
  qui n'auront qu'à définir leurs propres états et leur propre logique de dégâts.
