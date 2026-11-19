export default defineEventHandler(async (event) => {
  const formData = await readMultipartFormData(event)
  if (!formData) {
    throw createError({ statusCode: 400, message: 'Không có dữ liệu' })
  }

  const chunkField = formData.find((f) => f.name === 'chunk')
  const sessionUrlField = formData.find((f) => f.name === 'sessionUrl')
  const startField = formData.find((f) => f.name === 'start')
  const endField = formData.find((f) => f.name === 'end')
  const totalField = formData.find((f) => f.name === 'total')

  if (!chunkField?.data || !sessionUrlField?.data) {
    throw createError({ statusCode: 400, message: 'Thiếu chunk hoặc sessionUrl' })
  }

  const sessionUrl = sessionUrlField.data.toString()
  const start = Number(startField?.data.toString() || '0')
  const end = Number(endField?.data.toString() || '0')
  const total = Number(totalField?.data.toString() || '0')

  const resp = await fetch(sessionUrl, {
    method: 'PUT',
    headers: {
      'Content-Length': String(chunkField.data.length),
      'Content-Range': `bytes ${start}-${end}/${total}`,
    },
    body: chunkField.data,
  })

  // Google trả 308 nếu chưa xong, 200 nếu xong
  if (resp.status === 308) {
    return { done: false }
  }

  if (resp.ok) {
    const data = (await resp.json()) as { id?: string }
    return {
      done: true,
      url: `https://drive.google.com/file/d/${data.id}/view`,
    }
  }

  const errText = await resp.text()
  throw createError({ statusCode: 500, message: `Upload chunk lỗi (${resp.status}): ${errText}` })
})
