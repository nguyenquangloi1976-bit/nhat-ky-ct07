export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const code = query.code as string
  const error = query.error as string

  if (error) {
    return `<h2>Lỗi: ${error}</h2>`
  }
  if (!code) {
    return '<h2>Không nhận được authorization code</h2>'
  }

  const config = useRuntimeConfig()
  const clientId = config.googleOauthClientId as string
  const clientSecret = config.googleOauthClientSecret as string
  const redirectUri = `${getRequestURL(event).origin}/api/oauth-callback`

  // Đổi code lấy token
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
      grant_type: 'authorization_code',
    }),
  })

  const data = await res.json()

  if (!res.ok) {
    return `<h2>Lỗi lấy token</h2><pre>${JSON.stringify(data, null, 2)}</pre>`
  }

  // Hiện refresh token để user copy vào Vercel env
  return `
    <html><body style="font-family:sans-serif;max-width:600px;margin:40px auto;padding:20px">
      <h2 style="color:green">✅ Xác thực thành công!</h2>
      <p><strong>Refresh Token</strong> (copy giá trị này vào Vercel Environment Variables với tên <code>GOOGLE_OAUTH_REFRESH_TOKEN</code>):</p>
      <textarea readonly style="width:100%;height:120px;font-size:12px;padding:8px">${data.refresh_token || '(Không có refresh_token — thử lại với prompt=consent)'}</textarea>
      <p style="color:#666;font-size:14px">Sau khi lưu env var trên Vercel, redeploy lại project. Trang này có thể đóng.</p>
    </body></html>
  `
})
