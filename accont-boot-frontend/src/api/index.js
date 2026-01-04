import axios from 'axios'
import { ElMessage } from 'element-plus'
import router from '@/router'

// 创建axios实例
const api = axios.create({
  baseURL: '/api',
  timeout: 90000, // AI分析需要更长时间
})

// 请求拦截器
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器
api.interceptors.response.use(
  (response) => {
    const res = response.data
    if (res.code !== 200) {
      ElMessage.error(res.message || '请求失败')
      return Promise.reject(new Error(res.message || '请求失败'))
    }
    return res
  },
  (error) => {
    if (error.response && error.response.status === 401) {
      ElMessage.error('登录已过期，请重新登录')
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      router.push('/login')
    } else {
      ElMessage.error(error.message || '网络错误')
    }
    return Promise.reject(error)
  }
)

// ============ 用户 API ============

/**
 * 登录
 */
export const login = (data) => {
  return api.post('/users/login', data)
}

/**
 * 注册
 */
export const register = (data) => {
  return api.post('/users/register', data)
}

/**
 * 获取当前用户信息
 */
export const getCurrentUser = () => {
  return api.get('/users/me')
}

// ============ 资产 API ============

/**
 * 获取用户资产列表
 */
export const getAssets = () => {
  // 后端从 Token 获取用户ID，不再需要前端传递
  return api.get(`/assets`)
}

/**
 * 获取资产详情
 */
export const getAssetById = (id) => {
  return api.get(`/assets/${id}`)
}

/**
 * 创建资产
 */
export const createAsset = (data) => {
  return api.post('/assets', data)
}

/**
 * 更新资产名称
 */
export const updateAsset = (id, name) => {
  return api.put(`/assets/${id}`, { name })
}

/**
 * 删除资产
 */
export const deleteAsset = (id) => {
  return api.delete(`/assets/${id}`)
}

// ============ 流水 API ============

/**
 * 获取用户流水列表
 */
export const getTransactions = () => {
  return api.get(`/transactions`)
}

/**
 * 获取资产流水列表
 */
export const getTransactionsByAsset = (assetId) => {
  return api.get(`/transactions/asset/${assetId}`)
}

/**
 * 新增记账
 */
export const addTransaction = (data) => {
  return api.post('/transactions', data)
}

/**
 * 删除流水
 */
export const deleteTransaction = (id) => {
  return api.delete(`/transactions/${id}`)
}

// ============ AI 分析 API ============

/**
 * AI 账本分析
 * @param {Object} data { type, timeRange }
 */
export const analyze = (data) => {
  return api.post('/ai/analyze', data)
}

export default api
