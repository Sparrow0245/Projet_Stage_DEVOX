<template>
  <div id="layout">
    <header class="navbar">
      <div class="brand">
        <h1>🛡️ Sentinelle V4</h1>
        <span class="subtitle">Supervision & Sécurité Systemd</span>
      </div>
      <nav class="nav-links">
        <router-link to="/">Tableau de bord</router-link>
        <router-link to="/security">Sécurité & Pare-feu</router-link>
      </nav>
    </header>

    <main class="content">
      <router-view />
    </main>
  </div>
</template>

<style>
:root {
  --bg-color: #0f172a;
  --card-bg: #1e293b;
  --text-main: #f8fafc;
  --accent-blue: #38bdf8;
  --border-color: #334155;
}

body {
  margin: 0;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background-color: var(--bg-color);
  color: var(--text-main);
}

.navbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 2rem;
  background-color: var(--card-bg);
  border-bottom: 1px solid var(--border-color);
}

.brand h1 {
  margin: 0;
  font-size: 1.4rem;
}

.subtitle {
  font-size: 0.8rem;
  color: #94a3b8;
}

.nav-links a {
  color: var(--text-main);
  text-decoration: none;
  margin-left: 1.5rem;
  padding: 0.5rem 0.8rem;
  border-radius: 4px;
}

.nav-links a.router-link-active {
  background-color: var(--accent-blue);
  color: #0f172a;
  font-weight: bold;
}

.content {
  padding: 2rem;
}
</style>
