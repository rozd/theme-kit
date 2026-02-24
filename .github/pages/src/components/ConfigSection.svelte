<script>
  import { getConfig, setConfig } from '../lib/state.svelte.js';

  let { properties = [] } = $props();
</script>

{#if properties.length > 0}
  <section class="config-section">
    <h2>Configuration</h2>
    <div class="config-fields">
      {#each properties as prop}
        {#if prop.type === 'boolean'}
          <div class="config-field config-field-bool">
            <div>
              <label for="config-{prop.key}">{prop.key}</label>
              {#if prop.description}
                <p class="config-field-desc">{prop.description}</p>
              {/if}
            </div>
            <label class="toggle">
              <input
                id="config-{prop.key}"
                type="checkbox"
                checked={getConfig(prop.key) ?? false}
                onchange={(e) => setConfig(prop.key, e.target.checked)}
              />
              <span class="toggle-slider"></span>
            </label>
          </div>
        {:else}
        <div class="config-field">
          <label for="config-{prop.key}">
            {prop.key}
            {#if prop.required}<span class="required">*</span>{/if}
          </label>
          {#if prop.type === 'number'}
            <input
              id="config-{prop.key}"
              type="number"
              value={getConfig(prop.key) ?? ''}
              oninput={(e) => setConfig(prop.key, e.target.value ? Number(e.target.value) : '')}
              placeholder={prop.description}
            />
          {:else}
            <input
              id="config-{prop.key}"
              type="text"
              value={getConfig(prop.key) ?? ''}
              oninput={(e) => setConfig(prop.key, e.target.value)}
              placeholder={prop.description}
            />
          {/if}
        </div>
        {/if}
      {/each}
    </div>
  </section>
{/if}
