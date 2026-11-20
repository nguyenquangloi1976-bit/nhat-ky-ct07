<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-xl font-bold text-gray-800">Nguồn vật liệu</h1>
        <p class="text-sm text-gray-500 mt-1">Theo khoản 5–7, Điều 14, NĐ 207/2026/NĐ-CP</p>
      </div>
      <button @click="showAdd = true"
        class="px-3 py-2 bg-primary-600 text-white text-sm rounded-lg hover:bg-primary-700">
        + Thêm nguồn vật liệu
      </button>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-3 gap-3 mb-6">
      <div class="bg-white rounded-lg shadow-sm p-3 border">
        <p class="text-xs text-gray-500">Tổng nguồn</p>
        <p class="text-xl font-bold text-gray-700">{{ stats.total }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-sm p-3 border">
        <p class="text-xs text-gray-500">Đã chấp thuận</p>
        <p class="text-xl font-bold text-green-600">{{ stats.approved }}</p>
      </div>
      <div class="bg-white rounded-lg shadow-sm p-3 border">
        <p class="text-xs text-gray-500">Chưa trình</p>
        <p class="text-xl font-bold text-gray-400">{{ stats.pending }}</p>
      </div>
    </div>

    <!-- Search -->
    <div class="mb-4">
      <div class="relative">
        <input v-model="searchQuery" type="text" placeholder="Tìm kiếm vật liệu..."
          class="w-full border rounded-lg pl-9 pr-3 py-1.5 text-sm" />
        <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="text-center py-12 text-gray-400">Đang tải...</div>

    <!-- Material List -->
    <div v-else class="space-y-4">
      <div v-if="filteredSources.length === 0" class="bg-white rounded-lg shadow-sm border p-8 text-center text-gray-400">
        Chưa có nguồn vật liệu nào
      </div>

      <div v-for="src in filteredSources" :key="src.id"
        class="bg-white rounded-lg shadow-sm border overflow-hidden">
        <div class="p-4">
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <div class="flex items-center space-x-2">
                <h3 class="font-medium text-gray-800">{{ src.material_name }}</h3>
                <span :class="['px-2 py-0.5 text-xs rounded-full', MAT_STATUS_COLORS[src.status]]">
                  {{ MAT_STATUS_LABELS[src.status] }}
                </span>
              </div>
              <div class="mt-2 text-sm text-gray-600 space-y-0.5">
                <p v-if="src.supplier">
                  <span class="text-gray-400">NCC:</span> {{ src.supplier }}
                </p>
                <p v-if="src.supplier_address">
                  <span class="text-gray-400">Địa chỉ:</span> {{ src.supplier_address }}
                </p>
                <p v-if="src.distance_km != null">
                  <span class="text-gray-400">Cự ly:</span> {{ src.distance_km }} km
                </p>
                <p v-if="src.approved_date">
                  <span class="text-gray-400">Ngày duyệt:</span> {{ src.approved_date }}
                </p>
              </div>

              <!-- Hồ sơ chất lượng -->
              <div class="mt-3 flex flex-wrap gap-2">
                <span :class="['px-2 py-0.5 text-xs rounded-full border',
                  src.has_cert_quality ? 'bg-green-50 text-green-700 border-green-200' : 'bg-gray-50 text-gray-400 border-gray-200']">
                  {{ src.has_cert_quality ? '✓' : '○' }} CN chất lượng
                </span>
                <span :class="['px-2 py-0.5 text-xs rounded-full border',
                  src.has_cert_origin ? 'bg-green-50 text-green-700 border-green-200' : 'bg-gray-50 text-gray-400 border-gray-200']">
                  {{ src.has_cert_origin ? '✓' : '○' }} Xuất xứ
                </span>
                <span :class="['px-2 py-0.5 text-xs rounded-full border',
                  src.has_cert_compliance ? 'bg-green-50 text-green-700 border-green-200' : 'bg-gray-50 text-gray-400 border-gray-200']">
                  {{ src.has_cert_compliance ? '✓' : '○' }} Hợp quy
                </span>
                <span :class="['px-2 py-0.5 text-xs rounded-full border',
                  src.has_test_result ? 'bg-green-50 text-green-700 border-green-200' : 'bg-gray-50 text-gray-400 border-gray-200']">
                  {{ src.has_test_result ? '✓' : '○' }} Thí nghiệm
                </span>
                <span :class="['px-2 py-0.5 text-xs rounded-full border',
                  src.has_mining_permit ? 'bg-green-50 text-green-700 border-green-200' : 'bg-gray-50 text-gray-400 border-gray-200']">
                  {{ src.has_mining_permit ? '✓' : '○' }} GP khai thác
                </span>
              </div>

              <div v-if="src.file_url" class="mt-2">
                <a :href="src.file_url" target="_blank" rel="noopener"
                  class="text-xs text-blue-600 hover:underline inline-flex items-center space-x-1">
                  <span>📎</span><span>Xem hồ sơ</span>
                </a>
              </div>
              <p v-if="src.notes" class="text-xs text-gray-400 mt-2">{{ src.notes }}</p>
            </div>
            <div class="flex items-center space-x-2 ml-3 flex-shrink-0">
              <button @click="editSource(src)" class="text-gray-400 hover:text-primary-600 text-xs">Sửa</button>
              <button @click="confirmDelete(src)" class="text-gray-400 hover:text-red-600 text-xs">Xóa</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Thêm/Sửa -->
    <div v-if="showAdd || editingSrc" class="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
      @click.self="closeModal">
      <div class="bg-white rounded-xl shadow-xl w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto">
        <div class="p-5 border-b">
          <h2 class="text-lg font-semibold">{{ editingSrc ? 'Sửa nguồn vật liệu' : 'Thêm nguồn vật liệu' }}</h2>
        </div>
        <div class="p-5 space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Tên vật liệu *</label>
            <input v-model="form.material_name" class="w-full border rounded-lg px-3 py-2 text-sm"
              placeholder="VD: Đất đắp K95, Đá dăm 0x4, Xi măng PC40..." />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Nhà cung cấp / Mỏ</label>
            <input v-model="form.supplier" class="w-full border rounded-lg px-3 py-2 text-sm"
              placeholder="VD: Mỏ đất Phú Bình, Trạm trộn BT số 2..." />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Địa chỉ nguồn cung</label>
            <input v-model="form.supplier_address" class="w-full border rounded-lg px-3 py-2 text-sm"
              placeholder="VD: Xã ABC, huyện XYZ, tỉnh Thái Nguyên" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Khoảng cách (km)</label>
              <input v-model.number="form.distance_km" type="number" step="0.1"
                class="w-full border rounded-lg px-3 py-2 text-sm" placeholder="15.5" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Trạng thái</label>
              <select v-model="form.status" class="w-full border rounded-lg px-3 py-2 text-sm">
                <option v-for="(label, code) in MAT_STATUS_LABELS" :key="code" :value="code">{{ label }}</option>
              </select>
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Ngày được chấp thuận</label>
            <input v-model="form.approved_date" type="date" class="w-full border rounded-lg px-3 py-2 text-sm" />
          </div>

          <!-- Upload / Link hồ sơ -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Hồ sơ đính kèm</label>
            <div v-if="!form.file_url">
              <div class="flex items-center gap-2">
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
              <div class="mt-2">
                <input v-model="manualUrl" type="url" class="w-full border rounded-lg px-3 py-2 text-sm"
                  placeholder="Hoặc dán link Google Drive..." @change="manualUrl && (form.file_url = manualUrl)" />
              </div>
            </div>
            <div v-else class="flex items-center gap-2 mt-1 p-2 bg-green-50 rounded-lg border border-green-200">
              <span class="text-green-600">✓</span>
              <a :href="form.file_url" target="_blank" class="text-xs text-blue-600 hover:underline truncate flex-1">
                {{ form.file_url }}
              </a>
              <button @click="form.file_url = ''" type="button" class="text-xs text-gray-400 hover:text-red-500">✕</button>
            </div>
            <div v-if="uploading" class="mt-1">
              <div class="w-full bg-gray-200 rounded-full h-2">
                <div class="bg-blue-600 h-2 rounded-full transition-all" :style="{ width: uploadProgress + '%' }"></div>
              </div>
              <p class="text-xs text-gray-500 mt-0.5">{{ uploadProgress }}%</p>
            </div>
            <p v-if="uploadError" class="text-xs text-red-600 mt-1">{{ uploadError }}</p>
          </div>

          <!-- Hồ sơ chất lượng -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Hồ sơ chất lượng</label>
            <div class="space-y-2">
              <label class="flex items-center space-x-2 text-sm">
                <input v-model="form.has_cert_quality" type="checkbox" class="rounded" />
                <span>Chứng nhận chất lượng của nhà sản xuất</span>
              </label>
              <label class="flex items-center space-x-2 text-sm">
                <input v-model="form.has_cert_origin" type="checkbox" class="rounded" />
                <span>Chứng từ xuất xứ</span>
              </label>
              <label class="flex items-center space-x-2 text-sm">
                <input v-model="form.has_cert_compliance" type="checkbox" class="rounded" />
                <span>Giấy chứng nhận hợp quy</span>
              </label>
              <label class="flex items-center space-x-2 text-sm">
                <input v-model="form.has_test_result" type="checkbox" class="rounded" />
                <span>Kết quả thí nghiệm vật liệu</span>
              </label>
              <label class="flex items-center space-x-2 text-sm">
                <input v-model="form.has_mining_permit" type="checkbox" class="rounded" />
                <span>Giấy phép khai thác mỏ</span>
              </label>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Ghi chú</label>
            <textarea v-model="form.notes" rows="2" class="w-full border rounded-lg px-3 py-2 text-sm"></textarea>
          </div>
        </div>
        <div class="p-5 border-t flex justify-end space-x-3">
          <button @click="closeModal" class="px-4 py-2 text-sm text-gray-600 border rounded-lg hover:bg-gray-50">Hủy</button>
          <button @click="saveSrc" :disabled="!form.material_name"
            class="px-4 py-2 text-sm bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50">
            {{ editingSrc ? 'Cập nhật' : 'Thêm' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const {
  sources, loading, stats,
  loadSources, addSource, updateSource, deleteSource,
  MAT_STATUS_LABELS, MAT_STATUS_COLORS,
} = useMaterialSources()

const { showToast } = useToast()
const { uploadFile, uploading, uploadError, uploadProgress } = useUploadDrive()
const { currentProject } = useProject()

// Extract Google Drive folder ID from URL
function driveFolderId(): string | undefined {
  const url = currentProject.value?.drive_folder_url
  if (!url) return undefined
  const m = url.match(/folders\/([a-zA-Z0-9_-]+)/)
  return m ? m[1] : undefined
}
const selectedFile = ref<File | null>(null)
const manualUrl = ref('')

function onFileSelect(e: Event) {
  const input = e.target as HTMLInputElement
  if (input.files?.length) {
    selectedFile.value = input.files[0]
  }
}

async function doUpload() {
  if (!selectedFile.value) return
  const url = await uploadFile(selectedFile.value, driveFolderId())
  if (url) {
    form.value.file_url = url
    selectedFile.value = null
  }
}

const showAdd = ref(false)
const searchQuery = ref('')

const filteredSources = computed(() => {
  if (!searchQuery.value) return sources.value
  const q = searchQuery.value.toLowerCase()
  return sources.value.filter(s =>
    s.material_name.toLowerCase().includes(q) ||
    (s.supplier && s.supplier.toLowerCase().includes(q)) ||
    (s.supplier_address && s.supplier_address.toLowerCase().includes(q)) ||
    (s.notes && s.notes.toLowerCase().includes(q))
  )
})
const editingSrc = ref<any>(null)

const defaultForm = () => ({
  material_name: '',
  supplier: '',
  supplier_address: '',
  distance_km: null as number | null,
  status: 'chua_trinh' as string,
  approved_date: '',
  has_cert_quality: false,
  has_cert_origin: false,
  has_cert_compliance: false,
  has_test_result: false,
  has_mining_permit: false,
  file_url: '',
  notes: '',
})

const form = ref(defaultForm())

function editSource(src: any) {
  editingSrc.value = src
  form.value = {
    material_name: src.material_name,
    supplier: src.supplier || '',
    supplier_address: src.supplier_address || '',
    distance_km: src.distance_km,
    status: src.status,
    approved_date: src.approved_date || '',
    has_cert_quality: src.has_cert_quality,
    has_cert_origin: src.has_cert_origin,
    has_cert_compliance: src.has_cert_compliance,
    has_test_result: src.has_test_result,
    has_mining_permit: src.has_mining_permit,
    file_url: src.file_url || '',
    notes: src.notes || '',
  }
}

function closeModal() {
  showAdd.value = false
  editingSrc.value = null
  form.value = defaultForm()
}

async function saveSrc() {
  try {
    const payload: any = {
      material_name: form.value.material_name,
      supplier: form.value.supplier || null,
      supplier_address: form.value.supplier_address || null,
      distance_km: form.value.distance_km,
      status: form.value.status,
      approved_date: form.value.approved_date || null,
      has_cert_quality: form.value.has_cert_quality,
      has_cert_origin: form.value.has_cert_origin,
      has_cert_compliance: form.value.has_cert_compliance,
      has_test_result: form.value.has_test_result,
      has_mining_permit: form.value.has_mining_permit,
      file_url: form.value.file_url || null,
      notes: form.value.notes || null,
    }
    if (editingSrc.value) {
      await updateSource(editingSrc.value.id, payload)
      showToast('Đã cập nhật', 'success')
    } else {
      await addSource(payload)
      showToast('Đã thêm nguồn vật liệu', 'success')
    }
    closeModal()
    await loadSources()
  } catch (e: any) {
    showToast(e.message || 'Lỗi', 'error')
  }
}

async function confirmDelete(src: any) {
  if (!confirm(`Xóa "${src.material_name}"?`)) return
  try {
    await deleteSource(src.id)
    showToast('Đã xóa', 'success')
  } catch (e: any) {
    showToast(e.message || 'Lỗi xóa', 'error')
  }
}

onMounted(() => loadSources())
</script>
