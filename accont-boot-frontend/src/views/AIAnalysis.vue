<script setup>
import { ref, reactive } from 'vue'
import { analyze } from '@/api'
import { ElMessage } from 'element-plus'
import { marked } from 'marked'

const loading = ref(false)
const result = ref('')
const form = reactive({
  type: 'summary',
  timeRange: 'month'
})

const typeOptions = [
  { label: '收支总结', value: 'summary' },
  { label: '理财建议', value: 'advice' },
  { label: '趋势预测', value: 'forecast' }
]

const timeRangeOptions = [
  { label: '本周', value: 'week' },
  { label: '本月', value: 'month' },
  { label: '本年', value: 'year' }
]

const handleAnalyze = async () => {
  loading.value = true
  result.value = ''
  try {
    const res = await analyze(form)
    if (res.code === 200 && res.data && res.data.content) {
      // 使用 marked.parse 解析 Markdown
      result.value = marked.parse(res.data.content)
    } else {
      ElMessage.error(res.message || '分析失败')
    }
  } catch (error) {
    console.error('AI分析错误:', error)
    ElMessage.error(error.response?.data?.message || '分析失败，请稍后重试')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="ai-analysis">
    <el-card class="box-card">
      <template #header>
        <div class="card-header">
          <span>AI 智能账本分析</span>
        </div>
      </template>
      
      <el-form :inline="true" :model="form" class="demo-form-inline">
        <el-form-item label="分析类型">
          <el-select v-model="form.type" placeholder="请选择分析类型" style="width: 150px">
            <el-option
              v-for="item in typeOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-select v-model="form.timeRange" placeholder="请选择时间范围" style="width: 150px">
            <el-option
              v-for="item in timeRangeOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleAnalyze" :loading="loading">
            开始分析
          </el-button>
        </el-form-item>
      </el-form>

      <div v-if="result" class="analysis-result">
        <el-divider content-position="left">分析结果</el-divider>
        <div class="markdown-body" v-html="result"></div>
      </div>
      
      <el-empty v-else-if="!loading" description="暂无分析结果，请点击上方按钮开始分析" />
      
      <div v-if="loading" class="loading-container">
        <el-skeleton :rows="5" animated />
      </div>
    </el-card>
  </div>
</template>

<style scoped>
.ai-analysis {
  padding: 20px;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.analysis-result {
  margin-top: 20px;
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 4px;
  line-height: 1.6;
}
.loading-container {
  margin-top: 20px;
}
/* Markdown styles */
:deep(.markdown-body) {
  color: #2c3e50;
}
:deep(.markdown-body h1),
:deep(.markdown-body h2),
:deep(.markdown-body h3) {
  margin-top: 24px;
  margin-bottom: 16px;
  font-weight: 600;
  line-height: 1.25;
}
:deep(.markdown-body p) {
  margin-bottom: 16px;
}
:deep(.markdown-body ul),
:deep(.markdown-body ol) {
  padding-left: 2em;
  margin-bottom: 16px;
}
</style>
