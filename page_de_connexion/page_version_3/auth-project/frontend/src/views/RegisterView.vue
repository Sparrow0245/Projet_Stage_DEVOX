<template>
  <div class="page-center">
    <div class="card">
      <div class="card-logo">
        <div class="brand">Auth<span>App</span></div>
      </div>
      <h1 class="card-title">Créer un compte</h1>
      <p class="card-subtitle">Rejoignez-nous en quelques secondes</p>

      <div v-if="error"   class="msg-error">{{ error }}</div>
      <div v-if="success" class="msg-success">{{ success }}</div>

      <div class="field">
        <label for="name">Nom</label>
        <input
          id="name"
          v-model="name"
          type="text"
          placeholder="Votre nom"
          autocomplete="name"
        />
      </div>

      <div class="field">
        <label for="email">Adresse e-mail</label>
        <input
          id="email"
          v-model="email"
          type="email"
          placeholder="exemple@mail.com"
          autocomplete="email"
        />
      </div>

      <div class="field">
        <label for="password">Mot de passe <small>(8 caractères minimum)</small></label>
        <input
          id="password"
          v-model="password"
          type="password"
          placeholder="••••••••"
          autocomplete="new-password"
        />
      </div>

      <button class="btn btn-primary" :disabled="loading" @click="submit">
        <span v-if="loading">Création…</span>
        <span v-else>Créer mon compte</span>
      </button>

      <div class="divider">ou</div>

      <button class="btn btn-secondary" @click="$router.push('/login')">
        Se connecter
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { register } from '../api/auth.js'

const router   = useRouter()
const name     = ref('')
const email    = ref('')
const password = ref('')
const error    = ref('')
const success  = ref('')
const loading  = ref(false)

async function submit() {
  error.value   = ''
  success.value = ''

  if (!name.value || !email.value || !password.value) {
    error.value = 'Veuillez remplir tous les champs.'
    return
  }
  if (password.value.length < 8) {
    error.value = 'Le mot de passe doit contenir au moins 8 caractères.'
    return
  }

  loading.value = true
  try {
    await register(name.value, email.value, password.value)
    success.value = 'Compte créé ! Redirection vers la connexion…'
    setTimeout(() => router.push('/login'), 1500)
  } catch (e) {
    error.value = e.response?.data?.message || 'Erreur lors de la création du compte.'
  } finally {
    loading.value = false
  }
}
</script>
