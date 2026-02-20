<script>
  import TokenPopover from './TokenPopover.svelte';

  let { token, tokenProperties = [], onremove, onupdate } = $props();

  let showPopover = $state(false);

  function togglePopover() {
    showPopover = !showPopover;
  }

  function handleUpdate(key, value) {
    onupdate(key, value);
  }

  let hasOverride = $derived(token.name !== token.style);
</script>

<span class="token-tag" class:has-override={hasOverride}>
  <span class="tag-name">{token.name}</span>
  <button class="tag-btn info-btn" onclick={togglePopover} aria-label="Edit token properties">
    <svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
      <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 2.5a1 1 0 110 2 1 1 0 010-2zM6.5 7h2l.5 0v5h-1V8h-1.5V7z"/>
    </svg>
  </button>
  <button class="tag-btn remove-btn" onclick={onremove} aria-label="Remove token">
    <svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor">
      <path d="M4.646 4.646a.5.5 0 01.708 0L8 7.293l2.646-2.647a.5.5 0 01.708.708L8.707 8l2.647 2.646a.5.5 0 01-.708.708L8 8.707l-2.646 2.647a.5.5 0 01-.708-.708L7.293 8 4.646 5.354a.5.5 0 010-.708z"/>
    </svg>
  </button>
  {#if showPopover}
    <TokenPopover
      {token}
      {tokenProperties}
      onupdate={handleUpdate}
      onclose={() => showPopover = false}
    />
  {/if}
</span>
