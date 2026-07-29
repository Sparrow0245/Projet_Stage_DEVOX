<template>
  <div class="dashboard">
    <h2>Supervision en Temps Réel</h2>
    
    <div class="cards-grid">
      <div class="card">
        <h3>Statut Serveur</h3>
        <p class="status-indicator" :class="{ active: serverStatus === 'UP' }">
          {{ serverStatus }}
        </p>
      </div>

      <div class="card">
        <h3>Charge CPU</h3>
        <p class="metric-value">{{ currentCpuUsage }} %</p>
      </div>
    </div>

    <div class="chart-container card">
      <h3>Évolution de la charge CPU</h3>
      <Line v-if="chartData.labels.length > 0" :data="chartData" :options="chartOptions" />
      <p v-else>Chargement des données...</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  LineElement,
  LinearScale,
  PointElement,
  CategoryScale
} from 'chart.js'

ChartJS.register(Title, Tooltip, Legend, LineElement, LinearScale, PointElement, CategoryScale)

const serverStatus = ref('UNKNOWN')
const currentCpuUsage = ref(0)

const chartData = ref({
  labels: [],
  datasets: [
    {
      label: 'CPU Usage (%)',
      backgroundColor: '#38bdf8',
      borderColor: '#38bdf8',
      data: []
    }
  ]
})

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false
}

const fetchMetrics = async () => {
  try {
    const statusRes = await axios.get('/api/dashboard/overview')
    serverStatus.value = statusRes.data.status

    const cpuRes = await axios.get('/api/dashboard/cpu')
    const metrics = cpuRes.data.reverse()

    chartData.value.labels = metrics.map(m => new Date(m.recordedAt).toLocaleTimeString())
    chartData.value.datasets[0].data = metrics.map(m => m.usagePercent)

    if (metrics.length > 0) {
      currentCpuUsage.value = metrics[metrics.length - 1].usagePercent
    }
  } catch (error) {
    console.error('Erreur lors de la récupération des métriques:', error)
  }
}

onMounted(() => {
  fetchMetrics()
  setInterval(fetchMetrics, 10000)
})
</script>

<style scoped>
.cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.card {
  background-color: #1e293b;
  padding: 1.5rem;
  border-radius: 8px;
  border: 1px solid #334155;
}

.metric-value {
  font-size: 2rem;
  font-weight: bold;
  color: #38bdf8;
  margin: 0.5rem 0 0 0;
}

.status-indicator {
  font-size: 1.2rem;
  font-weight: bold;
  color: #ef4444;
}

.status-indicator.active {
  color: #22c55e;
}

.chart-container {
  height: 400px;
}
</style>
