# Procédure pour lancer le projet en localhost

### Pour lancer le projet

#### 1. Extraire l'archive

bash

```bash
tar -xzf auth-project.tar.gz
cd auth-project
```

#### 2. Démarrer MongoDB

bash

```bash
sudo systemctl start mongod
```

#### 3. Backend (mode session par défaut)

bash

```bash
cd backend
mvn spring-boot:run
```

Pour JWT : `mvn spring-boot:run -Dspring-boot.run.profiles=jwt`

#### 4. Frontend (autre terminal)

bash

```bash
cd frontend
npm install
npm run dev
# Pour JWT : VITE_AUTH_MODE=jwt npm run dev
```

#### 5. Ouvrir `http://localhost:5173`
