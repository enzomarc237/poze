# Plan de développement pour l'application Poze

## Aperçu du projet
Poze est une application Flutter pour macOS qui permet de gérer les processus en cours d'exécution sur le système. Elle offre la possibilité de visualiser les applications actives, leur utilisation du processeur, ainsi que de mettre en pause et de reprendre ces applications.

## Fonctionnalités principales
1. Lister toutes les applications en cours d'exécution
2. Afficher le pourcentage d'utilisation du processeur pour chaque application
3. Mettre en pause une application via la commande "killall -STOP"
4. Sortir une application de la pause via la commande "killall -CONT"

## Structure du projet

```
lib/
├── main.dart                  # Point d'entrée de l'application
├── app.dart                   # Configuration de l'application
├── models/
│   ├── process_model.dart     # Modèle de données pour les processus
│   └── system_stats.dart      # Modèle pour les statistiques système
├── services/
│   ├── process_service.dart   # Service pour interagir avec les processus
│   └── system_service.dart    # Service pour obtenir les stats système
├── views/
│   ├── home_view.dart         # Vue principale
│   └── settings_view.dart     # Vue des paramètres (optionnelle)
└── widgets/
    ├── process_list_item.dart # Widget pour afficher un processus
    ├── cpu_usage_chart.dart   # Widget pour afficher l'usage CPU
    └── control_buttons.dart   # Widgets pour les actions (pause/reprise)
```

## Dépendances requises
```yaml
dependencies:
  flutter:
    sdk: flutter
  macos_ui: ^2.0.0            # UI style macOS
  process_run: ^0.14.0        # Pour exécuter des commandes shell
  charts_flutter: ^0.12.0     # Pour les graphiques de CPU (optionnel)
  provider: ^6.1.1            # Pour la gestion d'état
```

## Étapes d'implémentation

### Phase 1: Configuration initiale
1. Configurer le projet avec les dépendances nécessaires
2. Créer la structure de base de l'application avec macos_ui
3. Implémenter l'interface utilisateur selon le design fourni

### Phase 2: Fonctionnalités de base
1. Implémenter le service pour lister les processus en cours (via `ps` ou autre commande système)
2. Créer le modèle de données pour représenter les processus
3. Développer l'interface pour afficher la liste des processus

### Phase 3: Fonctionnalités avancées
1. Ajouter la fonctionnalité pour obtenir l'utilisation CPU par processus
2. Implémenter les commandes pour mettre en pause (`killall -STOP`) et reprendre (`killall -CONT`) les processus
3. Créer les contrôles UI pour ces actions

### Phase 4: Améliorations et finition
1. Peaufiner l'interface utilisateur
2. Ajouter des animations et transitions
3. Optimiser les performances et la réactivité
4. Tests et corrections des bugs

## Détails techniques

### Commandes système utilisées
- `ps aux` - Pour lister les processus
- `top -l 1 -stats pid,command,cpu` - Pour obtenir l'utilisation CPU
- `killall -STOP [processName]` - Pour mettre en pause un processus
- `killall -CONT [processName]` - Pour sortir un processus de la pause

### Considérations pour macOS
- Demander les permissions nécessaires pour accéder aux informations système
- Vérifier la compatibilité avec les différentes versions de macOS
- S'assurer que l'application fonctionne correctement dans un environnement de sandbox

## Interface utilisateur
Basée sur l'image fournie, l'interface aura:
- Une barre latérale avec les différentes catégories ou vues
- Une liste principale des processus avec:
  - Icône/identifiant du processus
  - Nom du processus
  - Description ou détails supplémentaires
  - Boutons de contrôle (pause/reprise)
  - Indicateur d'utilisation CPU
- Des contrôles de filtrage et de tri

## Prochaines étapes potentielles
- Ajout d'une fonctionnalité de recherche
- Support pour les notifications
- Historique d'utilisation du CPU
- Profils de gestion de processus personnalisés