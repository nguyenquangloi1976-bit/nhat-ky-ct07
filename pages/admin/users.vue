<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-gray-800">Quản lý người dùng</h1>
      <NuxtLink to="/admin" class="text-sm text-primary-600 hover:underline">← Quản trị</NuxtLink>
    </div>

    <!-- Create user form -->
    <div class="bg-white rounded-lg shadow-sm border p-6 mb-4">
      <h2 class="font-semibold text-gray-700 mb-3">Tạo tài khoản mới</h2>
      <form @submit.prevent="createUser" class="space-y-3">
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Email <span class="text-red-500">*</span></label>
            <input v-model="newUser.email" type="email" required
              class="input-field" placeholder="email@example.com" />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Mật khẩu <span class="text-red-500">*</span></label>
            <input v-model="newUser.password" type="text" required minlength="6"
              class="input-field" placeholder="Tối thiểu 6 ký tự" />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Họ tên</label>
            <input v-model="newUser.full_name" type="text"
              class="input-field" placeholder="Nguyễn Văn A" />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Đơn vị</label>
            <input v-model="newUser.organization" type="text"
              class="input-field" placeholder="TEDI, CTGT2..." />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Vai trò</label>
            <select v-model="newUser.role" class="input-field">
              <option value="engineer">Kỹ sư</option>
              <option value="tvgs_truong">TVGS trưởng</option>
              <option value="admin">Admin</option>
            </select>
          </div>
        </div>
        <div class="flex items-center gap-3 pt-1">
          <button type="submit" :disabled="creating"
            class="px-4 py-2 bg-primary-600 text-white text-sm rounded-lg hover:bg-primary-700 disabled:opacity-50">
            {{ creating ? 'Đang tạo...' : 'Tạo tài khoản' }}
          </button>
          <span v-if="createMsg" :class="createMsgOk ? 'text-green-600' : 'text-red-600'" class="text-sm">
            {{ createMsg }}
          </span>
        </div>
      </form>
    </div>

    <!-- User list -->
    <div class="bg-white rounded-lg shadow-sm border">
      <div v-if="loading" class="p-8 text-center text-gray-400">Đang tải...</div>
      <table v-else class="w-full text-sm">
        <thead class="bg-gray-50 text-gray-600">
          <tr>
            <th class="text-left px-4 py-3">Họ tên</th>
            <th class="text-left px-4 py-3">Email</th>
            <th class="text-left px-4 py-3">Đơn vị</th>
            <th class="text-center px-4 py-3">Vai trò</th>
            <th class="text-center px-4 py-3">Mật khẩu</th>
            <th class="px-4 py-3"></th>
          </tr>
        </thead>
        <tbody class="divide-y">
          <tr v-for="u in users" :key="u.id" class="hover:bg-gray-50">
            <td class="px-4 py-3">
              <input v-model="u.full_name" @blur="updateUser(u)" class="input-inline" />
            </td>
            <td class="px-4 py-3 text-gray-500">{{ u.email }}</td>
            <td class="px-4 py-3">
              <input v-model="u.organization" @blur="updateUser(u)" class="input-inline" placeholder="TEDI, CTGT2..." />
            </td>
            <td class="px-4 py-3 text-center">
              <select v-model="u.role" @change="updateUser(u)" class="input-xs">
                <option value="engineer">Kỹ sư</option>
                <option value="tvgs_truong">TVGS trưởng</option>
                <option value="admin">Admin</option>
              </select>
            </td>
            <td class="px-4 py-3 text-center">
              <div v-if="u._resetMode" class="flex items-center gap-1">
                <input v-model="u._newPw" type="text" placeholder="Mật khẩu mới"
                  class="w-28 px-2 py-1 border border-gray-300 rounded text-xs focus:ring-1 focus:ring-primary-500" />
                <button @click="doResetPassword(u)" :disabled="u._resetting"
                  class="px-2 py-1 bg-green-600 text-white text-xs rounded hover:bg-green-700 disabled:opacity-50">
                  {{ u._resetting ? '...' : 'OK' }}
                </button>
                <button @click="u._resetMode = false"
                  class="px-2 py-1 text-gray-500 text-xs hover:text-gray-700">✕</button>
              </div>
              <button v-else @click="u._resetMode = true; u._newPw = ''"
                class="px-2 py-1 text-xs text-orange-600 hover:text-orange-800 hover:bg-orange-50 rounded">
                Đặt lại
              </button>
            </td>
            <td class="px-4 py-3 text-right">
              <span v-if="u.saving" class="text-xs text-gray-400">Đang lưu...</span>
              <span v-if="u.saved" class="text-xs text-green-600">Đã lưu ✓</span>
              <span v-if="u._resetMsg" :class="u._resetOk ? 'text-green-600' : 'text-red-600'" class="text-xs">
                {{ u._resetMsg }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { createClient } from '@supabase/supabase-js'

definePageMeta({ middleware: 'auth' })

const { $supabase } = useNuxtApp()
const config = useRuntimeConfig()
const { isAdmin } = useAuth()
const router = useRouter()
const { success, error: showError } = useToast()

const loading = ref(true)
const users = ref<any[]>([])

// --- Create user ---
const creating = ref(false)
const createMsg = ref('')
const createMsgOk = ref(false)
const newUser = reactive({
  email: '',
  password: '',
  full_name: '',
  organization: '',
  role: 'engineer' as 'engineer' | 'tvgs_truong' | 'admin',
})

async function createUser() {
  creating.value = true
  createMsg.value = ''
  createMsgOk.value = false
  try {
    const tempClient = createClient(
      config.public.supabaseUrl as string,
      config.public.supabaseKey as string,
      { auth: { persistSession: false } }
    )
    const { data, error: signUpErr } = await tempClient.auth.signUp({
      email: newUser.email,
      password: newUser.password,
      options: {
        data: { full_name: newUser.full_name || newUser.email }
      }
    })
    if (signUpErr) throw signUpErr
    if (!data.user) throw new Error('Không tạo được tài khoản')

    await new Promise(r => setTimeout(r, 500))

    const { error: updErr } = await $supabase
      .from('profiles')
      .update({
        full_name: newUser.full_name || newUser.email,
        organization: newUser.organization,
        role: newUser.role,
      })
      .eq('id', data.user.id)
    if (updErr) console.warn('Cập nhật profile:', updErr.message)

    createMsg.value = `Đã tạo tài khoản ${newUser.email}`
    createMsgOk.value = true

    await loadUsers()

    newUser.email = ''
    newUser.password = ''
    newUser.full_name = ''
    newUser.organization = ''
    newUser.role = 'engineer'
  } catch (e: any) {
    const msg = e.message || 'Lỗi tạo tài khoản'
    if (msg.includes('already registered')) {
      createMsg.value = 'Email này đã được đăng ký'
    } else {
      createMsg.value = msg
    }
    createMsgOk.value = false
  } finally {
    creating.value = false
  }
}

// --- User list ---
async function loadUsers() {
  const { data, error: err } = await $supabase
    .from('profiles')
    .select('*')
    .order('created_at', { ascending: true })
  if (err) {
    showError(err.message)
  } else {
    users.value = (data || []).map((u: any) => ({
      ...u,
      saving: false,
      saved: false,
      _resetMode: false,
      _newPw: '',
      _resetting: false,
      _resetMsg: '',
      _resetOk: false,
    }))
  }
}

async function updateUser(u: any) {
  u.saving = true
  u.saved = false
  try {
    const { error: err } = await $supabase
      .from('profiles')
      .update({
        full_name: u.full_name,
        organization: u.organization,
        role: u.role,
      })
      .eq('id', u.id)
    if (err) throw err
    u.saved = true
    setTimeout(() => { u.saved = false }, 2000)
  } catch (e: any) {
    showError(e.message)
  } finally {
    u.saving = false
  }
}

async function doResetPassword(u: any) {
  if (!u._newPw || u._newPw.length < 6) {
    u._resetMsg = 'Tối thiểu 6 ký tự'
    u._resetOk = false
    return
  }
  u._resetting = true
  u._resetMsg = ''
  try {
    await $fetch('/api/reset-password', {
      method: 'POST',
      body: { userId: u.id, newPassword: u._newPw },
    })
    u._resetMsg = 'Đã đổi ✓'
    u._resetOk = true
    u._resetMode = false
    setTimeout(() => { u._resetMsg = '' }, 3000)
  } catch (err: any) {
    u._resetMsg = err.data?.message || err.message || 'Lỗi'
    u._resetOk = false
  } finally {
    u._resetting = false
  }
}

onMounted(async () => {
  if (!isAdmin.value) {
    router.push('/')
    return
  }
  await loadUsers()
  loading.value = false
})
</script>

<style scoped>
.input-field {
  @apply w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-1 focus:ring-primary-500 focus:border-primary-500;
}
.input-inline {
  @apply bg-transparent border-b border-transparent hover:border-gray-300 focus:border-primary-500 focus:outline-none px-1 py-0.5 text-sm w-full;
}
.input-xs {
  @apply px-2 py-1 border border-gray-300 rounded text-sm focus:ring-1 focus:ring-primary-500 focus:border-primary-500;
}
</style>
