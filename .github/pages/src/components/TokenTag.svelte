<script>
  import TokenPopover from './TokenPopover.svelte';
  import { hasBuiltinConflict, findDuplicateStyleName } from '../lib/validation.js';
  import { getAllStyles, getEnabledCategories } from '../lib/state.svelte.js';

  let { token, tokenProperties = [], category, onremove, onupdate } = $props();

  let showPopover = $state(false);

  function togglePopover() {
    showPopover = !showPopover;
  }

  function handleUpdate(key, value) {
    onupdate(key, value);
  }

  let hasOverride = $derived(token.name !== token.style);
  let hasConflict = $derived(hasBuiltinConflict(token));
  let duplicateCategory = $derived(findDuplicateStyleName(category, token, getAllStyles(), getEnabledCategories()));
  let hasDuplicate = $derived(duplicateCategory !== null);
</script>

<span class="token-tag" class:has-override={hasOverride} class:has-conflict={hasConflict || hasDuplicate}>
  <span class="tag-name">{token.name}</span>
  {#if hasConflict}
    <span class="tag-warning" title="Shadows SwiftUI's built-in .{token.name} — open to set a custom style name">
      <svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
        <path d="M8.982 1.566a1.13 1.13 0 00-1.96 0L.165 13.233c-.457.778.091 1.767.98 1.767h13.713c.889 0 1.438-.99.98-1.767L8.982 1.566zM8 5c.535 0 .954.462.9.995l-.35 3.507a.552.552 0 01-1.1 0L7.1 5.995A.905.905 0 018 5zm.002 6a1 1 0 110 2 1 1 0 010-2z"/>
      </svg>
    </span>
  {:else if hasDuplicate}
    <span class="tag-warning" title="Style name &quot;{token.style ?? token.name}&quot; conflicts with a token in {duplicateCategory} — open to set a different style name">
      <svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
        <path d="M8.982 1.566a1.13 1.13 0 00-1.96 0L.165 13.233c-.457.778.091 1.767.98 1.767h13.713c.889 0 1.438-.99.98-1.767L8.982 1.566zM8 5c.535 0 .954.462.9.995l-.35 3.507a.552.552 0 01-1.1 0L7.1 5.995A.905.905 0 018 5zm.002 6a1 1 0 110 2 1 1 0 010-2z"/>
      </svg>
    </span>
  {/if}
  <button class="tag-btn info-btn" onclick={togglePopover} aria-label="Edit token properties">
    <svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
      <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 2.5a1 1 0 110 2 1 1 0 010-2zM6.5 7h2l.5 0v5h-1V8h-1.5V7z"/>
    </svg>
  </button>
  <button class="tag-btn remove-btn" onclick={onremove} aria-label="Remove token">
    <svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
      <path d="M4.646 4.646a.5.5 0 01.708 0L8 7.293l2.646-2.647a.5.5 0 01.708.708L8.707 8l2.647 2.646a.5.5 0 01-.708.708L8 8.707l-2.646 2.647a.5.5 0 01-.708-.708L7.293 8 4.646 5.354a.5.5 0 010-.708z"/>
    </svg>
  </button>
  {#if showPopover}
    <TokenPopover
      {token}
      {tokenProperties}
      {duplicateCategory}
      onupdate={handleUpdate}
      onclose={() => showPopover = false}
    />
  {/if}
</span>
