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

  let theme = $state(
    typeof localStorage !== 'undefined'
      ? localStorage.getItem('theme') || 'system'
      : 'system',
  );

  function setTheme(value) {
    theme = value;
    if (value === 'system') {
      delete document.documentElement.dataset.theme;
      localStorage.removeItem('theme');
    } else {
      document.documentElement.dataset.theme = value;
      localStorage.setItem('theme', value);
    }
  }
</script>

<main class="app">
  <header class="app-header">
    <div style="display: flex; align-items: center; justify-content: space-between;">
      <h1>ThemeKit Configurator</h1>
      <div class="theme-toggle">
        <button class:active={theme === 'system'} onclick={() => setTheme('system')} title="Use system theme">
          <svg viewBox="0 0 16 16"><path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1ZM2 8a6 6 0 1 1 12 0A6 6 0 0 1 2 8Zm6-4.5v9a4.5 4.5 0 0 0 0-9Z"/></svg>
          Auto
        </button>
        <button class:active={theme === 'light'} onclick={() => setTheme('light')} title="Light theme">
          <svg viewBox="0 0 16 16"><path d="M8 1a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-1 0v-1A.5.5 0 0 1 8 1Zm0 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm0-1a3 3 0 1 1 0-6 3 3 0 0 1 0 6Zm5.657-8.157a.5.5 0 0 1 0 .707l-.707.707a.5.5 0 1 1-.707-.707l.707-.707a.5.5 0 0 1 .707 0ZM3.757 11.243a.5.5 0 0 1 0 .707l-.707.707a.5.5 0 1 1-.707-.707l.707-.707a.5.5 0 0 1 .707 0ZM15 8a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1 0-1h1A.5.5 0 0 1 15 8ZM3.5 8a.5.5 0 0 1-.5.5H2a.5.5 0 0 1 0-1h1a.5.5 0 0 1 .5.5Zm9.193 4.243a.5.5 0 0 1-.707 0l-.707-.707a.5.5 0 0 1 .707-.707l.707.707a.5.5 0 0 1 0 .707ZM4.464 4.465a.5.5 0 0 1-.707 0l-.707-.708a.5.5 0 1 1 .707-.707l.707.707a.5.5 0 0 1 0 .708ZM8 14a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-1 0v-1A.5.5 0 0 1 8 14Z"/></svg>
        </button>
        <button class:active={theme === 'dark'} onclick={() => setTheme('dark')} title="Dark theme">
          <svg viewBox="0 0 16 16"><path d="M6.2 1a.5.5 0 0 0-.48.636 5.5 5.5 0 0 1-4.684 6.93.5.5 0 0 0-.118.958A7 7 0 1 0 6.68.536.5.5 0 0 0 6.2 1ZM7 13a5.998 5.998 0 0 1-4.672-2.24 6.5 6.5 0 0 0 4.89-7.58A6 6 0 0 1 7 13Z"/></svg>
        </button>
      </div>
    </div>
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
