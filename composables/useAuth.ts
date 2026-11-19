import type { User } from '@supabase/supabase-js'

interface Profile {
  id: string
  full_name: string | null
  role: 'admin' | 'engineer'
}

const user = ref<User | null>(null)
const profile = ref<Profile | null>(null)
const loading = ref(true)

export function useAuth() {
  const { $supabase } = useNuxtApp()

  async function init() {
    loading.value = true
    const { data: { session } } = await $supabase.auth.getSession()
    if (session?.user) {
      user.value = session.user
      await fetchProfile(session.user.id)
    }
    loading.value = false

    // Listen for auth changes
    $supabase.auth.onAuthStateChange(async (event: string, session: any) => {
      user.value = session?.user ?? null
      if (session?.user) {
        await fetchProfile(session.user.id)
      } else {
        profile.value = null
      }
    })
  }

  async function fetchProfile(userId: string) {
    const { data } = await $supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single()
    profile.value = data
  }

  async function signIn(email: string, password: string) {
    const { error } = await $supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }

  async function signOut() {
    await $supabase.auth.signOut()
    user.value = null
    profile.value = null
  }

  async function changePassword(newPassword: string) {
    const { error } = await $supabase.auth.updateUser({ password: newPassword })
    if (error) throw error
  }

  return {
    user: readonly(user),
    profile: readonly(profile),
    loading: readonly(loading),
    isAdmin: computed(() => profile.value?.role === 'admin'),
    init,
    signIn,
    signOut,
    changePassword,
  }
}
