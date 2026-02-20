/**
 * Convert a camelCase key to title-cased words.
 * "meshGradients" → "Mesh Gradients"
 */
export function camelToWords(str) {
  return str
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/^./, (c) => c.toUpperCase());
}

/**
 * Serialize a token for JSON output.
 * If name === style, use the compact string form; otherwise use the object form.
 */
export function serializeToken(token) {
  return token.name === token.style ? token.name : { name: token.name, style: token.style };
}

/**
 * Normalize a raw token value (from JSON) into the internal { name, style } form.
 */
export function normalizeToken(raw) {
  if (typeof raw === 'string') return { name: raw, style: raw };
  return { name: raw.name, style: raw.style ?? raw.name };
}
