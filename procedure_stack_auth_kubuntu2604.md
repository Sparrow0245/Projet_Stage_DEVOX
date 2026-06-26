# Procédure : Page d'authentification web — Stack Java 21 / Spring Boot / Vue.js / MongoDB 8

> **Environnement cible :** Kubuntu 26.04 LTS (Resolute Raccoon)  
> **Objectif :** Mettre en place en local une application web d'authentification (login/register) avec un backend Java Spring Boot et un frontend Vue.js, reliés à une base MongoDB.  
> **Niveau :** Débutant accompagné — chaque commande est expliquée.

---

## Sommaire

1. [Comprendre l'architecture](#1-comprendre-larchitecture)
2. [Mettre à jour le système](#2-mettre-à-jour-le-système)
3. [Installer Java 21 (JDK)](#3-installer-java-21-jdk)
4. [Installer Maven (outil de build Java)](#4-installer-maven-outil-de-build-java)
5. [Tester Java : compiler et exécuter un fichier `.java`](#5-tester-java--compiler-et-exécuter-un-fichier-java)
6. [Installer Node.js 22](#6-installer-nodejs-22)
7. [Installer MongoDB 8](#7-installer-mongodb-8)
8. [Créer le projet backend Spring Boot](#8-créer-le-projet-backend-spring-boot)
9. [Coder le backend : modèle, repository, service, contrôleur](#9-coder-le-backend--modèle-repository-service-contrôleur)
10. [Lancer et tester le backend](#10-lancer-et-tester-le-backend)
11. [Créer le projet frontend Vue.js](#11-créer-le-projet-frontend-vuejs)
12. [Coder la page de connexion en Vue.js](#12-coder-la-page-de-connexion-en-vuejs)
13. [Lancer et tester l'application complète](#13-lancer-et-tester-lapplication-complète)
14. [Récapitulatif des commandes clés](#14-récapitulatif-des-commandes-clés)

---

## 1. Comprendre l'architecture

Avant de taper la moindre commande, voici comment les briques s'articulent :

```
[Navigateur]
     │
     │  HTTP (port 5173)
     ▼
[Frontend — Vue.js]       ← Interface utilisateur (formulaire login/register)
     │
     │  HTTP/API REST (port 8080)
     ▼
[Backend — Spring Boot]   ← Logique métier : vérification identifiants, JWT...
     │
     │  Protocole MongoDB (port 27017)
     ▼
[Base de données — MongoDB 8]  ← Stockage des utilisateurs
```

**Vocabulaire à retenir :**

| Terme | Rôle |
|---|---|
| **Spring Boot** | Framework Java qui crée un serveur web (API REST) en quelques lignes |
| **Vue.js** | Framework JavaScript qui génère l'interface HTML dans le navigateur |
| **MongoDB** | Base de données NoSQL : stocke les données sous forme de documents JSON |
| **API REST** | Interface de communication entre frontend et backend via des URLs HTTP |
| **Maven** | Outil Java qui télécharge les dépendances et compile le projet |
| **npm** | Même chose que Maven, mais pour Node.js/JavaScript |

---

## 2. Mettre à jour le système

Toujours commencer par synchroniser les listes de paquets disponibles.

```bash
sudo apt update && sudo apt upgrade -y
```

**Explication :**
- `sudo` : exécuter en tant qu'administrateur
- `apt update` : recharger la liste des paquets disponibles
- `apt upgrade -y` : installer les mises à jour, `-y` confirme automatiquement

---

## 3. Installer Java 21 (JDK)

Le **JDK** (Java Development Kit) contient tout ce qu'il faut pour compiler et exécuter du Java : le compilateur `javac` et la machine virtuelle `java`.

```bash
sudo apt install -y openjdk-21-jdk
```

**Vérification :**

```bash
java --version
javac --version
```

Tu devrais voir quelque chose comme :

```
openjdk 21.0.x ...
javac 21.0.x
```

**Configurer la variable JAVA_HOME** (requise par Spring Boot et Maven) :

```bash
echo 'JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"' | sudo tee -a /etc/environment
source /etc/environment
echo $JAVA_HOME
```

- `JAVA_HOME` : variable d'environnement qui indique aux outils où se trouve le JDK.
- `source /etc/environment` : recharge le fichier dans le terminal courant.

> **Note :** Si `echo $JAVA_HOME` ne retourne rien, ferme et rouvre ton terminal.

---

## 4. Installer Maven (outil de build Java)

Maven télécharge les bibliothèques Java (Spring Boot, etc.) et compile ton projet.

```bash
sudo apt install -y maven
```

**Vérification :**

```bash
mvn --version
```

Résultat attendu : `Apache Maven 3.x.x ...`

---

## 5. Tester Java : compiler et exécuter un fichier `.java`

Avant d'aller plus loin, voici comment créer, compiler et exécuter un programme Java depuis le terminal — une compétence de base à maîtriser.

### Créer un fichier Java

```bash
mkdir -p ~/test-java && cd ~/test-java
nano Bonjour.java
```

Colle ce contenu dans l'éditeur `nano` :

```java
public class Bonjour {
    public static void main(String[] args) {
        System.out.println("Bonjour depuis Java 21 !");
    }
}
```

Sauvegarde avec `Ctrl+O`, `Entrée`, puis quitte avec `Ctrl+X`.

### Compiler le fichier

```bash
javac Bonjour.java
```

Cette commande produit un fichier `Bonjour.class` (bytecode Java).

### Exécuter le programme

```bash
java Bonjour
```

Résultat attendu :

```
Bonjour depuis Java 21 !
```

**Résumé des commandes Java de base :**

| Commande | Action |
|---|---|
| `javac MonFichier.java` | Compile le fichier source en bytecode |
| `java NomDeLaClasse` | Exécute le bytecode (sans `.class`) |
| `java --version` | Affiche la version Java installée |

---

## 6. Installer Node.js 22

Node.js est le moteur d'exécution JavaScript côté serveur. Il est aussi utilisé pour les outils de développement Vue.js.

**Bonne nouvelle :** Ubuntu 26.04 inclut Node.js 22 dans ses dépôts officiels.

```bash
sudo apt install -y nodejs npm
```

**Vérification :**

```bash
node --version   # doit afficher v22.x.x
npm --version
```

> **Alternative si la version n'est pas 22 :** utiliser NodeSource.
> ```bash
> sudo mkdir -p /etc/apt/keyrings
> curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
> echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
> sudo apt update && sudo apt install -y nodejs
> ```

---

## 7. Installer MongoDB 8

> **Contexte technique important :** En juin 2026, MongoDB Inc. ne publie pas encore de dépôt natif pour Ubuntu 26.04. Le contournement stable documenté consiste à utiliser le dépôt `noble` (Ubuntu 24.04), qui fonctionne sur Ubuntu 26.04. Cette méthode est utilisée par plusieurs sources techniques récentes (RoseHosting, PhoenixNAP, Progressive Robot — mai 2026).

### Étape 7.1 — Installer les prérequis

```bash
sudo apt install -y gnupg curl
```

### Étape 7.2 — Importer la clé GPG officielle de MongoDB

La clé GPG permet à `apt` de vérifier que les paquets MongoDB sont authentiques.

```bash
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
  sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
```

**Explication :**
- `curl -fsSL` : télécharge la clé silencieusement
- `gpg --dearmor` : convertit la clé au format binaire attendu par `apt`
- `-o /usr/share/keyrings/...` : enregistre la clé dans le dossier système dédié

### Étape 7.3 — Ajouter le dépôt MongoDB (workaround noble)

```bash
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] \
https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | \
sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```

**Explication :**
- `noble` : codename d'Ubuntu 24.04, compatible avec Ubuntu 26.04
- `mongodb-org/8.0` : branche MongoDB 8.0 (satisfait ton exigence "7 ou plus")
- `multiverse` : section du dépôt contenant les logiciels tiers

### Étape 7.4 — Installer MongoDB

```bash
sudo apt update
sudo apt install -y mongodb-org
```

### Étape 7.5 — Démarrer MongoDB et l'activer au démarrage

```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```

**Vérification :**

```bash
sudo systemctl status mongod
```

Tu dois voir `Active: active (running)`.

**Test depuis le shell MongoDB :**

```bash
mongosh
```

Dans le shell, tape :

```js
db.runCommand({ ping: 1 })
```

Résultat attendu : `{ ok: 1 }`. Quitte avec `exit`.

---

## 8. Créer le projet backend Spring Boot

Spring Boot est un framework Java qui simplifie la création d'API REST.

### Méthode recommandée : Spring Initializr en ligne de commande

```bash
cd ~
curl https://start.spring.io/starter.tgz \
  -d type=maven-project \
  -d language=java \
  -d bootVersion=3.3.0 \
  -d baseDir=auth-backend \
  -d groupId=com.monprojet \
  -d artifactId=auth-backend \
  -d name=auth-backend \
  -d dependencies=web,data-mongodb,security \
  -d javaVersion=21 | tar -xzvf -
```

**Explication des paramètres :**
- `type=maven-project` : utilise Maven comme outil de build
- `bootVersion=3.3.0` : version stable de Spring Boot compatible Java 21
- `dependencies=web,data-mongodb,security` : les modules nécessaires :
  - `web` : pour créer des API REST
  - `data-mongodb` : pour parler à MongoDB
  - `security` : pour gérer l'authentification

```bash
cd auth-backend
```

### Structure du projet générée

```
auth-backend/
├── pom.xml                          ← Fichier de configuration Maven (dépendances)
└── src/
    └── main/
        ├── java/com/monprojet/auth_backend/
        │   └── AuthBackendApplication.java  ← Point d'entrée de l'application
        └── resources/
            └── application.properties       ← Configuration (BDD, port...)
```

### Configurer la connexion MongoDB

Édite le fichier `src/main/resources/application.properties` :

```bash
nano src/main/resources/application.properties
```

Contenu à mettre :

```properties
# Port du serveur Spring Boot
server.port=8080

# Connexion MongoDB locale (pas d'authentification en local)
spring.data.mongodb.host=localhost
spring.data.mongodb.port=27017
spring.data.mongodb.database=auth_db

# Désactiver temporairement la sécurité Spring pour les tests initiaux
spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration
```

> **Pourquoi désactiver la sécurité ?** Spring Security bloque tout par défaut. On la désactive temporairement pour tester l'API facilement, puis on la réactivera.

---

## 9. Coder le backend : modèle, repository, service, contrôleur

Crée les dossiers nécessaires :

```bash
mkdir -p src/main/java/com/monprojet/auth_backend/{model,repository,service,controller,dto}
```

### 9.1 — Le modèle `User.java`

Le modèle représente la structure d'un utilisateur en base de données.

```bash
nano src/main/java/com/monprojet/auth_backend/model/User.java
```

```java
package com.monprojet.auth_backend.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.index.Indexed;

@Document(collection = "users")   // nom de la collection MongoDB
public class User {

    @Id
    private String id;             // identifiant unique généré par MongoDB

    @Indexed(unique = true)        // l'email doit être unique en base
    private String email;

    private String password;       // sera haché (jamais en clair !)

    private String username;

    // Constructeur vide (requis par Spring)
    public User() {}

    // Getters et Setters
    public String getId() { return id; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
}
```

### 9.2 — Le repository `UserRepository.java`

Le repository fournit les opérations de base sur la BDD (trouver, sauvegarder...).

```bash
nano src/main/java/com/monprojet/auth_backend/repository/UserRepository.java
```

```java
package com.monprojet.auth_backend.repository;

import com.monprojet.auth_backend.model.User;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

// MongoRepository<User, String> : gère des objets User dont l'ID est un String
public interface UserRepository extends MongoRepository<User, String> {

    // Spring génère automatiquement le code SQL/MongoDB pour cette méthode
    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);
}
```

### 9.3 — Les DTOs (objets de transfert de données)

Les DTOs représentent les données reçues depuis le frontend (formulaire).

```bash
nano src/main/java/com/monprojet/auth_backend/dto/RegisterRequest.java
```

```java
package com.monprojet.auth_backend.dto;

public class RegisterRequest {
    private String username;
    private String email;
    private String password;

    // Getters et Setters
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
}
```

```bash
nano src/main/java/com/monprojet/auth_backend/dto/LoginRequest.java
```

```java
package com.monprojet.auth_backend.dto;

public class LoginRequest {
    private String email;
    private String password;

    // Getters et Setters
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
}
```

### 9.4 — Le service `AuthService.java`

Le service contient la logique métier (hachage du mot de passe, vérification...).

```bash
nano src/main/java/com/monprojet/auth_backend/service/AuthService.java
```

```java
package com.monprojet.auth_backend.service;

import com.monprojet.auth_backend.dto.LoginRequest;
import com.monprojet.auth_backend.dto.RegisterRequest;
import com.monprojet.auth_backend.model.User;
import com.monprojet.auth_backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

@Service  // indique à Spring que c'est un service injectable
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    // BCrypt est l'algorithme standard pour hacher les mots de passe
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public String register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            return "EMAIL_EXISTS";
        }

        User user = new User();
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());
        // IMPORTANT : on ne stocke jamais le mot de passe en clair
        user.setPassword(passwordEncoder.encode(request.getPassword()));

        userRepository.save(user);
        return "SUCCESS";
    }

    public String login(LoginRequest request) {
        return userRepository.findByEmail(request.getEmail())
            .map(user -> {
                // Comparer le mot de passe fourni avec le hash en BDD
                if (passwordEncoder.matches(request.getPassword(), user.getPassword())) {
                    return "SUCCESS";
                }
                return "WRONG_PASSWORD";
            })
            .orElse("USER_NOT_FOUND");
    }
}
```

### 9.5 — Le contrôleur `AuthController.java`

Le contrôleur expose les endpoints HTTP que le frontend appellera.

```bash
nano src/main/java/com/monprojet/auth_backend/controller/AuthController.java
```

```java
package com.monprojet.auth_backend.controller;

import com.monprojet.auth_backend.dto.LoginRequest;
import com.monprojet.auth_backend.dto.RegisterRequest;
import com.monprojet.auth_backend.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController             // indique que c'est un contrôleur REST (retourne du JSON)
@RequestMapping("/api/auth") // préfixe de toutes les routes de ce contrôleur
@CrossOrigin(origins = "http://localhost:5173")  // autorise les requêtes depuis Vue.js
public class AuthController {

    @Autowired
    private AuthService authService;

    // POST /api/auth/register
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        String result = authService.register(request);
        return switch (result) {
            case "SUCCESS"      -> ResponseEntity.ok(Map.of("message", "Compte créé avec succès"));
            case "EMAIL_EXISTS" -> ResponseEntity.badRequest().body(Map.of("error", "Email déjà utilisé"));
            default             -> ResponseEntity.internalServerError().build();
        };
    }

    // POST /api/auth/login
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        String result = authService.login(request);
        return switch (result) {
            case "SUCCESS"       -> ResponseEntity.ok(Map.of("message", "Connexion réussie"));
            case "WRONG_PASSWORD"-> ResponseEntity.badRequest().body(Map.of("error", "Mot de passe incorrect"));
            case "USER_NOT_FOUND"-> ResponseEntity.badRequest().body(Map.of("error", "Utilisateur introuvable"));
            default              -> ResponseEntity.internalServerError().build();
        };
    }
}
```

### 9.6 — Ajouter BCrypt dans `pom.xml`

Spring Security (déjà inclus) fournit BCrypt. Mais comme on a désactivé la config auto de sécurité dans `application.properties`, on doit quand même déclarer Spring Security dans le `pom.xml` pour avoir accès à `BCryptPasswordEncoder`. Il est déjà là (inclus via `dependencies=security` à la génération).

Vérifie que `pom.xml` contient bien :

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

---

## 10. Lancer et tester le backend

### Compiler et démarrer le serveur

```bash
# Depuis le dossier auth-backend/
mvn spring-boot:run
```

La première fois, Maven télécharge toutes les dépendances (peut prendre 2-3 min). Tu verras :

```
Started AuthBackendApplication in X.XXX seconds
```

Le serveur tourne sur `http://localhost:8080`.

### Tester avec curl (dans un autre terminal)

**Test inscription :**

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"Wassim","email":"wassim@test.com","password":"motdepasse123"}'
```

Réponse attendue : `{"message":"Compte créé avec succès"}`

**Test connexion :**

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"wassim@test.com","password":"motdepasse123"}'
```

Réponse attendue : `{"message":"Connexion réussie"}`

**Vérifier en base MongoDB :**

```bash
mongosh
use auth_db
db.users.find().pretty()
```

Tu verras l'utilisateur créé, avec le mot de passe haché (jamais en clair).

---

## 11. Créer le projet frontend Vue.js

Ouvre un **nouveau terminal** (laisse Spring Boot tourner dans l'autre).

```bash
cd ~
npm create vue@latest auth-frontend
```

L'assistant te posera des questions. Réponds ainsi :

```
✔ Project name: auth-frontend
✔ Add TypeScript? → No
✔ Add JSX Support? → No
✔ Add Vue Router? → Yes   ← important pour naviguer entre les pages
✔ Add Pinia? → No
✔ Add Vitest? → No
✔ Add ESLint? → Yes
✔ Add Prettier? → No
```

```bash
cd auth-frontend
npm install
```

**Installer Axios** (bibliothèque pour faire des requêtes HTTP depuis Vue.js) :

```bash
npm install axios
```

### Structure du projet Vue générée

```
auth-frontend/
├── package.json          ← Dépendances npm
├── vite.config.js        ← Config du serveur de développement
└── src/
    ├── main.js           ← Point d'entrée
    ├── App.vue           ← Composant racine
    ├── router/
    │   └── index.js      ← Définition des routes (URLs)
    └── views/            ← Pages de l'application
```

---

## 12. Coder la page de connexion en Vue.js

### 12.1 — Configurer le routeur

Édite `src/router/index.js` :

```bash
nano src/router/index.js
```

```javascript
import { createRouter, createWebHistory } from 'vue-router'
import LoginView from '../views/LoginView.vue'
import RegisterView from '../views/RegisterView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/',         redirect: '/login' },
    { path: '/login',    component: LoginView },
    { path: '/register', component: RegisterView }
  ]
})

export default router
```

### 12.2 — Créer un service API centralisé

```bash
mkdir -p src/services
nano src/services/authService.js
```

```javascript
import axios from 'axios'

// URL de base de l'API backend
const API_URL = 'http://localhost:8080/api/auth'

export const authService = {

  async login(email, password) {
    const response = await axios.post(`${API_URL}/login`, { email, password })
    return response.data
  },

  async register(username, email, password) {
    const response = await axios.post(`${API_URL}/register`, { username, email, password })
    return response.data
  }
}
```

### 12.3 — Créer la page de connexion `LoginView.vue`

```bash
nano src/views/LoginView.vue
```

```vue
<template>
  <div class="auth-container">
    <div class="auth-card">
      <h1>Connexion</h1>

      <!-- Message d'erreur ou de succès -->
      <div v-if="message" :class="['message', messageType]">
        {{ message }}
      </div>

      <!-- Formulaire de connexion -->
      <form @submit.prevent="handleLogin">
        <div class="form-group">
          <label for="email">Email</label>
          <input
            id="email"
            v-model="email"
            type="email"
            placeholder="votre@email.com"
            required
          />
        </div>

        <div class="form-group">
          <label for="password">Mot de passe</label>
          <input
            id="password"
            v-model="password"
            type="password"
            placeholder="••••••••"
            required
          />
        </div>

        <button type="submit" :disabled="loading">
          {{ loading ? 'Connexion...' : 'Se connecter' }}
        </button>
      </form>

      <p class="link-text">
        Pas encore de compte ?
        <router-link to="/register">S'inscrire</router-link>
      </p>
    </div>
  </div>
</template>

<script>
import { authService } from '../services/authService'

export default {
  name: 'LoginView',
  data() {
    return {
      email: '',
      password: '',
      message: '',
      messageType: '',
      loading: false
    }
  },
  methods: {
    async handleLogin() {
      this.loading = true
      this.message = ''

      try {
        const data = await authService.login(this.email, this.password)
        this.message = data.message || 'Connexion réussie !'
        this.messageType = 'success'
        // Ici on pourrait rediriger : this.$router.push('/dashboard')
      } catch (error) {
        this.message = error.response?.data?.error || 'Erreur de connexion'
        this.messageType = 'error'
      } finally {
        this.loading = false
      }
    }
  }
}
</script>

<style scoped>
.auth-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f0f2f5;
}

.auth-card {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 400px;
}

h1 {
  text-align: center;
  margin-bottom: 1.5rem;
  color: #333;
}

.form-group {
  margin-bottom: 1rem;
}

label {
  display: block;
  margin-bottom: 0.3rem;
  color: #555;
  font-size: 0.9rem;
}

input {
  width: 100%;
  padding: 0.6rem 0.8rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
  box-sizing: border-box;
}

input:focus {
  outline: none;
  border-color: #4a90e2;
}

button {
  width: 100%;
  padding: 0.75rem;
  background-color: #4a90e2;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  margin-top: 0.5rem;
}

button:hover:not(:disabled) {
  background-color: #357abd;
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.message {
  padding: 0.75rem;
  border-radius: 4px;
  margin-bottom: 1rem;
  text-align: center;
}

.success {
  background-color: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.error {
  background-color: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

.link-text {
  text-align: center;
  margin-top: 1rem;
  color: #666;
}

.link-text a {
  color: #4a90e2;
  text-decoration: none;
}
</style>
```

### 12.4 — Créer la page d'inscription `RegisterView.vue`

```bash
nano src/views/RegisterView.vue
```

```vue
<template>
  <div class="auth-container">
    <div class="auth-card">
      <h1>Inscription</h1>

      <div v-if="message" :class="['message', messageType]">
        {{ message }}
      </div>

      <form @submit.prevent="handleRegister">
        <div class="form-group">
          <label for="username">Nom d'utilisateur</label>
          <input
            id="username"
            v-model="username"
            type="text"
            placeholder="MonPseudo"
            required
          />
        </div>

        <div class="form-group">
          <label for="email">Email</label>
          <input
            id="email"
            v-model="email"
            type="email"
            placeholder="votre@email.com"
            required
          />
        </div>

        <div class="form-group">
          <label for="password">Mot de passe</label>
          <input
            id="password"
            v-model="password"
            type="password"
            placeholder="Minimum 6 caractères"
            minlength="6"
            required
          />
        </div>

        <button type="submit" :disabled="loading">
          {{ loading ? 'Création...' : 'Créer un compte' }}
        </button>
      </form>

      <p class="link-text">
        Déjà un compte ?
        <router-link to="/login">Se connecter</router-link>
      </p>
    </div>
  </div>
</template>

<script>
import { authService } from '../services/authService'

export default {
  name: 'RegisterView',
  data() {
    return {
      username: '',
      email: '',
      password: '',
      message: '',
      messageType: '',
      loading: false
    }
  },
  methods: {
    async handleRegister() {
      this.loading = true
      this.message = ''

      try {
        const data = await authService.register(this.username, this.email, this.password)
        this.message = data.message || 'Compte créé avec succès !'
        this.messageType = 'success'
        // Redirection vers login après 2 secondes
        setTimeout(() => this.$router.push('/login'), 2000)
      } catch (error) {
        this.message = error.response?.data?.error || 'Erreur lors de l\'inscription'
        this.messageType = 'error'
      } finally {
        this.loading = false
      }
    }
  }
}
</script>

<!-- Réutilisation des mêmes styles que LoginView -->
<style scoped>
/* Copier/coller les styles de LoginView.vue ici, ou les externaliser dans un fichier CSS global */
.auth-container { min-height: 100vh; display: flex; align-items: center; justify-content: center; background-color: #f0f2f5; }
.auth-card { background: white; padding: 2rem; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); width: 100%; max-width: 400px; }
h1 { text-align: center; margin-bottom: 1.5rem; color: #333; }
.form-group { margin-bottom: 1rem; }
label { display: block; margin-bottom: 0.3rem; color: #555; font-size: 0.9rem; }
input { width: 100%; padding: 0.6rem 0.8rem; border: 1px solid #ddd; border-radius: 4px; font-size: 1rem; box-sizing: border-box; }
input:focus { outline: none; border-color: #4a90e2; }
button { width: 100%; padding: 0.75rem; background-color: #4a90e2; color: white; border: none; border-radius: 4px; font-size: 1rem; cursor: pointer; margin-top: 0.5rem; }
button:hover:not(:disabled) { background-color: #357abd; }
button:disabled { opacity: 0.6; cursor: not-allowed; }
.message { padding: 0.75rem; border-radius: 4px; margin-bottom: 1rem; text-align: center; }
.success { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
.error { background-color: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
.link-text { text-align: center; margin-top: 1rem; color: #666; }
.link-text a { color: #4a90e2; text-decoration: none; }
</style>
```

---

## 13. Lancer et tester l'application complète

### Terminal 1 — Backend Spring Boot

```bash
cd ~/auth-backend
mvn spring-boot:run
```

### Terminal 2 — MongoDB (vérifier qu'il tourne)

```bash
sudo systemctl status mongod
```

### Terminal 3 — Frontend Vue.js

```bash
cd ~/auth-frontend
npm run dev
```

Le terminal affichera :

```
  VITE v5.x.x  ready in XXX ms

  ➜  Local:   http://localhost:5173/
```

### Ouvrir dans le navigateur

Rends-toi sur **http://localhost:5173**

Tu verras la page de connexion. Teste :

1. Clique sur "S'inscrire" → crée un compte
2. Reviens sur "Se connecter" → connecte-toi avec les mêmes identifiants
3. Teste un mauvais mot de passe → observe le message d'erreur

---

## 14. Récapitulatif des commandes clés

### Commandes système

| Action | Commande |
|---|---|
| Mettre à jour les paquets | `sudo apt update && sudo apt upgrade -y` |
| Installer Java 21 | `sudo apt install -y openjdk-21-jdk` |
| Installer Maven | `sudo apt install -y maven` |
| Installer Node.js | `sudo apt install -y nodejs npm` |
| Démarrer MongoDB | `sudo systemctl start mongod` |
| Statut MongoDB | `sudo systemctl status mongod` |
| Shell MongoDB | `mongosh` |

### Commandes Java (terminal)

| Action | Commande |
|---|---|
| Compiler un fichier Java | `javac MonFichier.java` |
| Exécuter un programme Java | `java NomDeLaClasse` |
| Version Java | `java --version` |
| Version compilateur | `javac --version` |

### Commandes Maven (projet Spring Boot)

| Action | Commande |
|---|---|
| Démarrer l'application | `mvn spring-boot:run` |
| Compiler sans lancer | `mvn compile` |
| Générer le JAR exécutable | `mvn package` |
| Nettoyer les fichiers compilés | `mvn clean` |

### Commandes npm (projet Vue.js)

| Action | Commande |
|---|---|
| Installer les dépendances | `npm install` |
| Lancer en développement | `npm run dev` |
| Construire pour production | `npm run build` |
| Installer un paquet | `npm install nom-du-paquet` |

---

## Points importants à retenir

**Sécurité :** Ce projet est configuré pour le développement local uniquement. Avant de le déployer :
- Réactiver Spring Security et implémenter JWT
- Ajouter l'authentification MongoDB (`mongod.conf`)
- Ne jamais committer de mots de passe dans le code

**Ports utilisés :**
- `5173` → Frontend Vue.js
- `8080` → Backend Spring Boot
- `27017` → MongoDB

**En cas d'erreur CORS :** L'annotation `@CrossOrigin(origins = "http://localhost:5173")` dans le contrôleur autorise les requêtes cross-origin depuis Vue.js. Si tu changes le port du frontend, mets-le à jour ici.

---

*Procédure rédigée pour Kubuntu 26.04 LTS (Resolute Raccoon) — juin 2026*
