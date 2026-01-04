<script setup>
import { computed, ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'

const route = useRoute()
const router = useRouter()

const menuItems = [
  { path: '/', title: '首页', icon: 'HomeFilled' },
  { path: '/assets', title: '资产管理', icon: 'Wallet' },
  { path: '/transactions', title: '记账流水', icon: 'List' },
  { path: '/ai-analysis', title: 'AI分析', icon: 'DataAnalysis' }
]

const activeMenu = computed(() => route.path)
const showLayout = computed(() => !route.meta.hidden)

const username = ref('')

onMounted(() => {
  const userStr = localStorage.getItem('user')
  if (userStr) {
    try {
      const user = JSON.parse(userStr)
      username.value = user.username
    } catch (e) {
      console.error(e)
    }
  }
})

const handleSelect = (path) => {
  router.push(path)
}

const handleLogout = () => {
  ElMessageBox.confirm('确定要退出登录吗？', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    ElMessage.success('已退出登录')
    router.push('/login')
  }).catch(() => {})
}
</script>

<template>
  <div v-if="!showLayout" class="full-screen">
    <router-view />
  </div>
  
  <el-container v-else class="app-container">
    <!-- 侧边栏 -->
    <el-aside width="220px" class="app-aside">
      <div class="logo">
        <el-icon :size="32" color="#c17c4a">
          <Money />
        </el-icon>
        <span class="logo-text">个人记账</span>
      </div>
      <el-menu :default-active="activeMenu" class="app-menu" @select="handleSelect">
        <el-menu-item v-for="item in menuItems" :key="item.path" :index="item.path">
          <el-icon>
            <component :is="item.icon" />
          </el-icon>
          <span>{{ item.title }}</span>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <!-- 主内容区 -->
    <el-container>
      <el-header class="app-header">
        <div class="header-title">{{ route.meta.title || '首页' }}</div>
        <div class="header-user">
          <el-dropdown @command="handleLogout">
            <span class="user-info">
              <el-avatar :size="36" class="user-avatar">
                <el-icon :size="20">
                  <User />
                </el-icon>
              </el-avatar>
              <span class="user-name">{{ username || '用户' }}</span>
              <el-icon class="el-icon--right"><arrow-down /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <el-main class="app-main">
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </el-main>
    </el-container>
  </el-container>
</template>

<style scoped>
/* Layout Styles for Elegant Notebook Theme */
.full-screen {
  height: 100%;
  width: 100%;
}

.app-container {
  height: 100vh;
}

.app-aside {
  background: #fdfbf7;
  /* 极淡的米白 */
  border-right: 1px solid #f0eae6;
  box-shadow: none;
  /* 去除侧边阴影，追求平面纸张感 */
}

.logo {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  background: transparent;
  border-bottom: 1px solid #f0eae6;
}

.logo-text {
  font-family: 'Noto Serif SC', serif;
  font-size: 20px;
  font-weight: 700;
  color: #3d3020;
  letter-spacing: 1px;
}

.app-menu {
  border-right: none;
  padding-top: 24px;
  background: transparent !important;
}

.app-menu .el-menu-item {
  margin: 4px 16px;
  border-radius: 8px;
  transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
  color: #6b5d52 !important;
  /* text-body */
  font-family: 'Noto Sans SC', sans-serif;
  height: 48px;
  line-height: 48px;
}

.app-menu .el-menu-item:hover {
  background: #f5f0eb !important;
  color: #3d3020 !important;
  transform: translateX(4px);
}

.app-menu .el-menu-item.is-active {
  background: #f0e6dd !important;
  /* 选中状态淡褐背景 */
  color: #c17c4a !important;
  /* accent-gold */
  font-weight: 600;
  box-shadow: none;
  position: relative;
}

/* 选中状态左侧指示条 */
.app-menu .el-menu-item.is-active::before {
  content: "";
  position: absolute;
  left: -16px;
  top: 10px;
  bottom: 10px;
  width: 4px;
  background: #c17c4a;
  border-radius: 0 4px 4px 0;
}

.app-header {
  height: 64px;
  background: transparent;
  /* 透明顶栏，让body背景显示 */
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 32px;
  /* border-bottom: 1px solid #f0eae6; */
  /* 如果想要完全干净可以去掉边框 */
  position: sticky;
  top: 0;
  z-index: 100;
}

.header-title {
  font-family: 'Noto Serif SC', serif;
  font-size: 24px;
  font-weight: 700;
  color: #3d3020;
  letter-spacing: 0.5px;
}

.header-user {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 6px 16px;
  background: #fff;
  border-radius: 24px;
  border: 1px solid #f0eae6;
  box-shadow: 0 2px 10px rgba(90, 74, 63, 0.05);
  transition: all 0.3s ease;
}

.header-user:hover {
  border-color: #e5dfd9;
  box-shadow: 0 4px 12px rgba(90, 74, 63, 0.1);
}

.user-info {
  display: flex;
  align-items: center;
  cursor: pointer;
  gap: 8px;
}

.user-avatar {
  background: #f5f0eb;
  color: #c17c4a;
}

.user-name {
  font-size: 14px;
  color: #6b5d52;
  font-weight: 500;
  font-family: 'Noto Sans SC', sans-serif;
}

.app-main {
  background: transparent;
  padding: 32px;
  /* 增加内边距，留白 */
  /* max-width: 1400px; */
  /* 限制最大宽度，防止在大屏上太散 */
  /* margin: 0 auto; */
  width: 100%;
}

/* 页面过渡动画 */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease, transform 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
</style>
