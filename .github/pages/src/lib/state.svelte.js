import { serializeToken, normalizeToken } from './utils.js';

/** Internal state for the theme configuration. */
let styles = $state({});
let config = $state({ outputPath: '' });
let enabledCategories = $state(new Set());

/** Whether the JSON editor is currently focused (pauses UI→JSON sync). */
let jsonEditorFocused = $state(false);

/**
 * Derived JSON string from the current state.
 * Only recomputes when styles/config/enabledCategories change.
 */
const jsonOutput = $derived.by(() => {
  const obj = {};

  // Build styles — only include enabled categories
  const stylesObj = {};
  for (const cat of enabledCategories) {
    const tokens = styles[cat] ?? [];
    stylesObj[cat] = tokens.map(serializeToken);
  }
  if (Object.keys(stylesObj).length > 0) {
    obj.styles = stylesObj;
  }

  // Build config — only include if it has properties
  if (Object.keys(config).length > 0) {
    obj.config = { ...config };
  }

  return JSON.stringify(obj, null, 2);
});

/**
 * Get the current JSON output string.
 */
export function getJsonOutput() {
  return jsonOutput;
}

/**
 * Get whether the JSON editor is focused.
 */
export function isJsonEditorFocused() {
  return jsonEditorFocused;
}

/**
 * Set whether the JSON editor is focused.
 */
export function setJsonEditorFocused(focused) {
  jsonEditorFocused = focused;
}

/**
 * Get the current enabled categories set.
 */
export function getEnabledCategories() {
  return enabledCategories;
}

/**
 * Get the tokens for a given category.
 */
export function getTokens(category) {
  return styles[category] ?? [];
}

/**
 * Get a config property value.
 */
export function getConfig(key) {
  return config[key];
}

/**
 * Toggle a style category on or off.
 */
export function toggleCategory(category, enabled) {
  if (enabled) {
    enabledCategories.add(category);
    if (!styles[category]) styles[category] = [];
  } else {
    enabledCategories.delete(category);
  }
  // Force reactivity on the Set by reassigning
  enabledCategories = new Set(enabledCategories);
}

/**
 * Check if a category is enabled.
 */
export function isCategoryEnabled(category) {
  return enabledCategories.has(category);
}

/**
 * Add a token to a category.
 */
export function addToken(category, name) {
  if (!styles[category]) styles[category] = [];
  styles[category] = [...styles[category], { name, style: name }];
}

/**
 * Remove a token from a category by index.
 */
export function removeToken(category, index) {
  styles[category] = styles[category].filter((_, i) => i !== index);
}

/**
 * Update a token property in a category.
 */
export function updateToken(category, index, key, value) {
  styles[category] = styles[category].map((t, i) =>
    i === index ? { ...t, [key]: value } : t
  );
}

/**
 * Set a config property.
 */
export function setConfig(key, value) {
  config = { ...config, [key]: value };
}

/**
 * Update state from a JSON string. Returns an error message if invalid.
 */
export function updateFromJson(jsonString) {
  let parsed;
  try {
    parsed = JSON.parse(jsonString);
  } catch {
    return 'Invalid JSON';
  }

  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    return 'JSON must be an object';
  }

  // Update styles
  const newStyles = {};
  const newEnabled = new Set();

  if (parsed.styles && typeof parsed.styles === 'object') {
    for (const [cat, tokens] of Object.entries(parsed.styles)) {
      if (!Array.isArray(tokens)) continue;
      newStyles[cat] = tokens.map(normalizeToken);
      newEnabled.add(cat);
    }
  }

  styles = newStyles;
  enabledCategories = newEnabled;

  // Update config
  if (parsed.config && typeof parsed.config === 'object') {
    config = { ...parsed.config };
  } else {
    config = {};
  }

  return null;
}
