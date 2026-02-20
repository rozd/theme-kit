<script>
  import { loadSchema } from './lib/schema.js';
  import ConfigSection from './components/ConfigSection.svelte';
  import StylesSection from './components/StylesSection.svelte';
  import JsonEditor from './components/JsonEditor.svelte';

  let schema = $state(null);
  let loadError = $state(null);

  $effect(() => {
    loadSchema()
      .then((s) => (schema = s))
      .catch((e) => (loadError = e.message));
  });
</script>

<main class="app">
  <header class="app-header">
    <h1>ThemeKit Configurator</h1>
    <p class="subtitle">Build your <code>theme.json</code> configuration visually</p>
  </header>

  {#if loadError}
    <div class="error-banner">
      <p>Failed to load schema: {loadError}</p>
      <p>Make sure you have internet access and the schema is available.</p>
    </div>
  {:else if !schema}
    <div class="loading">Loading schema...</div>
  {:else}
    <div class="app-layout">
      <div class="editor-panel">
        <ConfigSection properties={schema.configProperties} />
        <StylesSection categories={schema.styleCategories} tokenProperties={schema.tokenProperties} />
      </div>
      <div class="json-panel">
        <JsonEditor />
      </div>
    </div>
  {/if}
</main>
