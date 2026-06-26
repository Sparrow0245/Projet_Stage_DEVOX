# AuthApp — Spring Boot + Vue.js + MongoDB

Système d'authentification full-stack avec deux versions :
- **Version Session Cookie** (défaut)
- **Version JWT** (via profil Spring)

---

## Prérequis

| Outil        | Version minimale |
|-------------|-----------------|
| Java        | 21              |
| Maven       | 3.9+            |
| Node.js     | 22              |
| npm         | 10+             |
| MongoDB     | 7+              |

---

## 1. Démarrer MongoDB

```bash
sudo systemctl start mongod
# Vérifier :
sudo systemctl status mongod
```

La base `authdb` est créée automatiquement au premier lancement.

---

## 2. Backend Spring Boot

### Version Session Cookie (défaut)

```bash
cd backend
mvn spring-boot:run
```

Accès : `http://localhost:8080`

### Version JWT

```bash
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=jwt
```

> La seule différence : `application-jwt.properties` remplace `auth.mode=session` par `auth.mode=jwt`
> et active la génération/validation de tokens JWT.

**⚠️ Changer la clé secrète JWT avant tout déploiement** dans `application-jwt.properties` :
```properties
jwt.secret=votre_cle_secrete_longue_et_aleatoire_ici
```

---

## 3. Frontend Vue.js

### Version Session Cookie (défaut)

```bash
cd frontend
npm install
npm run dev
```

### Version JWT

```bash
cd frontend
npm install
VITE_AUTH_MODE=jwt npm run dev
```

Accès : `http://localhost:5173`

Le proxy Vite redirige automatiquement `/api/*` → `http://localhost:8080`.

---

## 4. Endpoints REST disponibles

| Méthode | Route              | Auth requise | Description              |
|--------|--------------------|-------------|--------------------------|
| POST   | `/api/auth/register` | Non        | Créer un compte          |
| POST   | `/api/auth/login`    | Non        | Se connecter             |
| GET    | `/api/auth/me`       | Oui        | Récupérer son profil     |
| PUT    | `/api/auth/me`       | Oui        | Modifier nom/mot de passe|
| DELETE | `/api/auth/me`       | Oui        | Supprimer son compte     |
| POST   | `/api/auth/logout`   | Non        | Se déconnecter (session) |

### Exemples curl

**Inscription**
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@test.com","password":"motdepasse"}'
```

**Connexion (session)**
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{"email":"alice@test.com","password":"motdepasse"}'
```

**Connexion (JWT)**
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@test.com","password":"motdepasse"}'
# → récupérer le champ "token" dans la réponse
```

**Profil (JWT)**
```bash
curl http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer <votre_token>"
```

---

## 5. Structure du projet

```
auth-project/
├── backend/
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/auth/app/
│       │   ├── AuthAppApplication.java
│       │   ├── config/SecurityConfig.java
│       │   ├── controller/AuthController.java
│       │   ├── model/User.java
│       │   ├── model/Dto.java
│       │   ├── repository/UserRepository.java
│       │   ├── security/JwtUtil.java
│       │   ├── security/JwtFilter.java
│       │   └── service/AuthService.java
│       └── resources/
│           ├── application.properties        ← mode session (défaut)
│           └── application-jwt.properties    ← mode JWT
└── frontend/
    ├── package.json
    ├── vite.config.js
    ├── index.html
    └── src/
        ├── main.js
        ├── App.vue
        ├── api/auth.js
        ├── assets/global.css
        ├── router/index.js
        └── views/
            ├── LoginView.vue
            ├── RegisterView.vue
            ├── DashboardView.vue
            └── ProfileView.vue
```

---

## 6. Différences Session vs JWT

| Critère           | Session Cookie                     | JWT                                   |
|------------------|------------------------------------|---------------------------------------|
| Stockage état    | Côté serveur (mémoire Spring)      | Côté client (localStorage)            |
| Transport        | Cookie `JSESSIONID` httpOnly       | Header `Authorization: Bearer <token>`|
| Révocation       | Immédiate (invalidate session)     | Impossible avant expiration           |
| Scalabilité      | Nécessite session sticky ou Redis  | Stateless, scalable nativement        |
| Sécurité XSS     | Protégé (httpOnly cookie)          | Vulnérable si localStorage compromis  |
| Expiration       | Configurable côté serveur          | Encodée dans le token (1h par défaut) |
