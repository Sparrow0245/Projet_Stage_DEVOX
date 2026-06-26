<template>
  <div class="page-center">
    <div class="card">
      <div class="card-logo">
        <div class="brand">Auth<span>App</span></div>
      </div>
      <h1 class="card-title">Se connecter</h1>
      <p class="card-subtitle">Accédez à votre compte</p>

      <div v-if="error" class="msg-error">{{ error }}</div>

      <div class="field">
        <label for="email">Adresse e-mail</label>
        <input
          id="email"
          v-model="email"
          type="email"
          placeholder="exemple@mail.com"
          autocomplete="email"
          @keyup.enter="submit"
        />
      </div>

      <div class="field">
        <label for="password">Mot de passe</label>
        <input
          id="password"
          v-model="password"
          type="password"
          placeholder="••••••••"
          autocomplete="current-password"
          @keyup.enter="submit"
        />
      </div>

      <button class="btn btn-primary" :disabled="loading" @click="submit">
        <span v-if="loading">Connexion…</span>
        <span v-else>Se connecter</span>
      </button>

      <div class="divider">ou</div>

      <button class="btn btn-secondary" @click="$router.push('/register')">
        Créer un compte
      </button>

      <div class="footer-links">
        <a href="#">Mot de passe oublié ?</a>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { login } from '../api/auth.js'

const router   = useRouter()
const email    = ref('')
const password = ref('')
const error    = ref('')
const loading  = ref(false)

async function submit() {
  error.value = ''
  if (!email.value || !password.value) {
    error.value = 'Veuillez remplir tous les champs.'
    return
  }
  loading.value = true
  try {
    await login(email.value, password.value)
    router.push('/dashboard')
  } catch (e) {
    error.value = e.response?.data?.message || 'Erreur de connexion.'
  } finally {
    loading.value = false
  }
}
</script>
