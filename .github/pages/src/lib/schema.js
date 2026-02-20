const SCHEMA_URL =
  'https://raw.githubusercontent.com/rozd/theme-kit/main/theme.schema.json';

/**
 * Fetch and parse theme.schema.json into a UI-friendly structure.
 *
 * Returns:
 *   configProperties — array of { key, type, description, required }
 *   styleCategories  — array of { key, description }
 *   tokenProperties  — array of { key, type, description } (from tokenEntry object, excluding "name")
 */
export async function loadSchema() {
  const res = await fetch(SCHEMA_URL);
  if (!res.ok) throw new Error(`Failed to fetch schema: ${res.status}`);
  const schema = await res.json();

  const configProperties = parseConfigProperties(schema);
  const styleCategories = parseStyleCategories(schema);
  const tokenProperties = parseTokenProperties(schema);

  return { configProperties, styleCategories, tokenProperties };
}

function parseConfigProperties(schema) {
  const configSchema = schema.properties?.config;
  if (!configSchema?.properties) return [];
  const required = new Set(configSchema.required ?? []);
  return Object.entries(configSchema.properties).map(([key, def]) => ({
    key,
    type: def.type ?? 'string',
    description: def.description ?? '',
    required: required.has(key),
  }));
}

function parseStyleCategories(schema) {
  const stylesSchema = schema.properties?.styles;
  if (!stylesSchema?.properties) return [];
  return Object.entries(stylesSchema.properties).map(([key, def]) => ({
    key,
    description: def.description ?? '',
  }));
}

function parseTokenProperties(schema) {
  const tokenDef = schema.$defs?.tokenEntry;
  if (!tokenDef?.oneOf) return [];
  const objectVariant = tokenDef.oneOf.find((v) => v.type === 'object');
  if (!objectVariant?.properties) return [];
  return Object.entries(objectVariant.properties)
    .filter(([key]) => key !== 'name')
    .map(([key, def]) => ({
      key,
      type: def.type ?? 'string',
      description: def.description ?? '',
    }));
}
