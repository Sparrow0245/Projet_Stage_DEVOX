# Guide pas à pas : Page d'authentification Web (Java 21 + Spring Boot + Vue.js + MongoDB)

## Objectif

Créer une application web locale composée de :

- Backend : Java 21 + Spring Boot
- Frontend : Vue.js
- Base de données : MongoDB 7+
- Authentification simple (connexion avec email/mot de passe)

---

# 1. Installation des prérequis sur Kubuntu 26.04

## Mise à jour du système

```bash
sudo apt update
sudo apt upgrade -y
```

---

## Installer Java 21

Vérifier la présence de Java :

```bash
java --version
```

Si Java 21 n'est pas installé :

```bash
sudo apt install openjdk-21-jdk -y
```

Vérification :

```bash
java --version
javac --version
```

---

## Installer Maven

Spring Boot utilise Maven pour gérer les dépendances.

```bash
sudo apt install maven -y
```

Vérification :

```bash
mvn -version
```

---

## Installer Node.js 22

Vérifier :

```bash
node -v
npm -v
```

Si nécessaire :

```bash
sudo apt install nodejs npm -y
```

Vérifier les versions.

---

## Installer MongoDB 7+

Consulter la documentation officielle MongoDB pour Ubuntu/Kubuntu :

https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-ubuntu/

Après installation :

```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```

Vérification :

```bash
sudo systemctl status mongod
```

---

# 2. Rappels Java de base

Créer un fichier :

```bash
nano HelloWorld.java
```

Contenu :

```java
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Bonjour");
    }
}
```

Compiler :

```bash
javac HelloWorld.java
```

Exécuter :

```bash
java HelloWorld
```

---

# 3. Création du backend Spring Boot

## Génération du projet

Créer un dossier :

```bash
mkdir projet-auth
cd projet-auth
```

Créer le projet avec Spring Initializr :

https://start.spring.io

Paramètres :

- Project : Maven
- Language : Java
- Java : 21
- Packaging : Jar

Dépendances :

- Spring Web
- Spring Data MongoDB
- Spring Security
- Lombok

Télécharger puis décompresser.

---

## Tester le backend

À la racine du projet :

```bash
mvn spring-boot:run
```

Si tout fonctionne :

```text
Tomcat started on port 8080
```

---

# 4. Configuration MongoDB

Créer la base :

```bash
mongosh
```

Puis :

```javascript
use authdb
```

Quitter :

```javascript
exit
```

---

## application.properties

Créer ou modifier :

```properties
spring.data.mongodb.uri=mongodb://localhost:27017/authdb
```

---

# 5. Création du frontend Vue.js

Depuis un autre terminal :

```bash
cd projet-auth
```

Créer l'application :

```bash
npm create vue@latest
```

Choisir les options par défaut.

Entrer dans le projet :

```bash
cd nom-du-projet
```

Installer les dépendances :

```bash
npm install
```

Lancer le serveur :

```bash
npm run dev
```

Le site est accessible sur l'adresse indiquée dans le terminal.

---

# 6. Création de la page de connexion

Dans :

```text
src/components/Login.vue
```

Créer :

```vue
<template>
  <div>
    <h2>Connexion</h2>

    <form @submit.prevent="login">
      <input v-model="email" type="email" placeholder="Email" />
      <br><br>

      <input v-model="password" type="password" placeholder="Mot de passe" />
      <br><br>

      <button type="submit">Se connecter</button>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const email = ref('')
const password = ref('')

const login = async () => {
  console.log(email.value)
  console.log(password.value)
}
</script>
```

---

# 7. Création du modèle utilisateur côté Spring

Créer :

```java
package com.example.auth.model;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Document(collection = "users")
public class User {

    @Id
    private String id;

    private String email;

    private String password;
}
```

---

# 8. Repository MongoDB

Créer :

```java
package com.example.auth.repository;

import com.example.auth.model.User;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface UserRepository
        extends MongoRepository<User, String> {

    User findByEmail(String email);
}
```

---

# 9. Contrôleur de connexion

Créer :

```java
@RestController
@RequestMapping("/auth")
public class AuthController {

    @PostMapping("/login")
    public String login() {
        return "Connexion reçue";
    }
}
```

---

# 10. Appel du backend depuis Vue

Installer Axios :

```bash
npm install axios
```

Dans Login.vue :

```javascript
import axios from "axios";

await axios.post(
  "http://localhost:8080/auth/login",
  {
    email: email.value,
    password: password.value
  }
);
```

---

# 11. Test complet

Démarrer MongoDB :

```bash
sudo systemctl start mongod
```

Démarrer Spring :

```bash
mvn spring-boot:run
```

Démarrer Vue :

```bash
npm run dev
```

Ouvrir le navigateur.

Tester la connexion.

---

# 12. Améliorations futures

Quand cette première version fonctionne :

1. Hashage des mots de passe avec BCrypt.
2. Création d'un endpoint d'inscription.
3. Validation des formulaires.
4. Gestion des erreurs.
5. JWT.
6. Gestion des rôles.
7. Déploiement Docker.
8. Déploiement Kubernetes.
9. HTTPS.
10. Journalisation et audit.

---

# Architecture finale

```text
Vue.js
   |
   | HTTP
   v
Spring Boot
   |
   v
MongoDB
```

Quand cette maquette fonctionne entièrement en local, tu auras déjà les bases nécessaires pour comprendre le fonctionnement global d'une application web moderne avec authentification.
