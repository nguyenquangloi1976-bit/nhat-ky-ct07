<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-xl font-bold text-gray-800">Tài liệu đệ trình</h1>
        <p class="text-sm text-gray-500 mt-1">Theo Điều 15, Nghị định 207/2026/NĐ-CP</p>
      </div>
      <button @click="showAdd = true"
        class="px-3 py-2 bg-primary-600 text-white text-sm rounded-lg hover:bg-primary-700">
        + Thêm tài liệu
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
        <p class="text-xs text-gray-500">Chưa nộp</p>
        <p class="text-xl font-bold text-gray-400">{{ stats.pending }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-sm p-3 border">
        <p class="text-xs text-gray-500">Yêu cầu sửa</p>
        <p class="text-xl font-bold text-red-600">{{ stats.needFix }}</p>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="text-center py-12 text-gray-400">Đang tải...</div>

    <!-- Groups -->
    <div v-else class="space-y-6">
      <div v-for="(code, idx) in ['A','B','C','D']" :key="code"
        class="bg-white rounded-lg shadow-sm border overflow-hidden">
        <!-- Group Header -->
        <div class="px-4 py-3 bg-gray-50 border-b flex items-center justify-between cursor-pointer"
          @click="toggleGroup(code)">
          <div class="flex items-center space-x-2">
            <span class="text-xs font-bold text-primary-700 bg-primary-100 px-2 py-0.5 rounded">{{ code }}</span>
            <span class="font-medium text-gray-700 text-sm">{{ GROUP_LABELS[code] }}</span>
            <span class="text-xs text-gray-400">({{ (grouped[code] || []).length }})</span>
          </div>
          <svg class="w-4 h-4 text-gray-400 transition-transform"
            :class="{ 'rotate-180': !collapsed[code] }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
          </svg>
        </div>

        <!-- Doc List -->
        <div v-show="!collapsed[code]" class="divide-y">
          <div v-if="(grouped[code] || []).length === 0" class="p-4 text-center text-gray-400 text-sm">
            Chưa có tài liệu
          </div>
          <div v-for="doc in (grouped[code] || [])" :key="doc.id"
            class="px-4 py-3 hover:bg-gray-50 transition">
            <div class="flex items-start justify-between">
              <div class="flex-1 min-w-0">
                <div class="flex items-center space-x-2">
                  <p class="text-sm font-medium text-gray-800 truncate">{{ doc.doc_name }}</p>
                </div>
                <div class="flex items-center space-x-3 mt-1 text-xs text-gray-500">
                  <span v-if="doc.doc_number">Số: {{ doc.doc_number }}</span>
                  <span v-if="doc.submitted_date">Nộp: {{ doc.submitted_date }}</span>
                  <span v-if="doc.approved_date">Duyệt: {{ doc.approved_date }}</span>
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
    </div>

    <!-- Modal Thêm/Sửa -->
    <div v-if="showAdd || editingDoc" class="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
      @click.self="closeModal">
      <div class="bg-white rounded-xl shadow-xl w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto">
        <div class="p-5 border-b">
          <h2 class="text-lg font-semibold">{{ editingDoc ? 'Sửa tài liệu' : 'Thêm tài liệu mới' }}</h2>
        </div>
        <div class="p-5 space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Nhóm</label>
            <select v-model="form.group_code" class="w-full border rounded-lg px-3 py-2 text-sm">
              <option v-for="(label, code) in GROUP_LABELS" :key="code" :value="code">{{ code }} – {{ label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Tên tài liệu *</label>
            <input v-model="form.doc_name" class="w-full border rounded-lg px-3 py-2 text-sm"
              placeholder="VD: Biện pháp thi công" />
          </div>
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
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Ghi chú TVGS</label>
            <textarea v-model="form.reviewer_notes" rows="2" class="w-full border rounded-lg px-3 py-2 text-sm"
              placeholder="Nhận xét / yêu cầu bổ sung của TVGS"></textarea>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Ghi chú</label>
            <textarea v-model="form.notes" rows="2" class="w-full border rounded-lg px-3 py-2 text-sm"
              placeholder="Ghi chú chung"></textarea>
          </div>
        </div>
        <div class="p-5 border-t flex justify-end space-x-3">
          <button @click="closeModal" class="px-4 py-2 text-sm text-gray-600 border rounded-lg hover:bg-gray-50">Hủy</button>
          <button @click="saveDoc" :disabled="!form.doc_name"
            class="px-4 py-2 text-sm bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50">
            {{ editingDoc ? 'Cập nhật' : 'Thêm' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const {
  docs, loading, grouped, stats,
  loadDocs, addDoc, updateDoc, deleteDoc,
  GROUP_LABELS, STATUS_LABELS, STATUS_COLORS,
} = useSubmissionDocs()

const { showToast } = useToast()
const { isAdmin } = useAuth()

const showAdd = ref(false)
const editingDoc = ref<any>(null)
const collapsed = ref<Record<string, boolean>>({ A: false, B: false, C: false, D: false })

const form = ref({
  group_code: 'A',
  doc_name: '',
  doc_number: '',
  status: 'chua_nop',
  submitted_date: '',
  approved_date: '',
  reviewer_notes: '',
  notes: '',
  sort_order: 0,
})

function toggleGroup(code: string) {
  collapsed.value[code] = !collapsed.value[code]
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
    reviewer_notes: doc.reviewer_notes || '',
    notes: doc.notes || '',
    sort_order: doc.sort_order || 0,
  }
}

function closeModal() {
  showAdd.value = false
  editingDoc.value = null
  form.value = {
    group_code: 'A', doc_name: '', doc_number: '', status: 'chua_nop',
    submitted_date: '', approved_date: '', reviewer_notes: '', notes: '', sort_order: 0,
  }
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
      reviewer_notes: form.value.reviewer_notes || null,
      notes: form.value.notes || null,
    }
    if (editingDoc.value) {
      await updateDoc(editingDoc.value.id, payload)
      showToast('Đã cập nhật', 'success')
    } else {
      await addDoc(payload)
      showToast('Đã thêm tài liệu', 'success')
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

onMounted(() => loadDocs())
</script>
