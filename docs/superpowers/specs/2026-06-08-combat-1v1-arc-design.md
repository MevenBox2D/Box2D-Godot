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
- Barre de vie : nœud enfant (ex. `TextureProgressBar` ou `ProgressBar` dans un
  `Node2D`) positionné au-dessus du cercle, dont la rotation est compensée pour rester
  horizontale indépendamment de la rotation physique du corps.

### 3. Arme — Arc (`BowWeapon`)

- Scène attachée au personnage via un `RapierPinJoint2D` (pivot proche du centre du
  cercle), ce qui permet à l'arme physiquement de réagir aux chocs (léger débattement)
  tout en restant globalement solidaire du personnage.
- Script `bow_weapon.gd` piloté par une **machine à états** :

  | État | Comportement |
  |---|---|
  | `TRACKING` | Interpole en douceur (`lerp_angle`) la rotation de l'arme vers la position de `character.opponent`. Après un délai/cooldown, transition vers `DRAWING`. |
  | `DRAWING` | Joue une animation (`AnimationPlayer`) de bandage de la corde ; le suivi de la cible est figé ou ralenti pour mimer la concentration du tir. À la fin de l'animation, transition vers `FIRING`. |
  | `FIRING` | Instancie une flèche (scène `Arrow`) au niveau de l'encoche, lui applique une vitesse initiale dans la direction visée, puis transition vers `COOLDOWN`. |
  | `COOLDOWN` | Pause avant de revenir en `TRACKING`. |

- Flèche (`Arrow`) :
  - `RapierRigidBody2D` de forme simple (cercle ou capsule), affectée par la gravité
    une fois lancée (trajectoire balistique).
  - Porte une valeur `damage: int` et une zone de détection (`RapierArea2D`) en hitbox.
  - Au contact d'un personnage adverse : appelle `take_damage(damage)` sur celui-ci,
    puis se détruit (`queue_free`). Au contact de l'arène ou de son propriétaire,
    se détruit également sans infliger de dégâts.

### 4. Système de dégâts et fin de combat

- Flux générique : toute source de dégâts (flèche, futur club, etc.) appelle
  `Character.take_damage(amount)`.
- `GameManager` (script de la scène principale du combat) :
  - Instancie les deux personnages à leurs positions de spawn fixes, assigne
    `opponent` réciproquement.
  - Écoute le signal `died` de chaque personnage.
  - À réception de `died` : désactive les armes (arrêt de la state machine), stoppe
    le combat, affiche un message de victoire pour l'adversaire restant.

## Notes d'implémentation

- Toutes les interactions physiques (corps, joints, zones) utilisent les nœuds du
  plugin Rapier2D déjà présents (`RapierRigidBody2D`, `RapierStaticBody2D`,
  `RapierPinJoint2D`, `RapierArea2D`) plutôt que les nœuds physiques natifs de Godot,
  pour rester cohérent avec la configuration du projet (`2d/physics_engine="Rapier2D"`).
- La structure (Character / Weapon attaché par joint / state machine / projectile)
  est conçue pour être réutilisée telle quelle par les futures armes (club, etc.),
  qui n'auront qu'à définir leurs propres états et leur propre logique de dégâts.
