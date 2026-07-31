import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

import OverviewView from '@/views/OverviewView.vue';
import SecurityView from '@/views/SecurityView.vue';

const routes = [
  {
    path: '/overview',
    name: 'Overview',
    component: OverviewView,
    meta: { requiresAdmin: false }
  },
  {
    path: '/security',
    name: 'Security',
    component: SecurityView,
    meta: { requiresAdmin: true }
  }
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore();
  
  if (to.meta.requiresAdmin && !authStore.isAdmin) {
    return next({ name: 'Overview' });
  }
  next();
});

export default router;
