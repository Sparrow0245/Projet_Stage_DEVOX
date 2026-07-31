<template>
  <div class="alert-card">
    <h3>Dernières Alertes ({{ alerts.length }})</h3>
    <ul v-if="alerts.length > 0">
      <li v-for="alert in alerts" :key="alert.id" :class="alert.priority.toLowerCase()">
        <span class="badge">{{ alert.priority }}</span>
        <span class="message">{{ alert.message }}</span>
      </li>
    </ul>
    <p v-else>Aucune alerte récente</p>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';

const alerts = ref([]);
let intervalId = null;

const fetchAlerts = async () => {
  try {
    const res = await fetch('/api/alerts');
    const json = await res.json();
    if (json.success) {
      alerts.value = json.data;
    }
  } catch (err) {
    console.error("Erreur récupération alertes :", err);
  }
};

onMounted(() => {
  fetchAlerts();
  intervalId = setInterval(fetchAlerts, 5000);
});

onUnmounted(() => {
  clearInterval(intervalId);
});
</script>
