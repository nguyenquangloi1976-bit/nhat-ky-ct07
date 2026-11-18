// Tiện ích lý trình: chuyển đổi giữa dạng chữ "Km60+100" và số mét (60100)

/** "Km60+100" | "60+100" | "km 60 + 100,5" | "60100" → số mét; không hợp lệ → null */
export function parseKm(input: string | number | null | undefined): number | null {
  if (input === null || input === undefined) return null
  if (typeof input === 'number') return Number.isFinite(input) ? input : null
  const t = input.toUpperCase().replace(/\s+/g, '').replace(/^KM/, '').replace(',', '.')
  if (!t) return null
  if (t.includes('+')) {
    const [km, m] = t.split('+')
    const a = Number(km)
    const b = Number(m)
    if (km === '' || m === '' || !Number.isFinite(a) || !Number.isFinite(b)) return null
    return a * 1000 + b
  }
  const n = Number(t)
  return Number.isFinite(n) ? n : null
}

/** 60100 → "Km60+100" */
export function formatKm(m: number | null | undefined): string {
  if (m === null || m === undefined || !Number.isFinite(Number(m))) return ''
  const v = Number(m)
  const km = Math.floor(v / 1000)
  const rest = Math.round((v - km * 1000) * 100) / 100
  const whole = Math.floor(rest)
  const frac = rest - whole
  const tail = String(whole).padStart(3, '0') + (frac > 0 ? String(Math.round(frac * 100) / 100).slice(1) : '')
  return `Km${km}+${tail}`
}

/** Tìm khoảng lý trình trong chuỗi mô tả công trình, vd "Km59+000 → Km68+700" */
export function parseKmRange(text: string | null | undefined): { from: number; to: number } | null {
  if (!text) return null
  const found = text.match(/\d+\s*\+\s*\d+(?:[.,]\d+)?/g)
  if (!found || found.length < 2) return null
  const a = parseKm(found[0])
  const b = parseKm(found[1])
  if (a === null || b === null || a === b) return null
  return { from: Math.min(a, b), to: Math.max(a, b) }
}

export function useStation() {
  return { parseKm, formatKm, parseKmRange }
}
