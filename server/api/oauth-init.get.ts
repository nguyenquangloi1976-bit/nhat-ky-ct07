export default defineEventHandler((event) => {
  const config = useRuntimeConfig()
  const clientId = config.googleOauthClientId as string

  if (!clientId) {
    throw createError({ statusCode: 500, statusMessage: 'Thiếu GOOGLE_OAUTH_CLIENT_ID' })
  }

  const redirectUri = `${getRequestURL(event).origin}/api/oauth-callback`

  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: 'code',
    scope: 'https://www.googleapis.com/auth/drive.file',
    access_type: 'offline',
    prompt: 'consent',
  })

  return sendRedirect(event, `https://accounts.google.com/o/oauth2/v2/auth?${params}`)
})
