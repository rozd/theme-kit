<script>
  import { getJsonOutput, isJsonEditorFocused, setJsonEditorFocused, updateFromJson } from '../lib/state.svelte.js';

  let localValue = $state('');
  let error = $state(null);
  let focused = $state(false);

  // Sync from state → local when not focused
  $effect(() => {
    const output = getJsonOutput();
    if (!focused) {
      localValue = output;
      error = null;
    }
  });

  function handleFocus() {
    focused = true;
    setJsonEditorFocused(true);
  }

  function handleBlur() {
    focused = false;
    setJsonEditorFocused(false);
    const err = updateFromJson(localValue);
    error = err;
    if (!err) {
      // Sync back the formatted version
      localValue = getJsonOutput();
    }
  }

  function handleInput(e) {
    localValue = e.target.value;
    // Live validation
    try {
      JSON.parse(localValue);
      error = null;
    } catch {
      error = 'Invalid JSON';
    }
  }

  function download() {
    const blob = new Blob([localValue], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'theme.json';
    a.click();
    URL.revokeObjectURL(url);
  }
</script>

<section class="json-editor">
  <div class="section-header">
    <h2>JSON Output</h2>
    <button class="download-btn" onclick={download} title="Download theme.json">
      <svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
        <path d="M8 1a.5.5 0 0 1 .5.5v8.793l2.146-2.147a.5.5 0 0 1 .708.708l-3 3a.5.5 0 0 1-.708 0l-3-3a.5.5 0 1 1 .708-.708L7.5 10.293V1.5A.5.5 0 0 1 8 1ZM2 13.5a.5.5 0 0 1 .5-.5h11a.5.5 0 0 1 0 1h-11a.5.5 0 0 1-.5-.5Z"/>
      </svg>
      Download
    </button>
  </div>
  <textarea
    class="json-textarea"
    class:json-error={error}
    value={localValue}
    oninput={handleInput}
    onfocus={handleFocus}
    onblur={handleBlur}
    spellcheck="false"
  ></textarea>
  {#if error}
    <p class="error-text">{error}</p>
  {/if}
</section>
