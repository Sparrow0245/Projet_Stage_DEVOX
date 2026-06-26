<template>
  <div>
    <!-- Barre de navigation -->
    <nav class="topbar">
      <div class="brand">Auth<span>App</span></div>
      <div class="topbar-actions">
        <button class="btn btn-secondary" style="width:auto" @click="$router.push('/profile')">
          Mon profil
        </button>
        <div class="avatar">{{ initial }}</div>
        <button class="btn btn-secondary" style="width:auto" @click="handleLogout">
          Déconnexion
        </button>
      </div>
    </nav>

    <!-- Contenu -->
    <div class="page-center" style="min-height: calc(100vh - 60px)">
      <div class="card" style="text-align:center">
        <div style="font-size:64px; margin-bottom:16px">✅</div>
        <h1 style="font-size:28px; font-weight:500; margin-bottom:8px">
          Connexion réussie !
        </h1>
        <p style="color:var(--text-muted); margin-bottom:24px">
          Bienvenue, <strong>{{ user.name }}</strong> — vous êtes connecté en tant que
          <code style="background:var(--bg);padding:2px 6px;border-radius:4px">{{ user.email }}</code>.
        </p>
        <button class="btn btn-primary" @click="$router.push('/profile')">
          Accéder à mon profil
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { getMe, logout } from '../api/auth.js'

const router = useRouter()
const user   = ref({ name: '', email: '' })

const initial = computed(() =>
  user.value.name ? user.value.name.charAt(0).toUpperCase() : '?'
)

onMounted(async () => {
  try {
    const res = await getMe()
    user.value = res.data
  } catch {
    router.push('/login')
  }
})

async function handleLogout() {
  await logout()
  router.push('/login')
}
</script>
