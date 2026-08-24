# Projet_Stage_DEVOX

## Projet de Stage en entreprise (DEVOX Rabat)


### Installer et lancer le projet :

Pour récupérer et lancer cette solution de monitoring, suivre les étapes suivantes :

### Étape 1 : Clonage du repo Github sur le serveur cible

```bash
git clone https://github.com/Sparrow0245/Projet_Stage_DEVOX
```


### Étape 2 : Aller dans le bon sous dossier

```bash
cd Projet_Stage_DEVOX/script_lancement
```


### Étape 3 : Rendre exécutable le script d'installation `lancement.sh`

```bash
chmod +x lancement.sh
```

### Étape 4 : Lancer le script pour installer et déployer la solution Sentinelle

```bash
sudo ./lancement.sh
```

### Étape 5 : Ouvrir un navigateur et taper l'adresse pour afficher l'écran de monitoring de Sentinelle

```http
http://localhost:8080/index.php
```

___


### Désinstaller le projet :

Pour désinstaller le projet, il suffit de lancer le script de désinstallation nommé `09_desinstallation.sh`. Pour cela voici les étapes à suivre :


### Étape 1 : Aller dans le bon sous dossier

```bash
cd Projet_Stage_DEVOX/script_lancement
```

### Étape 2 : Rendre exécutable le script de désinstallation `09_desinstallation.sh`

```bash
chmod +x 09_desinstallation.sh
```

### Étape 3 : Lancer le script de désinstallation `09_desinstallation.sh`

```bash
sudo ./09_desinstallation.sh
```
Confirmer la désinstallation en appuyant sur "O" pour "Oui".
