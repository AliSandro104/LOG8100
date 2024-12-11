# LOG8100 - DevSecOps

## Introduction

Ce projet dans le cadre du cours LOG8100: DevSecOps consiste à automatiser le déploiement de l'application OWASP WebGoat (https://github.com/WebGoat/WebGoat) à l'aide d'une pipeline CI/CD.

Les objectifs principaux de ce projet sont:

- La configuration d'un cluster Kubernetes en utilisant Terraform et Ansible.
- L'automatisation des builds et déploiements avec GitHub Actions.
- L'intégration des tests de sécurité statiques et dynamiques.
- La surveillance et l'optimisation des performances et des coûts avec Prometheus, Grafana, et Kubecost.

**Auteurs principaux:** Louis Lalonde [@louislalonde](https://github.com/LouisLalonde), Andy Chen [@AnOddWobbuffet](https://github.com/AnOddWobbuffet) and Ali Hazime [@AliSandro104](https://github.com/AliSandro104)

## Outils utilisés

- Terraform : Automatisation de l'infrastructure en tant que code (IaC).
- Ansible : Gestion des configurations et déploiements automatisés.
- Docker : Création d'images et de conteneurs.
- Trivy : Scan de vulnérabilités pour les images Docker.
- Dependabot : Gestion et mise à jour automatique des dépendances.
- SonarLint : Analyse locale du code pour amélioration de qualité et sécurité.
- SonarQube : Tests statiques pour l'analyse de vulnérabilités du code.
- OWASP ZAP : Tests de sécurité dynamiques sur les applications déployées.
- Checkov : Analyse des configurations Terraform et Ansible pour détecter les problèmes de sécurité.
- Helm : Gestion des applications Kubernetes.
- Prometheus : Surveillance et collecte des métriques.
- Prometheus Alertmanager : Envoi d'alertes dépendemment des métriques.
- Discord : Configuration pour recevoir les alertes de Prometheus Alertmanager.
- Grafana : Visualisation des données de performance.
- Kubecost : Suivi et optimisation des coûts Kubernetes.
- GitHub CLI (gh) : Interaction avec les dépôts GitHub depuis la ligne de commande.

## 1. Intégration continue (Environnement Dev)

- Versionnage et gestion de code avec Github
- Analyse statique du code durant le développement avec SonarLint

Après que les modifications au projet sont intégrées sur le dépôt Github dans une branche de développement, la pipeline configurée sur Github réalise les étapes suivantes:

- Analyse des dépendences vulnérables avec Dependabot
- Analyse statique avec SonarQube

## 2. Livraison continue (Environnement Staging)

Après qu'une branche de développement soit intégrée sur une branche Release avec un Pull Request, la pipeline configurée sur Github réalise les étapes suivantes:

- Construction d'image Docker
- Scan de vulnérabilités sur l'image et génération d'un rapport à l'aide de Trivy
- Déploiement automatique des conteneurs avec Ansible (voir le dossier ansible/..) dans l'environnement Staging
- Tests dynamiques de sécurité sur le conteneur de l'application avec OWASP ZAP

## 3. Déploiement Continu

Après qu'une branche Release soit intégrée sur la branche principale avec un Pull Request, la pipeline configurée sur Github réalise les étapes suivantes:

- Construction d'image Docker
- Scan de vulnérabilités sur l'image à l'aide de Trivy
- Si le scan ne détecte aucune vulnérabilité critique, le tag Release est créée sur Github

Azure est utilisé pour l'hébergement Cloud des clusters Kubernetes dont l'infrastructure est déterminée par les configurations de Terraform (voir le dossier terraform/..). Une fois que le déploiement est effectué, de la surveillance continue des coûts et des métriques est effectuée à l'aide de Prometheus, Grafana et Kubecost. Prometheus Alertmanager envoie des alertes à l'aide d'un webhook Discord lorsque certaines métriques atteignent des seuils prédéfinis pour l'application déployée.

## 4. Étapes de déploiement

Développement:

1. Cloner le repo (git clone https://github.com/AliSandro104/LOG8100.git)
2. Création de branche de développement (git checkout -b'dev-branch')
3. Ajout de fichiers modifiés au commit (git add .)
4. Commit (git commit -m'modifications')
5. Pousser sur le dépôt distant (git push).

Staging:

1. Création de branche release/0.0.x sur le dépôt Github
2. Créer un pull request pour fusionner la branche de développement sur la branche release/0.0.x

Production:

1. Créer un pull request pour fusionner la branche release/0.0.x sur la branche master
