import { createClient } from '@supabase/supabase-js'

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  const body = await readBody(event)
  const { userId, newPassword } = body

  if (!userId || !newPassword) {
    throw createError({ statusCode: 400, message: 'Thiếu userId hoặc newPassword' })
  }
  if (newPassword.length < 6) {
    throw createError({ statusCode: 400, message: 'Mật khẩu tối thiểu 6 ký tự' })
  }

  const serviceRoleKey = config.supabaseServiceRoleKey as string
  if (!serviceRoleKey) {
    throw createError({ statusCode: 500, message: 'Chưa cấu hình SUPABASE_SERVICE_ROLE_KEY' })
  }

  const supabaseAdmin = createClient(
    config.public.supabaseUrl as string,
    serviceRoleKey,
    { auth: { autoRefreshToken: false, persistSession: false } }
  )

  const { error } = await supabaseAdmin.auth.admin.updateUserById(userId, {
    password: newPassword,
  })

  if (error) {
    throw createError({ statusCode: 500, message: `Lỗi đặt lại mật khẩu: ${error.message}` })
  }

  return { ok: true }
})
