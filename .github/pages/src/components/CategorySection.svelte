<script>
  import TokenField from './TokenField.svelte';
  import { toggleCategory, isCategoryEnabled } from '../lib/state.svelte.js';
  import { camelToWords } from '../lib/utils.js';

  let { category, tokenProperties = [] } = $props();

  const enabled = $derived(isCategoryEnabled(category.key));
  const title = $derived(camelToWords(category.key));
</script>

<div class="category-section" class:disabled={!enabled}>
  <div class="category-header">
    <h3>{title}</h3>
    <label class="toggle">
      <input
        type="checkbox"
        checked={enabled}
        onchange={(e) => toggleCategory(category.key, e.target.checked)}
      />
      <span class="toggle-slider"></span>
    </label>
  </div>
  {#if enabled}
    <TokenField category={category.key} {tokenProperties} />
  {/if}
</div>
