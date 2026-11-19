// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: false },

  // Chạy hoàn toàn trên trình duyệt (dữ liệu lấy từ Supabase) để đưa lên hosting tĩnh
  ssr: false,

  modules: [
    '@nuxtjs/tailwindcss',
    '@pinia/nuxt',
  ],

  runtimeConfig: {
    // Server-side only (không lộ ra client)
    googleServiceAccountEmail: process.env.NUXT_GOOGLE_SERVICE_ACCOUNT_EMAIL || '',
    googlePrivateKey: process.env.NUXT_GOOGLE_PRIVATE_KEY || '',
    googleDriveFolderId: process.env.NUXT_GOOGLE_DRIVE_FOLDER_ID || '',
    supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
    public: {
      supabaseUrl: process.env.SUPABASE_URL || '',
      supabaseKey: process.env.SUPABASE_KEY || '',
    },
  },

  app: {
    head: {
      title: 'Nhật ký thi công CT.07',
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: 'Nhật ký thi công – Gói thầu TV-08 – CT.07 Hà Nội – Thái Nguyên' },
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
      ],
    },
  },
})
