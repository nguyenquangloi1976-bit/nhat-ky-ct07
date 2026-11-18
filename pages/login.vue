<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-100">
    <div class="bg-white p-8 rounded-xl shadow-md w-full max-w-sm">
      <h1 class="text-xl font-bold text-center text-primary-700 mb-1">Nhật ký thi công</h1>
      <p class="text-sm text-center text-gray-500 mb-6">CT.07 Hà Nội – Thái Nguyên</p>

      <form @submit.prevent="handleLogin" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
          <input v-model="email" type="email" required
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 text-sm"
            placeholder="email@example.com" />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Mật khẩu</label>
          <input v-model="password" type="password" required
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500 text-sm"
            placeholder="••••••••" />
        </div>
        <button type="submit" :disabled="submitting"
          class="w-full py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 text-sm font-medium">
          {{ submitting ? 'Đang đăng nhập...' : 'Đăng nhập' }}
        </button>
        <p v-if="errorMsg" class="text-sm text-red-600 text-center">{{ errorMsg }}</p>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: false })

const { signIn } = useAuth()
const email = ref('')
const password = ref('')
const submitting = ref(false)
const errorMsg = ref('')

async function handleLogin() {
  submitting.value = true
  errorMsg.value = ''
  try {
    await signIn(email.value, password.value)
    navigateTo('/')
  } catch (e: any) {
    errorMsg.value = e.message || 'Đăng nhập thất bại'
  } finally {
    submitting.value = false
  }
}
</script>
