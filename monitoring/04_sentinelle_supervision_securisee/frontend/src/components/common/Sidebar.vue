<template>
  <aside class="sidebar">
    <nav>
      <!-- VUES PUBLIQUES / ACCESSIBLES À TOUS -->
      <router-link to="/overview">Vue générale</router-link>
      <router-link to="/performance">Performances</router-link>
      <router-link to="/network">Réseau</router-link>

      <!-- VUES RESTREINTES : ADMINISTRATEUR UNIQUEMENT -->
      <template v-if="authStore.isAdmin">
        <router-link to="/security">Sécurité</router-link>
        <router-link to="/history">Historique</router-link>
        <router-link to="/services">Services</router-link>
        <router-link to="/process">Processus</router-link>
        <router-link to="/users">Utilisateurs</router-link>
        <router-link to="/settings">Paramètres</router-link>
        <router-link to="/logs">Logs</router-link>
      </template>
    </nav>
  </aside>
</template>

<script setup>
import { useAuthStore } from '@/stores/auth';
const authStore = useAuthStore();
</script>
