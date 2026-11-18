<template>
  <div class="relative" ref="wrapper">
    <input
      type="text"
      v-model="search"
      :placeholder="placeholder"
      @focus="open = true"
      @input="open = true"
      class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
    />
    <!-- Clear button -->
    <button v-if="modelValue" @click.stop="clear"
      class="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 text-lg leading-none">
      &times;
    </button>
    <!-- Dropdown -->
    <div v-if="open && (filtered.length > 0 || showAdd)"
      class="absolute z-50 mt-1 w-full bg-white border border-gray-200 rounded-lg shadow-lg max-h-60 overflow-y-auto">
      <!-- Nút thêm mới -->
      <button v-if="showAdd" @mousedown.prevent="onAddNew"
        class="w-full text-left px-3 py-2 text-sm font-medium text-primary-600 hover:bg-primary-50 border-b border-gray-100">
        + Thêm hạng mục mới
      </button>
      <button v-for="opt in filtered" :key="opt.value"
        @mousedown.prevent="select(opt)"
        class="w-full text-left px-3 py-2 text-sm hover:bg-primary-50 hover:text-primary-700"
        :class="{ 'bg-primary-50 font-medium text-primary-700': opt.value === modelValue }">
        {{ opt.label }}
      </button>
    </div>
    <div v-else-if="open && search && filtered.length === 0"
      class="absolute z-50 mt-1 w-full bg-white border border-gray-200 rounded-lg shadow-lg">
      <!-- Nút thêm mới khi không tìm thấy -->
      <button v-if="showAdd" @mousedown.prevent="onAddNew"
        class="w-full text-left px-3 py-2 text-sm font-medium text-primary-600 hover:bg-primary-50">
        + Thêm hạng mục mới
      </button>
      <div class="p-3 text-sm text-gray-400 text-center">Không tìm thấy</div>
    </div>
  </div>
</template>

<script setup lang="ts">
export interface SelectOption {
  value: string
  label: string
}

const props = defineProps<{
  modelValue: string
  options: SelectOption[]
  placeholder?: string
  showAdd?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
  change: []
  'add-new': []
}>()

function onAddNew() {
  open.value = false
  emit('add-new')
}

const wrapper = ref<HTMLElement>()
const open = ref(false)
const search = ref('')

// Sync search text with selected option label
watch(() => props.modelValue, (val) => {
  if (val) {
    const opt = props.options.find(o => o.value === val)
    search.value = opt?.label || ''
  } else {
    search.value = ''
  }
}, { immediate: true })

// Also update when options change (async load)
watch(() => props.options, () => {
  if (props.modelValue) {
    const opt = props.options.find(o => o.value === props.modelValue)
    if (opt) search.value = opt.label
  }
})

const filtered = computed(() => {
  const q = search.value.toLowerCase().trim()
  if (!q) return props.options
  // Tách từ khóa, tìm bất kể từ nào trong label
  const words = q.split(/\s+/)
  return props.options.filter(o => {
    const label = o.label.toLowerCase()
    return words.every(w => label.includes(w))
  })
})

function select(opt: SelectOption) {
  search.value = opt.label
  open.value = false
  emit('update:modelValue', opt.value)
  emit('change')
}

function clear() {
  search.value = ''
  emit('update:modelValue', '')
  emit('change')
}

// Close on click outside
function onClickOutside(e: MouseEvent) {
  if (wrapper.value && !wrapper.value.contains(e.target as Node)) {
    open.value = false
    // Restore selected label if search doesn't match
    if (props.modelValue) {
      const opt = props.options.find(o => o.value === props.modelValue)
      if (opt) search.value = opt.label
    }
  }
}

onMounted(() => document.addEventListener('mousedown', onClickOutside))
onUnmounted(() => document.removeEventListener('mousedown', onClickOutside))
</script>
