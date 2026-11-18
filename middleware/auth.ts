export default defineNuxtRouteMiddleware((to) => {
  // Skip auth check for login page
  if (to.path === '/login') return

  // Only check auth on client side
  if (import.meta.server) return

  const { $supabase } = useNuxtApp()
  if (!$supabase) return navigateTo('/login')

  const checkAuth = async () => {
    const { data: { session } } = await $supabase.auth.getSession()
    if (!session) {
      return navigateTo('/login')
    }
  }

  return checkAuth()
})
