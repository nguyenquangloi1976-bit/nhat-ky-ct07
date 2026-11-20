<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Quản lý dự án</h1>
        <p class="text-sm text-gray-500 mt-1">Tạo và quản lý các dự án giám sát thi công</p>
      </div>
      <button @click="openNew" class="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 text-sm font-medium">
        + Thêm dự án
      </button>
    </div>

    <!-- Project List -->
    <div class="space-y-4">
      <div v-for="p in allProjects" :key="p.id"
        class="bg-white rounded-lg shadow-sm border p-6 hover:shadow-md transition">
        <div class="flex justify-between items-start">
          <div class="flex-1">
            <div class="flex items-center space-x-3 mb-2">
              <span class="px-2.5 py-1 bg-primary-100 text-primary-700 text-sm font-bold rounded">{{ p.code }}</span>
              <h3 class="text-lg font-semibold text-gray-800">{{ p.name }}</h3>
              <span v-if="!p.is_active" class="px-2 py-0.5 text-xs bg-gray-100 text-gray-500 rounded-full">Tạm dừng</span>
            </div>
            <p v-if="p.description" class="text-sm text-gray-500 mb-2">{{ p.description }}</p>
            <div class="flex flex-wrap gap-4 text-xs text-gray-400">
              <span v-if="p.km_range">📍 {{ p.km_range }}</span>
              <span v-if="p.consortium">👥 {{ p.consortium }}</span>
              <a v-if="p.drive_folder_url" :href="p.drive_folder_url" target="_blank" class="text-blue-500 hover:underline">📁 Google Drive</a>
              <span v-if="p.start_date">📅 {{ p.start_date }} → {{ p.end_date || '...' }}</span>
              <span>📂 {{ p._typeCount || 0 }} loại</span>
              <span>🏗️ {{ p._structCount || 0 }} công trình</span>
            </div>
          </div>
          <div class="flex items-center space-x-2 ml-4">
            <button @click="openEdit(p)" class="px-3 py-1.5 text-sm text-primary-600 hover:bg-primary-50 rounded">Sửa</button>
            <button @click="confirmDelete(p)" class="px-3 py-1.5 text-sm text-red-500 hover:bg-red-50 rounded">Xoá</button>
          </div>
        </div>
      </div>

      <div v-if="allProjects.length === 0" class="text-center py-16 text-gray-400">
        Chưa có dự án nào. Nhấn "Thêm dự án" để bắt đầu.
      </div>
    </div>

    <!-- Modal -->
    <div v-if="showModal" class="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <div class="p-6 border-b">
          <h2 class="text-lg font-semibold text-gray-800">{{ editingId ? 'Sửa dự án' : 'Thêm dự án mới' }}</h2>
        </div>
        <div class="p-6 space-y-4">
          <div class="grid grid-cols-3 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Mã dự án *</label>
              <input v-model="form.code" type="text" placeholder="CT07"
                class="w-full px-3 py-2 border rounded-lg text-sm focus:ring-1 focus:ring-primary-500"
                :disabled="!!editingId" />
            </div>
            <div class="col-span-2">
              <label class="block text-sm font-medium text-gray-700 mb-1">Tên dự án *</label>
              <input v-model="form.name" type="text" placeholder="Gói thầu TV-08..."
                class="w-full px-3 py-2 border rounded-lg text-sm focus:ring-1 focus:ring-primary-500" />
            </div>
          </div>
          <!-- Đường mới / Mở rộng -->
          <div class="flex items-center gap-2 bg-gray-50 rounded-lg px-4 py-3">
            <span class="text-sm font-medium text-gray-700 mr-2">Loại đường:</span>
            <label class="flex items-center gap-1.5 cursor-pointer px-3 py-1.5 rounded-lg transition"
              :class="!form.has_left_right ? 'bg-blue-100 text-blue-700 font-medium' : 'text-gray-400 hover:bg-gray-100'">
              <input type="radio" :value="false" v-model="form.has_left_right" class="accent-blue-600" />
              Đường mới
            </label>
            <label class="flex items-center gap-1.5 cursor-pointer px-3 py-1.5 rounded-lg transition"
              :class="form.has_left_right ? 'bg-orange-100 text-orange-700 font-medium' : 'text-gray-400 hover:bg-gray-100'">
              <input type="radio" :value="true" v-model="form.has_left_right" class="accent-orange-500" />
              Mở rộng (có T/P)
            </label>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Mô tả</label>
            <textarea v-model="form.description" rows="2" placeholder="TVGS đoạn..."
              class="w-full px-3 py-2 border rounded-lg text-sm focus:ring-1 focus:ring-primary-500"></textarea>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Phạm vi Km</label>
            <input v-model="form.km_range" type="text" placeholder="Km59+000–Km68+700"
              class="w-full px-3 py-2 border rounded-lg text-sm focus:ring-1 focus:ring-primary-500" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Liên danh</label>
            <input v-model="form.consortium" type="text" placeholder="TEDI – CTGT2 – ..."
              class="w-full px-3 py-2 border rounded-lg text-sm focus:ring-1 focus:ring-primary-500" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Thư mục Google Drive</label>
            <input v-model="form.drive_folder_url" type="url" placeholder="https://drive.google.com/drive/folders/..."
              class="w-full px-3 py-2 border rounded-lg text-sm focus:ring-1 focus:ring-primary-500" />
            <p class="text-xs text-gray-400 mt-1">Dán link thư mục Drive dùng để lưu tài liệu dự án</p>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Ngày bắt đầu</label>
              <input v-model="form.start_date" type="date"
                class="w-full px-3 py-2 border rounded-lg text-sm focus:ring-1 focus:ring-primary-500" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Ngày kết thúc</label>
              <input v-model="form.end_date" type="date"
                class="w-full px-3 py-2 border rounded-lg text-sm focus:ring-1 focus:ring-primary-500" />
            </div>
          </div>
          <div class="flex items-center">
            <input v-model="form.is_active" type="checkbox" id="is_active" class="mr-2" />
            <label for="is_active" class="text-sm text-gray-700">Đang hoạt động</label>
          </div>

          <!-- Structure Types -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Loại công trình (Hạng mục)</label>

            <!-- Quick-add preset buttons (only when creating or adding new types) -->
            <div v-if="availablePresets.length > 0" class="flex flex-wrap gap-1.5 mb-3">
              <button v-for="p in availablePresets" :key="p.code"
                @click="addPreset(p)" type="button"
                class="px-2.5 py-1 text-xs bg-gray-100 text-gray-600 rounded-full hover:bg-primary-100 hover:text-primary-700 border border-gray-200 transition">
                + {{ p.name }}
              </button>
            </div>

            <div v-if="form.types.length" class="space-y-2 mb-3">
              <div v-for="(t, idx) in form.types" :key="idx"
                class="flex items-center gap-2 bg-gray-50 rounded-lg px-3 py-2">
                <input v-model="t.code" type="text" placeholder="Mã"
                  class="w-20 px-2 py-1 border rounded text-xs focus:ring-1 focus:ring-primary-500 bg-white text-gray-500" readonly />
                <input v-model="t.name" type="text" placeholder="Tên loại"
                  class="flex-1 px-2 py-1 border rounded text-sm focus:ring-1 focus:ring-primary-500 bg-white" />
                <button @click="removeType(idx)" class="text-red-400 hover:text-red-600 text-lg leading-none">&times;</button>
              </div>
            </div>
            <p v-else class="text-xs text-gray-400 mb-2 italic">Nhấn vào tên loại ở trên để thêm nhanh</p>
            <button @click="addTypeRow" type="button"
              class="text-sm text-primary-600 hover:text-primary-700 hover:underline">
              + Thêm loại tùy chỉnh
            </button>
          </div>
        </div>
        <div class="p-6 border-t flex justify-end space-x-3">
          <button @click="showModal = false" class="px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 rounded-lg">
            Huỷ
          </button>
          <button @click="save" :disabled="!form.code || !form.name"
            class="px-4 py-2 text-sm bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50">
            {{ editingId ? 'Cập nhật' : 'Tạo dự án' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { $supabase } = useNuxtApp()
const { isAdmin } = useAuth()
const { createProject, updateProject, deleteProject, loadProjects } = useProject()
const { addType: insertType } = useStructures()
const router = useRouter()

const allProjects = ref<any[]>([])
const showModal = ref(false)
const editingId = ref<string | null>(null)
const existingTypes = ref<any[]>([])

const form = reactive({
  code: '',
  name: '',
  description: '',
  km_range: '',
  consortium: '',
  start_date: '',
  end_date: '',
  is_active: true,
  has_left_right: false,
  drive_folder_url: '',
  types: [] as { code: string; name: string; id?: string }[],
})

function resetForm() {
  form.code = ''
  form.name = ''
  form.description = ''
  form.km_range = ''
  form.consortium = ''
  form.start_date = ''
  form.end_date = ''
  form.is_active = true
  form.has_left_right = false
  form.drive_folder_url = ''
  form.types = []
  existingTypes.value = []
  editingId.value = null
}

// Preset structure types for quick-add
const PRESET_TYPES = [
  { code: 'DUONG', name: 'Đường' },
  { code: 'CAU', name: 'Cầu' },
  { code: 'HAM', name: 'Hầm' },
  { code: 'CONG', name: 'Cống' },
  { code: 'TUONG_CHAN', name: 'Tường chắn' },
  { code: 'HAM_CHUI', name: 'Hầm chui dân sinh' },
  { code: 'NUT_GIAO', name: 'Nút giao' },
  { code: 'TRAM_THU_PHI', name: 'Trạm thu phí' },
  { code: 'HE_THONG_THOAT_NUOC', name: 'Hệ thống thoát nước' },
  { code: 'DIEN_CHIEU_SANG', name: 'Điện chiếu sáng' },
  { code: 'AN_TOAN_GT', name: 'An toàn giao thông' },
  { code: 'CAY_XANH', name: 'Cây xanh' },
]

const availablePresets = computed(() => {
  const usedCodes = form.types.map(t => t.code)
  return PRESET_TYPES.filter(p => !usedCodes.includes(p.code))
})

function addPreset(p: { code: string; name: string }) {
  form.types.push({ code: p.code, name: p.name })
}

function addTypeRow() {
  const idx = form.types.length + 1
  form.types.push({ code: `LOAI_${idx}`, name: '' })
}

function removeType(idx: number) {
  form.types.splice(idx, 1)
}

function openNew() {
  resetForm()
  showModal.value = true
}

async function openEdit(p: any) {
  editingId.value = p.id
  form.code = p.code
  form.name = p.name
  form.description = p.description || ''
  form.km_range = p.km_range || ''
  form.consortium = p.consortium || ''
  form.start_date = p.start_date || ''
  form.end_date = p.end_date || ''
  form.is_active = p.is_active
  form.has_left_right = p.has_left_right ?? false
  form.drive_folder_url = p.drive_folder_url || ''

  // Load existing types for this project
  try {
    const { data, error } = await $supabase
      .from('structure_types')
      .select('*')
      .eq('project_id', p.id)
      .order('sort_order')
    if (!error && data) {
      existingTypes.value = data
      form.types = data.map((t: any) => ({ id: t.id, code: t.code, name: t.name }))
    } else {
      existingTypes.value = []
      form.types = []
    }
  } catch {
    existingTypes.value = []
    form.types = []
  }
  showModal.value = true
}

async function save() {
  try {
    const projectData = {
      code: form.code,
      name: form.name,
      description: form.description || null,
      km_range: form.km_range || null,
      consortium: form.consortium || null,
      start_date: form.start_date || null,
      end_date: form.end_date || null,
      is_active: form.is_active,
      has_left_right: form.has_left_right,
      drive_folder_url: form.drive_folder_url || null,
    }
    let projectId = editingId.value

    if (projectId) {
      await updateProject(projectId, projectData as any)
    } else {
      const newProject = await createProject(projectData as any)
      projectId = newProject.id
    }

    // Save structure types
    const validTypes = form.types.filter(t => t.code.trim() && t.name.trim())

    if (editingId.value) {
      // Editing: delete removed types, update existing, add new
      const existingIds = existingTypes.value.map(t => t.id)
      const formIds = validTypes.filter(t => t.id).map(t => t.id)
      // Delete removed
      for (const id of existingIds) {
        if (!formIds.includes(id)) {
          await $supabase.from('structure_types').delete().eq('id', id)
        }
      }
      // Update existing, insert new
      for (let i = 0; i < validTypes.length; i++) {
        const t = validTypes[i]
        if (t.id) {
          await $supabase.from('structure_types')
            .update({ code: t.code.trim(), name: t.name.trim(), sort_order: i })
            .eq('id', t.id)
        } else {
          await $supabase.from('structure_types')
            .insert({ code: t.code.trim(), name: t.name.trim(), project_id: projectId, sort_order: i })
        }
      }
    } else {
      // New project: insert all types
      if (validTypes.length > 0) {
        const rows = validTypes.map((t, i) => ({
          code: t.code.trim(),
          name: t.name.trim(),
          project_id: projectId,
          sort_order: i,
        }))
        await $supabase.from('structure_types').insert(rows)
      }
    }

    showModal.value = false
    await reload()
    await loadProjects()
  } catch (e: any) {
    alert('Lỗi: ' + e.message)
  }
}

async function confirmDelete(p: any) {
  if (!confirm(`Xoá dự án "${p.code} – ${p.name}"?\nTất cả công trình và nhật ký thuộc dự án sẽ bị xoá!`)) return
  try {
    await deleteProject(p.id)
    await reload()
    await loadProjects()
  } catch (e: any) {
    alert('Lỗi: ' + e.message)
  }
}

async function reload() {
  const { data } = await $supabase
    .from('projects')
    .select('*')
    .order('code')
  allProjects.value = data || []

  // Count types and structures per project
  for (const p of allProjects.value) {
    try {
      const [typesRes, structRes] = await Promise.all([
        $supabase.from('structure_types').select('id', { count: 'exact', head: true }).eq('project_id', p.id),
        $supabase.from('structures').select('id', { count: 'exact', head: true }).eq('project_id', p.id),
      ])
      p._typeCount = typesRes.count || 0
      p._structCount = structRes.count || 0
    } catch {
      p._typeCount = 0
      p._structCount = 0
    }
  }
}

onMounted(async () => {
  if (!isAdmin.value) {
    router.push('/')
    return
  }
  await reload()
})
</script>
