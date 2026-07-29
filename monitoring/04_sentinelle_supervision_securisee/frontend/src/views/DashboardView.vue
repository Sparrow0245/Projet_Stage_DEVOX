<template>
  <div class="dashboard-container">
    <h1>Dashboard Sentinelle V4</h1>
    <p>Supervision serveur Ubuntu en temps réel</p>
    <div class="cards-grid">
      <div class="card">CPU: {{ cpuUsage }}%</div>
      <div class="card">RAM: {{ ramUsage }}%</div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      cpuUsage: 12.5,
      ramUsage: 45.2,
      timer: null
    }
  },
  mounted() {
    this.timer = setInterval(this.fetchData, 5000)
  },
  beforeUnmount() {
    clearInterval(this.timer)
  },
  methods: {
    fetchData() {
      // Appel API REST vers le backend Spring Boot
    }
  }
}
</script>

<style scoped>
.dashboard-container { padding: 20px; }
.cards-grid { display: flex; gap: 20px; }
.card { background: #2a2a2a; padding: 20px; border-radius: 8px; min-width: 150px; }
</style>
