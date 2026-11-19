<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-xl font-bold text-gray-800">Tài liệu đệ trình</h1>
        <p class="text-sm text-gray-500 mt-1">Theo Điều 15, Nghị định 207/2026/NĐ-CP</p>
      </div>
      <button @click="openAdd"
        class="px-3 py-2 bg-primary-600 text-white text-sm rounded-lg hover:bg-primary-700">
        + Ghi nhận tài liệu
      </button>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
      <div class="bg-white rounded-lg shadow-sm p-3 border">
        <p class="text-xs text-gray-500">Tổng</p>
        <p class="text-xl font-bold text-gray-700">{{ stats.total }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-sm p-3 border">
        <p class="text-xs text-gray-500">Đã chấp thuận</p>
        <p class="text-xl font-bold text-green-600">{{ stats.approved }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-sm p-3 border">
        <p class="text-xs text-gray-500">Đang xem xét</p>
        <p class="text-xl font-bold text-blue-600">{{ stats.pending }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-sm p-3 border">
        <p class="text-xs text-gray-500">Yêu cầu sửa</p>
        <p class="text-xl font-bold text-red-600">{{ stats.needFix }}</p>
      </div>
    </div>

    <!-- Group Tabs -->
    <div class="flex items-center space-x-2 mb-4 overflow-x-auto pb-1">
      <button @click="filterGroup = ''"
        :class="['px-4 py-1.5 text-sm rounded-full border whitespace-nowrap transition',
          filterGroup === '' ? 'bg-primary-600 text-white border-primary-600' : 'bg-white text-gray-600 border-gray-300 hover:border-primary-400']">
        Tất cả ({{ docs.length }})
      </button>
      <button v-for="(label, code) in GROUP_LABELS" :key="code" @click="filterGroup = code"
        :class="['px-4 py-1.5 text-sm rounded-full border whitespace-nowrap transition',
          filterGroup === code ? 'bg-primary-600 text-white border-primary-600' : 'bg-white text-gray-600 border-gray-300 hover:border-primary-400']">
        {{ code }} – {{ label }} ({{ groupCount(code) }})
      </button>
    </div>

    <!-- Search + Status filter -->
    <div class="flex items-center flex-wrap gap-3 mb-4">
      <div class="relative flex-1 min-w-[200px]">
        <input v-model="searchQuery" type="text" placeholder="Tìm kiếm tài liệu..."
          class="w-full border rounded-lg pl-9 pr-3 py-1.5 text-sm" />
        <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
      </div>
      <select v-model="filterStatus" class="border rounded-lg px-3 py-1.5 text-sm">
        <option value="">Tất cả trạng thái</option>
        <option v-for="(label, code) in STATUS_LABELS" :key="code" :value="code">{{ label }}</option>
      </select>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="text-center py-12 text-gray-400">Đang tải...</div>

    <!-- Document List -->
    <div v-else class="bg-white rounded-lg shadow-sm border overflow-hidden">
      <div v-if="filtered.length === 0" class="p-8 text-center text-gray-400">
        Chưa có tài liệu nào được ghi nhận
      </div>
      <div v-else class="divide-y">
        <div v-for="doc in filtered" :key="doc.id" class="px-4 py-3 hover:bg-gray-50 transition">
          <div class="flex items-start justify-between">
            <div class="flex-1 min-w-0">
              <div class="flex items-center space-x-2">
                <span class="text-xs font-bold text-primary-700 bg-primary-100 px-1.5 py-0.5 rounded">{{ doc.group_code }}</span>
                <p class="text-sm font-medium text-gray-800 truncate">{{ doc.doc_name }}</p>
              </div>
              <div class="flex items-center flex-wrap gap-x-3 mt-1 text-xs text-gray-500">
                <span v-if="doc.doc_number">Số: {{ doc.doc_number }}</span>
                <span v-if="doc.submitted_date">Nộp: {{ doc.submitted_date }}</span>
                <span v-if="doc.approved_date">Duyệt: {{ doc.approved_date }}</span>
              </div>
              <div v-if="doc.file_url" class="mt-1">
                <a :href="doc.file_url" target="_blank" rel="noopener"
                  class="text-xs text-blue-600 hover:underline inline-flex items-center space-x-1">
                  <span>📎</span><span>Xem tài liệu</span>
                </a>
              </div>
              <p v-if="doc.reviewer_notes" class="text-xs text-orange-600 mt-1">
                TVGS: {{ doc.reviewer_notes }}
              </p>
              <p v-if="doc.notes" class="text-xs text-gray-400 mt-0.5">{{ doc.notes }}</p>
            </div>
            <div class="flex items-center space-x-2 ml-3 flex-shrink-0">
              <span :class="['px-2 py-0.5 text-xs rounded-full whitespace-nowrap', STATUS_COLORS[doc.status]]">
                {{ STATUS_LABELS[doc.status] }}
              </span>
              <button v-if="isAdmin" @click="editDoc(doc)" class="text-gray-400 hover:text-primary-600 text-xs">Sửa</button>
              <button v-if="isAdmin" @click="confirmDelete(doc)" class="text-gray-400 hover:text-red-600 text-xs">Xóa</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Thêm/Sửa -->
    <div v-if="showModal" class="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
      @click.self="closeModal">
      <div class="bg-white rounded-xl shadow-xl w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto">
        <div class="p-5 border-b">
          <h2 class="text-lg font-semibold">{{ editingDoc ? 'Sửa tài liệu' : 'Ghi nhận tài liệu đệ trình' }}</h2>
        </div>
        <div class="p-5 space-y-4">
          <!-- Nhóm -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Nhóm</label>
            <select v-model="form.group_code" class="w-full border rounded-lg px-3 py-2 text-sm">
              <option v-for="(label, code) in GROUP_LABELS" :key="code" :value="code">{{ code }} – {{ label }}</option>
            </select>
          </div>

          <!-- Tên tài liệu: gợi ý hoặc tự nhập -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Tên tài liệu *</label>
            <input v-model="form.doc_name" list="doc-suggestions"
              class="w-full border rounded-lg px-3 py-2 text-sm"
              placeholder="Chọn từ danh mục hoặc tự nhập..." />
            <datalist id="doc-suggestions">
              <option v-for="s in suggestionsForGroup" :key="s" :value="s" />
            </datalist>
            <p class="text-xs text-gray-400 mt-0.5">Gợi ý theo NĐ 207 — có thể tự nhập tên khác</p>
          </div>

          <!-- Số hiệu + Trạng thái -->
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Số hiệu văn bản</label>
              <input v-model="form.doc_number" class="w-full border rounded-lg px-3 py-2 text-sm"
                placeholder="VD: TV08-BPTC-01" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Trạng thái</label>
              <select v-model="form.status" class="w-full border rounded-lg px-3 py-2 text-sm">
                <option v-for="(label, code) in STATUS_LABELS" :key="code" :value="code">{{ label }}</option>
              </select>
            </div>
          </div>

          <!-- Ngày nộp + Ngày duyệt -->
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Ngày nộp</label>
              <input v-model="form.submitted_date" type="date" class="w-full border rounded-lg px-3 py-2 text-sm" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Ngày chấp thuận</label>
              <input v-model="form.approved_date" type="date" class="w-full border rounded-lg px-3 py-2 text-sm" />
            </div>
          </div>

          <!-- Upload tài liệu -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Tài liệu đính kèm</label>
            <div v-if="!form.file_url" class="flex items-center gap-2">
              <label class="flex-1 flex items-center justify-center border-2 border-dashed rounded-lg px-3 py-2.5 cursor-pointer hover:border-primary-400 transition"
                :class="selectedFile ? 'border-green-400 bg-green-50' : 'border-gray-300'">
                <input type="file" class="hidden" @change="onFileSelect"
                  accept=".pdf,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png" />
                <span v-if="!selectedFile" class="text-sm text-gray-500">📎 Chọn file để upload lên Drive</span>
                <span v-else class="text-sm text-green-700 truncate">{{ selectedFile.name }}</span>
              </label>
              <button v-if="selectedFile" @click="doUpload" :disabled="uploading" type="button"
                class="px-3 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 whitespace-nowrap">
                {{ uploading ? 'Đang tải...' : 'Upload' }}
              </button>
            </div>
            <div v-if="form.file_url" class="flex items-center gap-2 mt-1 p-2 bg-green-50 rounded-lg border border-green-200">
              <span class="text-green-600">✓</span>
              <a :href="form.file_url" target="_blank" class="text-xs text-blue-600 hover:underline truncate flex-1">
                {{ form.file_url }}
              </a>
              <button @click="form.file_url = ''; selectedFile = null" type="button"
                class="text-xs text-gray-400 hover:text-red-500">✕</button>
            </div>
            <p v-if="uploadError" class="text-xs text-red-600 mt-1">{{ uploadError }}</p>
          </div>

          <!-- Ghi chú TVGS -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Ghi chú TVGS</label>
            <textarea v-model="form.reviewer_notes" rows="2" class="w-full border rounded-lg px-3 py-2 text-sm"
              placeholder="Nhận xét / yêu cầu bổ sung của TVGS"></textarea>
          </div>

          <!-- Ghi chú -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Ghi chú</label>
            <textarea v-model="form.notes" rows="2" class="w-full border rounded-lg px-3 py-2 text-sm"></textarea>
          </div>
        </div>
        <div class="p-5 border-t flex justify-end space-x-3">
          <button @click="closeModal" class="px-4 py-2 text-sm text-gray-600 border rounded-lg hover:bg-gray-50">Hủy</button>
          <button @click="saveDoc" :disabled="!form.doc_name"
            class="px-4 py-2 text-sm bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50">
            {{ editingDoc ? 'Cập nhật' : 'Ghi nhận' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const {
  docs, loading, stats,
  loadDocs, addDoc, updateDoc, deleteDoc,
  GROUP_LABELS, STATUS_LABELS, STATUS_COLORS,
} = useSubmissionDocs()

const { showToast } = useToast()
const { isAdmin } = useAuth()
const { uploadFile, uploading, uploadError } = useUploadDrive()
const selectedFile = ref<File | null>(null)

const showModal = ref(false)
const editingDoc = ref<any>(null)
const filterStatus = ref('')
const filterGroup = ref('')
const searchQuery = ref('')

function onFileSelect(e: Event) {
  const input = e.target as HTMLInputElement
  if (input.files?.length) {
    selectedFile.value = input.files[0]
  }
}

async function doUpload() {
  if (!selectedFile.value) return
  const url = await uploadFile(selectedFile.value)
  if (url) form.value.file_url = url
}

// Danh mục gợi ý theo NĐ 207
const SUGGESTIONS: Record<string, string[]> = {
  A: [
    'Biện pháp thi công (kèm BP bảo đảm an toàn)',
    'Biện pháp bảo đảm an toàn thi công (Phụ lục III, NĐ 207)',
    'Kế hoạch an toàn giao thông',
    'Kế hoạch bảo vệ môi trường thi công',
    'Kế hoạch phòng cháy chữa cháy',
  ],
  B: [
    'Kế hoạch kiểm soát chất lượng vật liệu, sản phẩm, cấu kiện',
    'Kế hoạch tổ chức thí nghiệm, kiểm tra, kiểm định',
    'Kế hoạch kiểm tra, nghiệm thu công việc / giai đoạn',
    'Hồ sơ năng lực phòng thí nghiệm (LAS-XD, VILAS)',
  ],
  C: [
    'Tiến độ thi công chi tiết',
    'Chương trình huy động (nhân sự, thiết bị, mặt bằng)',
    'Hệ thống quản lý thi công (sơ đồ tổ chức, phân công)',
    'Danh sách nhân sự chủ chốt',
    'Danh mục thiết bị thi công (kèm giấy kiểm định)',
  ],
  D: [
    'Hồ sơ TKKT / BVTC được phê duyệt',
    'Chỉ dẫn kỹ thuật (CDKT)',
    'Đề cương thi công đại trà (sau đoạn thí điểm)',
  ],
}

const suggestionsForGroup = computed(() => SUGGESTIONS[form.value.group_code] || [])

const defaultForm = () => ({
  group_code: 'A',
  doc_name: '',
  doc_number: '',
  status: 'da_nop',
  submitted_date: new Date().toISOString().slice(0, 10),
  approved_date: '',
  file_url: '',
  reviewer_notes: '',
  notes: '',
  sort_order: 0,
})

const form = ref(defaultForm())

function groupCount(code: string) {
  return docs.value.filter(d => d.group_code === code).length
}

const filtered = computed(() => {
  let list = docs.value
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    list = list.filter(d =>
      d.doc_name.toLowerCase().includes(q) ||
      (d.doc_number && d.doc_number.toLowerCase().includes(q)) ||
      (d.notes && d.notes.toLowerCase().includes(q)) ||
      (d.reviewer_notes && d.reviewer_notes.toLowerCase().includes(q))
    )
  }
  if (filterStatus.value) list = list.filter(d => d.status === filterStatus.value)
  if (filterGroup.value) list = list.filter(d => d.group_code === filterGroup.value)
  return list
})

function openAdd() {
  editingDoc.value = null
  form.value = defaultForm()
  showModal.value = true
}

function editDoc(doc: any) {
  editingDoc.value = doc
  form.value = {
    group_code: doc.group_code,
    doc_name: doc.doc_name,
    doc_number: doc.doc_number || '',
    status: doc.status,
    submitted_date: doc.submitted_date || '',
    approved_date: doc.approved_date || '',
    file_url: doc.file_url || '',
    reviewer_notes: doc.reviewer_notes || '',
    notes: doc.notes || '',
    sort_order: doc.sort_order || 0,
  }
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  editingDoc.value = null
  selectedFile.value = null
}

async function saveDoc() {
  try {
    const payload: any = {
      group_code: form.value.group_code,
      doc_name: form.value.doc_name,
      status: form.value.status,
      sort_order: form.value.sort_order,
      doc_number: form.value.doc_number || null,
      submitted_date: form.value.submitted_date || null,
      approved_date: form.value.approved_date || null,
      file_url: form.value.file_url || null,
      reviewer_notes: form.value.reviewer_notes || null,
      notes: form.value.notes || null,
    }
    if (editingDoc.value) {
      await updateDoc(editingDoc.value.id, payload)
      showToast('Đã cập nhật', 'success')
    } else {
      await addDoc(payload)
      showToast('Đã ghi nhận', 'success')
    }
    closeModal()
    await loadDocs()
  } catch (e: any) {
    showToast(e.message || 'Lỗi', 'error')
  }
}

async function confirmDelete(doc: any) {
  if (!confirm(`Xóa "${doc.doc_name}"?`)) return
  try {
    await deleteDoc(doc.id)
    showToast('Đã xóa', 'success')
  } catch (e: any) {
    showToast(e.message || 'Lỗi xóa', 'error')
  }
}

const { currentProject } = useProject()

onMounted(() => loadDocs())

// Reload khi project sẵn sàng (load bất đồng bộ)
watch(() => currentProject.value, (val) => {
  if (val) loadDocs()
})
</script>
