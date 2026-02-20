<script>
  import { untrack } from 'svelte';
  import { SWIFTUI_BUILTIN_STYLES } from '../lib/validation.js';

  let { token, tokenProperties = [], onupdate, onclose } = $props();

  // Local input values — initialized from token, never overwritten by re-renders
  let values = $state(
    untrack(() =>
      Object.fromEntries(
        tokenProperties.map((p) => [
          p.key,
          token[p.key] === token.name ? '' : (token[p.key] ?? ''),
        ])
      )
    )
  );

  function handleInput(key, raw) {
    values[key] = raw;
    onupdate(key, raw || token.name);
  }

  let showWarning = $derived(
    SWIFTUI_BUILTIN_STYLES.has(values.style || token.name) && !values.style
  );

  function handleKeydown(e) {
    if (e.key === 'Escape') onclose();
  }
</script>

<!-- svelte-ignore a11y_no_static_element_interactions -->
<div class="token-popover" onkeydown={handleKeydown}>
  <div class="popover-header">
    <span class="popover-title">{token.name}</span>
    <button class="popover-close" onclick={onclose} aria-label="Close">&times;</button>
  </div>
  {#if showWarning}
    <div class="popover-warning">
      Shadows SwiftUI's built-in <code>.{token.name}</code> — set a custom style name below.
    </div>
  {/if}
  {#each tokenProperties as prop}
    <div class="popover-field">
      <label for="token-prop-{prop.key}">{prop.key}</label>
      <input
        id="token-prop-{prop.key}"
        type="text"
        value={values[prop.key]}
        placeholder="same as name"
        oninput={(e) => handleInput(prop.key, e.target.value)}
      />
    </div>
  {/each}
</div>
