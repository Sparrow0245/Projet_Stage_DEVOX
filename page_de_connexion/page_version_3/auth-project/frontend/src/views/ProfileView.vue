<template>
  <div>
    <nav class="topbar">
      <div class="brand">Auth<span>App</span></div>
      <div class="topbar-actions">
        <button class="btn btn-secondary" style="width:auto" @click="$router.push('/dashboard')">
          ← Tableau de bord
        </button>
        <button class="btn btn-secondary" style="width:auto" @click="handleLogout">
          Déconnexion
        </button>
      </div>
    </nav>

    <div class="page-center" style="min-height: calc(100vh - 60px)">
      <div class="card">
        <h1 class="card-title" style="text-align:left; margin-bottom:4px">Mon profil</h1>
        <p class="card-subtitle" style="text-align:left; margin-bottom:28px">
          Gérez vos informations personnelles
        </p>

        <!-- Messages -->
        <div v-if="error"   class="msg-error">{{ error }}</div>
        <div v-if="success" class="msg-success">{{ success }}</div>

        <!-- Formulaire mise à jour -->
        <div class="field">
          <label>Nom actuel</label>
          <input v-model="name" type="text" placeholder="Votre nom" />
        </div>

        <div class="field">
          <label>Nouveau mot de passe <small>(laisser vide pour ne pas changer)</small></label>
          <input v-model="password" type="password" placeholder="••••••••" autocomplete="new-password" />
        </div>

        <div class="field">
          <label>E-mail (non modifiable)</label>
          <input :value="email" type="email" disabled style="background:var(--bg);color:var(--text-muted);cursor:not-allowed" />
        </div>

        <button class="btn btn-primary" :disabled="saving" @click="save" style="margin-bottom:12px">
          <span v-if="saving">Enregistrement…</span>
          <span v-else>Enregistrer les modifications</span>
        </button>

        <div class="divider">zone dangereuse</div>

        <!-- Suppression -->
        <button class="btn btn-danger" style="width:100%" @click="confirmDelete = true">
          Supprimer mon compte
        </button>

        <!-- Modale de confirmation -->
        <div v-if="confirmDelete" class="modal-overlay" @click.self="confirmDelete = false">
          <div class="modal-box">
            <h2>Confirmer la suppression</h2>
            <p>Cette action est <strong>irréversible</strong>. Votre compte et toutes vos données seront supprimés définitivement.</p>
            <div style="display:flex;gap:12px;margin-top:20px">
              <button class="btn btn-secondary" style="flex:1" @click="confirmDelete = false">Annuler</button>
              <button class="btn btn-danger" style="flex:1" :disabled="deleting" @click="deleteAccount">
                <span v-if="deleting">Suppression…</span>
                <span v-else>Oui, supprimer</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { getMe, updateMe, deleteMe, logout } from '../api/auth.js'

const router  = useRouter()
const name    = ref('')
const email   = ref('')
const password= ref('')
const error   = ref('')
const success = ref('')
const saving  = ref(false)
const deleting= ref(false)
const confirmDelete = ref(false)

onMounted(async () => {
  try {
    const res = await getMe()
    name.value  = res.data.name
    email.value = res.data.email
  } catch {
    router.push('/login')
  }
})

async function save() {
  error.value = ''
  success.value = ''
  if (!name.value.trim()) { error.value = 'Le nom ne peut pas être vide.'; return }
  if (password.value && password.value.length < 8) {
    error.value = 'Le mot de passe doit contenir au moins 8 caractères.'
    return
  }
  saving.value = true
  try {
    const res = await updateMe(name.value, password.value || null)
    name.value    = res.data.name
    password.value= ''
    success.value = 'Profil mis à jour avec succès.'
  } catch (e) {
    error.value = e.response?.data?.message || 'Erreur lors de la mise à jour.'
  } finally {
    saving.value = false
  }
}

async function deleteAccount() {
  deleting.value = true
  try {
    await deleteMe()
    await logout()
    router.push('/login')
  } catch (e) {
    error.value = e.response?.data?.message || 'Erreur lors de la suppression.'
    confirmDelete.value = false
  } finally {
    deleting.value = false
  }
}

async function handleLogout() {
  await logout()
  router.push('/login')
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 999;
}
.modal-box {
  background: var(--white);
  border-radius: var(--radius);
  padding: 32px;
  max-width: 400px;
  width: 90%;
  box-shadow: 0 8px 32px rgba(0,0,0,0.2);
}
.modal-box h2 { font-size: 18px; margin-bottom: 12px; }
.modal-box p  { font-size: 14px; color: var(--text-muted); line-height: 1.6; }
</style>
