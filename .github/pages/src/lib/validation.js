/** SwiftUI built-in ShapeStyle static properties that will conflict with generated extensions. */
export const SWIFTUI_BUILTIN_STYLES = new Set([
  'primary',
  'secondary',
  'tertiary',
  'quaternary',
  'background',
  'foreground',
  'selection',
  'separator',
  'tint',
  'placeholder',
  'fill',
  'link',
  'ultraThinMaterial',
  'thinMaterial',
  'regularMaterial',
  'thickMaterial',
  'ultraThickMaterial',
  'bar',
  'windowBackground',
]);

/** Returns true when a token's effective style name shadows a SwiftUI built-in. */
export function hasBuiltinConflict(token) {
  return token.name === token.style && SWIFTUI_BUILTIN_STYLES.has(token.style);
}
