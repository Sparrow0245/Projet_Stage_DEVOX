import { createRouter, createWebHistory } from 'vue-router'
import LoginView    from '../views/LoginView.vue'
import RegisterView from '../views/RegisterView.vue'
import DashboardView from '../views/DashboardView.vue'
import ProfileView  from '../views/ProfileView.vue'
import { getMe }    from '../api/auth.js'

const routes = [
  { path: '/',         redirect: '/login' },
  { path: '/login',    component: LoginView,     meta: { guest: true } },
  { path: '/register', component: RegisterView,  meta: { guest: true } },
  { path: '/dashboard',component: DashboardView, meta: { requiresAuth: true } },
  { path: '/profile',  component: ProfileView,   meta: { requiresAuth: true } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// Guard global : vérifie la session/token en appelant /api/auth/me
router.beforeEach(async (to, from, next) => {
  if (to.meta.requiresAuth) {
    try {
      await getMe()
      next()
    } catch {
      next('/login')
    }
  } else if (to.meta.guest) {
    try {
      await getMe()
      next('/dashboard') // déjà connecté
    } catch {
      next()
    }
  } else {
    next()
  }
})

export default router
