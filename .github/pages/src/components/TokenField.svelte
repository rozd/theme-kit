<script>
  import TokenTag from './TokenTag.svelte';
  import { addToken, removeToken, updateToken, getTokens } from '../lib/state.svelte.js';

  let { category, tokenProperties = [] } = $props();

  let newTokenName = $state('');

  function handleAdd() {
    const name = newTokenName.trim();
    if (!name) return;
    addToken(category, name);
    newTokenName = '';
  }

  function handleKeydown(e) {
    if (e.key === 'Enter') handleAdd();
  }

  const tokens = $derived(getTokens(category));
</script>

<div class="token-field">
  <div class="token-list">
    {#each tokens as token, index (token.name + index)}
      <TokenTag
        {token}
        {tokenProperties}
        {category}
        onremove={() => removeToken(category, index)}
        onupdate={(key, value) => updateToken(category, index, key, value)}
      />
    {/each}
    <div class="token-add">
      <input
        type="text"
        bind:value={newTokenName}
        onkeydown={handleKeydown}
        placeholder="Add token..."
        class="token-input"
      />
      <button class="token-add-btn" onclick={handleAdd} disabled={!newTokenName.trim()}>+</button>
    </div>
  </div>
</div>
