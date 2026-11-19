<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Top Nav -->
    <nav class="bg-white shadow-sm border-b border-gray-200">
      <div class="max-w-7xl mx-auto px-4">
        <div class="flex justify-between h-14">
          <!-- Left: Logo + Project Selector + Links -->
          <div class="flex items-center space-x-4">
            <NuxtLink to="/" class="text-lg font-bold text-primary-700">
              NKTC
            </NuxtLink>

            <!-- Project Selector -->
            <div v-if="projects.length > 0" class="relative" ref="dropdownRef">
              <button @click="showDropdown = !showDropdown"
                class="flex items-center space-x-1.5 px-3 py-1.5 rounded-lg bg-primary-50 text-primary-700 text-sm font-medium hover:bg-primary-100 transition border border-primary-200">
                <span>{{ currentProject?.code || 'Chọn dự án' }}</span>
                <svg class="w-3.5 h-3.5 transition-transform" :class="{ 'rotate-180': showDropdown }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                </svg>
              </button>
              <div v-if="showDropdown"
                class="absolute top-full left-0 mt-1 w-72 bg-white rounded-lg shadow-lg border z-50 py-1 max-h-64 overflow-y-auto">
                <button v-for="p in projects" :key="p.id"
                  @click="switchProject(p)"
                  :class="[
                    'w-full text-left px-4 py-2.5 hover:bg-gray-50 transition',
                    p.id === currentProject?.id ? 'bg-primary-50' : ''
                  ]">
                  <div class="flex items-center justify-between">
                    <div>
                      <span class="text-sm font-medium text-gray-800">{{ p.code }}</span>
                      <span class="text-xs text-gray-400 ml-2">{{ p.name.length > 30 ? p.name.substring(0, 30) + '...' : p.name }}</span>
                    </div>
                    <svg v-if="p.id === currentProject?.id" class="w-4 h-4 text-primary-600" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
                    </svg>
                  </div>
                </button>
              </div>
            </div>

            <div class="flex items-center space-x-4 ml-2">
              <NuxtLink to="/diary" class="nav-link" active-class="nav-active">
                Nhật ký
              </NuxtLink>
              <NuxtLink to="/tong-hop-nhat-ky" class="nav-link" active-class="nav-active">
                Toàn bộ nhật ký
              </NuxtLink>
              <NuxtLink to="/cat-doc" class="nav-link" active-class="nav-active">
                Cắt dọc
              </NuxtLink>
              <NuxtLink to="/tai-lieu" class="nav-link" active-class="nav-active">
                Tài liệu
              </NuxtLink>
              <NuxtLink to="/vat-lieu" class="nav-link" active-class="nav-active">
                Vật liệu
              </NuxtLink>
              <NuxtLink to="/reports" class="nav-link" active-class="nav-active">
                Báo cáo
              </NuxtLink>
              <NuxtLink v-if="isAdmin" to="/admin" class="nav-link" active-class="nav-active">
                Quản trị
              </NuxtLink>
            </div>
          </div>
          <!-- Right: User info -->
          <div class="flex items-center space-x-3">
            <button @click="showPwdModal = true"
              class="text-sm text-gray-600 hover:text-primary-700 cursor-pointer underline-offset-2 hover:underline"
              title="Đổi mật khẩu">
              {{ userName }}
            </button>
            <span v-if="isAdmin" class="px-2 py-0.5 text-xs bg-primary-100 text-primary-700 rounded-full">Admin</span>
            <button @click="logout" class="text-sm text-gray-500 hover:text-red-600">
              Đăng xuất
            </button>
          </div>
        </div>
      </div>
    </nav>

    <!-- Main Content -->
    <main class="max-w-7xl mx-auto px-4 py-6">
      <slot />
    </main>

    <!-- Modal Đổi mật khẩu -->
    <div v-if="showPwdModal" class="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
      @click.self="closePwdModal">
      <div class="bg-white rounded-xl shadow-xl w-full max-w-sm mx-4">
        <div class="p-5 border-b">
          <h2 class="text-lg font-semibold text-gray-800">Đổi mật khẩu</h2>
        </div>
        <div class="p-5 space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Mật khẩu mới</label>
            <input v-model="newPassword" type="password" class="w-full border rounded-lg px-3 py-2 text-sm"
              placeholder="Nhập mật khẩu mới (tối thiểu 6 ký tự)" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Xác nhận mật khẩu</label>
            <input v-model="confirmPassword" type="password" class="w-full border rounded-lg px-3 py-2 text-sm"
              placeholder="Nhập lại mật khẩu mới" @keyup.enter="submitChangePassword" />
          </div>
          <p v-if="pwdError" class="text-sm text-red-600">{{ pwdError }}</p>
          <p v-if="pwdSuccess" class="text-sm text-green-600">{{ pwdSuccess }}</p>
        </div>
        <div class="p-5 border-t flex justify-end space-x-3">
          <button @click="closePwdModal" class="px-4 py-2 text-sm text-gray-600 border rounded-lg hover:bg-gray-50">
            Đóng
          </button>
          <button @click="submitChangePassword" :disabled="pwdLoading"
            class="px-4 py-2 text-sm bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50">
            {{ pwdLoading ? 'Đang xử lý...' : 'Đổi mật khẩu' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Toast -->
    <ToastNotification />
  </div>
</template>

<script setup lang="ts">
const { profile, signOut, changePassword } = useAuth()
const { projects, currentProject, selectProject } = useProject()

const userName = computed(() => profile.value?.full_name || 'User')
const isAdmin = computed(() => profile.value?.role === 'admin')

const showDropdown = ref(false)
const dropdownRef = ref<HTMLElement | null>(null)

// --- Đổi mật khẩu ---
const showPwdModal = ref(false)
const newPassword = ref('')
const confirmPassword = ref('')
const pwdError = ref('')
const pwdSuccess = ref('')
const pwdLoading = ref(false)

function closePwdModal() {
  showPwdModal.value = false
  newPassword.value = ''
  confirmPassword.value = ''
  pwdError.value = ''
  pwdSuccess.value = ''
}

async function submitChangePassword() {
  pwdError.value = ''
  pwdSuccess.value = ''

  if (!newPassword.value || newPassword.value.length < 6) {
    pwdError.value = 'Mật khẩu mới phải có ít nhất 6 ký tự'
    return
  }
  if (newPassword.value !== confirmPassword.value) {
    pwdError.value = 'Mật khẩu xác nhận không khớp'
    return
  }

  pwdLoading.value = true
  try {
    await changePassword(newPassword.value)
    pwdSuccess.value = 'Đổi mật khẩu thành công!'
    newPassword.value = ''
    confirmPassword.value = ''
    setTimeout(() => closePwdModal(), 1500)
  } catch (e: any) {
    pwdError.value = e.message || 'Đổi mật khẩu thất bại'
  } finally {
    pwdLoading.value = false
  }
}

function switchProject(p: any) {
  selectProject(p)
  showDropdown.value = false
  // Reload current page to refresh data
  window.location.reload()
}

// Close dropdown on outside click
function onClickOutside(e: MouseEvent) {
  if (dropdownRef.value && !dropdownRef.value.contains(e.target as Node)) {
    showDropdown.value = false
  }
}

onMounted(() => document.addEventListener('click', onClickOutside))
onUnmounted(() => document.removeEventListener('click', onClickOutside))

async function logout() {
  await signOut()
  navigateTo('/login')
}
</script>

<style>
.nav-link {
  @apply text-sm text-gray-600 hover:text-primary-700 py-4 border-b-2 border-transparent;
}
.nav-active {
  @apply text-primary-700 border-primary-700;
}
</style>
