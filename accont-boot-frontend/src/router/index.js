import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { title: '登录', hidden: true }
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('@/views/Register.vue'),
    meta: { title: '注册', hidden: true }
  },
  {
    path: '/',
    name: 'Dashboard',
    component: () => import('@/views/Dashboard.vue'),
    meta: { title: '首页', icon: 'HomeFilled', requiresAuth: true }
  },
  {
    path: '/assets',
    name: 'Assets',
    component: () => import('@/views/Assets.vue'),
    meta: { title: '资产管理', icon: 'Wallet', requiresAuth: true }
  },
  {
    path: '/transactions',
    name: 'Transactions',
    component: () => import('@/views/Transactions.vue'),
    meta: { title: '记账流水', icon: 'List', requiresAuth: true }
  },
  {
    path: '/ai-analysis',
    name: 'AIAnalysis',
    component: () => import('@/views/AIAnalysis.vue'),
    meta: { title: 'AI分析', icon: 'DataAnalysis', requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  
  if (to.meta.requiresAuth && !token) {
    next('/login')
  } else if (token && (to.path === '/login' || to.path === '/register')) {
    next('/')
  } else {
    next()
  }
})

export default router
