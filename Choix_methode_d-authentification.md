# Choix de la méthode d'authentification :

## Sources :

[https://developer.okta.com/blog/2022/02/08/cookies-vs-tokens](https://developer.okta.com/blog/2022/02/08/cookies-vs-tokens)

[https://auth0.com/blog/cookies-tokens-jwt-the-aspnet-core-identity-dilemma/#Cookie-or-Token-based-Authentication-](https://auth0.com/blog/cookies-tokens-jwt-the-aspnet-core-identity-dilemma/#Cookie-or-Token-based-Authentication-)

[https://blog.logto.io/fr/token-based-authentication-vs-session-based-authentication](https://blog.logto.io/fr/token-based-authentication-vs-session-based-authentication)

___

## Contexte :

Le protocole HTTP étant *stateless* (sans état), chaque requête est indépendante et n'est pas stockée sur le serveur. Ce dernier ne retient donc aucune information des échanges précédents.
Un inconvénient apparait donc avec ce protocole : l'utilisateur doit se réauthentifier à chaque requête, ce qui complique une utilisation en pratique.
Pour palier à ce problème, il existe deux approches pour maintenir l'état d'authentification : les **cookies session** et **les token JWT**.

___

## Choix n°1 : Cookies session

### Principe de fonctionnement :

Cette méthode de connexion repose sur le serveur pour conserver l'état d'authentification. Le flux est le suivant :

1. L'utilisateur soumet ses identifiants.
2. Le serveur valide les identifiants et crée un enregistrement de session en base de données (contenant un identifiant aléatoire, l'ID utilisateur, les dates de création et d'expiration, etc.).
3. Le `SessionID` est renvoyé au client sous forme de **cookie**.
4. À chaque requête suivante, le navigateur envoie automatiquement ce cookie.
5. Le serveur interroge sa base de données pour valider le `SessionID` et autorise (ou non) l'accès.

Cela implique que les données d'authentification sont stockées à la fois côté client pour le `SessionID` dans le cookies, et côté serveur avec l'enregistrement de session complet en base

___
### Avantages et Inconvénients :

___

### Avantages

| Avantage | Détail |
|---|---|
| **Gestion automatique par le navigateur** | L'envoi du cookie à chaque requête est géré nativement par le navigateur, sans code supplémentaire côté frontend. |
| **Stockage léger côté client** | Un cookie de session peut ne stocker qu'un identifiant de quelques octets (environ 6 Ko pour un simple user ID). |
| **Révocation en temps réel** | L'accès peut être immédiatement révoqué côté serveur en supprimant l'enregistrement de session (déconnexion forcée par un administrateur, détection de compromission, etc.). |
| **Protection contre le XSS** | L'attribut `HttpOnly` empêche JavaScript d'accéder au cookie, réduisant la surface d'attaque XSS. |
| **Partage entre sous-domaines** | L'attribut `Domain` permet d'utiliser la même session sur `example.com` et ses sous-domaines. |
| **Simplicité et fiabilité** | La source de vérité est centralisée sur le serveur, ce qui rend les décisions d'autorisation directes et fiables. |


___


### Inconvénients
___


| Inconvénient | Détail |
|---|---|
| **Vulnérabilité CSRF** | Les cookies sont envoyés automatiquement par le navigateur, y compris lors de requêtes provenant de sites tiers malveillants. L'attribut `SameSite` atténue ce risque mais peut dégrader l'expérience utilisateur. |
| **Problèmes de scalabilité** | Les sessions étant liées à un serveur, un déploiement en *load balancing* nécessite un magasin de sessions partagé (Redis, base de données centralisée), ce qui ajoute de la latence et de la complexité. |
| **Consommation de ressources serveur** | Chaque session active consomme de la mémoire ou de l'espace disque côté serveur. La performance peut se dégrader avec une grande base d'utilisateurs. |
| **Inadapté aux API et applications mobiles** | Les cookies sont difficiles à gérer sur les applications mobiles natives. Pour les API, qui sont par nature sans état, la gestion de sessions est une complexité superflue. |
| **Risque de détournement de session** | Le vol du cookie de session (*session hijacking*) peut permettre un accès non autorisé. L'attribut `Secure` (cookie uniquement sur HTTPS) est indispensable pour atténuer ce risque. |

___

## Choix n°2 : token JWT


### Principe de fonctionnement :

Contrairement à la méthode de connexion précédente, dans l'authentification par token le serveur ne conserve aucun enregistrement de session. Toutes les informations nécessaires à la validation sont **encodées dans le token lui-même** et restent sur la machine de l'utilisateur. 

Le flux est le suivant :

1. L'utilisateur soumet ses identifiants au serveur d'authentification.
2. Le serveur valide les identifiants et génère un JWT signé cryptographiquement.
3. Le JWT est renvoyé au client, qui le stocke (cookie, `localStorage`, `sessionStorage`).
4. À chaque requête suivante, le client envoie le JWT dans le header HTTP `Authorization: Bearer <token>`.
5. Le serveur vérifie la **signature** du JWT et ses **claims** (expiration, émetteur, audience) — sans aucun accès à une base de données.

Un token JWT est composée de 3 parties encodées en Base 64 et sépararé par des points (`.`)



### Avantages et Inconvénients :

### Avantages

| Avantage | Détail |
|---|---|
| **Sans état et scalable** | Le serveur n'a pas besoin d'interroger une base de données pour valider chaque requête. Particulièrement adapté aux architectures distribuées et aux microservices. |
| **Multi-domaines et SSO** | Un même JWT peut être accepté par plusieurs services ou domaines différents (`api.example.com`, `dashboard.example.com`), contrairement aux cookies qui sont liés à un domaine. Idéal pour le Single Sign-On (SSO). |
| **Compatible mobile et API REST** | Les tokens peuvent être stockés côté client et transmis facilement dans des headers HTTP, sans les contraintes des cookies sur les applications natives. |
| **Informations embarquées** | Le payload peut contenir des claims personnalisés (rôles, permissions) exploitables directement par le serveur destinataire, sans requête supplémentaire en base. |
| **Vérification cryptographique** | La signature garantit l'intégrité du token. Le contenu est visible mais non modifiable sans invalider la signature. |





### Inconvénients

| Inconvénient | Détail |
|---|---|
| **Révocation difficile** | Un JWT ne peut pas être invalidé avant son expiration, sauf à implémenter une liste noire (*deny-list*), ce qui reintroduit un état côté serveur et contredit la nature stateless des JWT. |
| **Données potentiellement périmées** | Le payload représente un instantané au moment de l'émission. Si les droits d'un utilisateur changent (rétrogradation, suppression de compte), le JWT reste valide jusqu'à expiration. |
| **Taille plus importante** | Un JWT peut peser 300 octets ou plus, contre quelques octets pour un `SessionID`, ce qui alourdit chaque requête HTTP. |
| **Sécurité du stockage à la charge du développeur** | Le stockage dans `localStorage` expose le token aux attaques XSS. Le stockage dans un cookie `HttpOnly` est recommandé, mais réduit l'avantage sur les cookies classiques. |
| **Complexité de gestion** | La rotation des clés de signature, la gestion des tokens de rafraîchissement (*refresh tokens*), et les stratégies de révocation nécessitent une implémentation rigoureuse. |

___

### Stratégies de révocation d'un JWT

La révocation  d'un JWT est plus complexe que pour une session. Nous avons donc plusieurs approches possibles qui sont :

1. **Durée d'expiration courte (`exp`) :** Définir un claim `exp` très court (ex. 15 minutes) et utiliser un *refresh token* pour renouveler l'accès. Limite la fenêtre d'exploitation en cas de compromission.
2. **Liste noire (*deny-list*)** : Maintenir côté serveur une liste des tokens révoqués. Efficace mais réintroduit un état serveur et peut devenir volumineux.
3. **Point de révocation (*revocation endpoint*)** : Révoquer le *refresh token* sur le serveur d'autorisation. Les tokens d'accès ne seront plus renouvelés. Adapté aux flux OAuth 2.0.



___

## Comparatif :

| Critère | Cookies de session | Token JWT |
|---|---|---|
| **Nature** | Stateful (état côté serveur) | Stateless (état dans le token) |
| **Stockage état** | Base de données / cache serveur | Côté client (cookie, localStorage…) |
| **Révocation** | Immédiate (suppression en base) | Difficile (nécessite liste noire ou expiration courte) |
| **Scalabilité** | Limitée sans stockage partagé | Excellente (pas de dépendance serveur) |
| **Taille côté client** | ~6 Ko (simple SessionID) | ~300 octets minimum |
| **Multi-domaines / SSO** | Non (lié à un domaine) | Oui |
| **Applications mobiles** | Difficile à gérer | Adapté nativement |
| **APIs REST** | Peu adapté | Très adapté |
| **Protection XSS** | Bonne (avec `HttpOnly`) | Risquée (si stocké dans `localStorage`) |
| **Protection CSRF** | Risque (mitigé par `SameSite`) | Absent (pas de cookie automatique) |
| **Fraîcheur des données** | Garantie (requête BDD à chaque fois) | Non garantie (snapshot au moment de l'émission) |
| **Complexité d'implémentation** | Simple | Modérée à élevée |
| **Cas d'usage principal** | Applications web traditionnelles, e-commerce, services bancaires | APIs, SPA, mobile, microservices, SSO |








