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

/**
 * Check if a token has a duplicate style name across all enabled categories.
 * Returns the conflicting category name if found, null otherwise.
 * @param {string} currentCategory - The category of the current token
 * @param {object} token - The token to check (must have name and style properties)
 * @param {object} allStyles - Object with category keys and token array values
 * @param {Set} enabledCategories - Set of enabled category names
 * @returns {string|null} - The conflicting category name or null
 */
export function findDuplicateStyleName(currentCategory, token, allStyles, enabledCategories) {
  const effectiveStyle = token.style ?? token.name;

  for (const cat of enabledCategories) {
    const tokens = allStyles[cat] ?? [];

    for (const otherToken of tokens) {
      const otherEffectiveStyle = otherToken.style ?? otherToken.name;

      // Skip if it's the same token (same category and same name)
      if (cat === currentCategory && otherToken.name === token.name) {
        continue;
      }

      // Found a duplicate
      if (effectiveStyle === otherEffectiveStyle) {
        return cat;
      }
    }
  }

  return null;
}
