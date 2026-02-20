<script>
  import CategorySection from './CategorySection.svelte';

  let { categories = [], tokenProperties = [] } = $props();
</script>

<section class="styles-section">
  <h2>Styles</h2>
  {#each categories as category (category.key)}
    <CategorySection {category} {tokenProperties} />
  {/each}
</section>
