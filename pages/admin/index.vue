<template>
  <div>
    <h1 class="text-2xl font-bold text-gray-800 mb-6">Quản trị hệ thống</h1>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
      <NuxtLink to="/admin/projects"
        class="bg-white rounded-lg shadow-sm border p-6 hover:bg-gray-50 transition">
        <p class="text-3xl mb-2">📁</p>
        <p class="font-semibold text-gray-800">Quản lý dự án</p>
        <p class="text-sm text-gray-500 mt-1">Tạo, sửa, xoá dự án. Hiện có {{ projectCount }} dự án</p>
      </NuxtLink>
      <NuxtLink to="/admin/users"
        class="bg-white rounded-lg shadow-sm border p-6 hover:bg-gray-50 transition">
        <p class="text-3xl mb-2">👥</p>
        <p class="font-semibold text-gray-800">Quản lý người dùng</p>
        <p class="text-sm text-gray-500 mt-1">Phân quyền, thêm/sửa tài khoản</p>
      </NuxtLink>
      <NuxtLink to="/admin/structures"
        class="bg-white rounded-lg shadow-sm border p-6 hover:bg-gray-50 transition">
        <p class="text-3xl mb-2">🏗️</p>
        <p class="font-semibold text-gray-800">Công trình & Hạng mục</p>
        <p class="text-sm text-gray-500 mt-1">Quản lý danh sách công trình ({{ currentProject?.code || '—' }})</p>
      </NuxtLink>
      <NuxtLink to="/admin/work-catalog"
        class="bg-white rounded-lg shadow-sm border p-6 hover:bg-gray-50 transition">
        <p class="text-3xl mb-2">📦</p>
        <p class="font-semibold text-gray-800">Danh mục khối lượng</p>
        <p class="text-sm text-gray-500 mt-1">Quản lý danh mục hạng mục khối lượng tổng hợp</p>
      </NuxtLink>
      <NuxtLink to="/admin/kl-thiet-ke"
        class="bg-white rounded-lg shadow-sm border p-6 hover:bg-gray-50 transition">
        <p class="text-3xl mb-2">📐</p>
        <p class="font-semibold text-gray-800">Khối lượng thiết kế</p>
        <p class="text-sm text-gray-500 mt-1">Khai báo KL thiết kế theo từng công trình, tính tỷ lệ hoàn thành</p>
      </NuxtLink>
      <NuxtLink to="/admin/import-dtpl"
        class="bg-white rounded-lg shadow-sm border p-6 hover:bg-gray-50 transition">
        <p class="text-3xl mb-2">📊</p>
        <p class="font-semibold text-gray-800">Import DTPL</p>
        <p class="text-sm text-gray-500 mt-1">Nhập diện tích phân lớp đắp từ file Excel</p>
      </NuxtLink>
      <div class="bg-white rounded-lg shadow-sm border p-6">
        <p class="text-3xl mb-2">📋</p>
        <p class="font-semibold text-gray-800">Nhật ký đã khóa</p>
        <p class="text-sm text-gray-500 mt-1">{{ lockedCount }} nhật ký</p>
        <button v-if="lockedCount > 0" @click="goToLocked"
          class="mt-2 text-sm text-primary-600 hover:underline">Xem danh sách →</button>
      </div>
    </div>

    <!-- Recent Audit Log -->
    <div class="bg-white rounded-lg shadow-sm border">
      <div class="p-4 border-b">
        <h2 class="font-semibold text-gray-800">Nhật ký hoạt động gần đây</h2>
      </div>
      <div v-if="auditLogs.length === 0" class="p-8 text-center text-gray-400">
        Chưa có hoạt động nào
      </div>
      <div v-else class="divide-y">
        <div v-for="log in auditLogs" :key="log.id" class="p-4 text-sm">
          <div class="flex justify-between">
            <div>
              <span class="font-medium text-gray-700">{{ log.profiles?.full_name || log.user_id }}</span>
              <span class="text-gray-400 mx-1">·</span>
              <span class="text-gray-500">{{ log.action }}</span>
              <span v-if="log.table_name" class="text-gray-400"> trên {{ log.table_name }}</span>
            </div>
            <span class="text-xs text-gray-400">{{ formatDate(log.created_at) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { $supabase } = useNuxtApp()
const { isAdmin } = useAuth()
const { projects, currentProject } = useProject()
const router = useRouter()

const lockedCount = ref(0)
const auditLogs = ref<any[]>([])
const projectCount = computed(() => projects.value.length)

function formatDate(d: string) {
  return new Date(d).toLocaleString('vi-VN', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })
}

function goToLocked() {
  router.push('/diary?locked=1')
}

onMounted(async () => {
  if (!isAdmin.value) {
    router.push('/')
    return
  }

  const [lockedRes, logsRes] = await Promise.all([
    $supabase.from('diary_entries').select('id', { count: 'exact', head: true }).eq('is_locked', true),
    $supabase.from('audit_logs').select('*, profiles(full_name)').order('created_at', { ascending: false }).limit(20),
  ])

  lockedCount.value = lockedRes.count || 0
  auditLogs.value = logsRes.data || []
})
</script>
