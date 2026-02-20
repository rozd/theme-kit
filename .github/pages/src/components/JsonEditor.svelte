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
</script>

<section class="json-editor">
  <h2>JSON Output</h2>
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
