# L. Local AI (optional experiment)

**Advanced / Later, not infrastructure.** Labels as in the [README](README.md); resource theory is in [`../03-hardware-capacity.md`](../03-hardware-capacity.md) section 7.

## Ollama (short profile)

| | |
|---|---|
| Purpose | Run open language models locally with a simple API and CLI |
| Facts **[V]** | Binds to `127.0.0.1:11434` by default (change with `OLLAMA_HOST`); the default context window is 4096 tokens; models stay loaded in memory for 5 minutes by default; `ollama ps` shows whether a model sits fully on CPU, fully on GPU, or split |
| Resources | The model must fit in memory: roughly 4-5 GB for a 7B-class model at 4-bit, 8-9 GB for 13B, 40 GB or more for 70B **[E]**. Longer context adds memory. CPU-only is limited by memory bandwidth and typically slow; a GPU whose VRAM holds the whole model is dramatically faster **[K]** |
| Storage | 2-40+ GB per model on SSD |
| Concurrency | Parallel requests multiply memory use and slow everyone **[K]** |
| Exposure | Class 4. It has no built-in authentication layer **[K]**: if other devices need it, put an authenticated proxy in front on the tailnet; never publish it. The FAQ shows proxy and tunnel recipes; applying them without authentication would expose your compute |
| Privacy note | Local inference keeps prompts on your hardware; separately, the project documents settings to disable its cloud features **[V]** |
| Backup | Models are re-downloadable; back up only your configuration and any custom prompts |
| Cost | Free software; the cost is hardware and electricity |

## Alternatives

llama.cpp-style servers, vLLM (GPU, server-class), LocalAI, desktop apps such as LM Studio, and web front ends such as Open WebUI **[K]**; verify maintenance and licence before adopting.

## Local vs an external API

| Prefer an external API when | Prefer local when |
|-----------------------------|-------------------|
| You need top quality, large context, or many users | Privacy requires prompts to stay home |
| Use is occasional (cheaper than hardware + power) | You want offline use or to learn |
| You have no GPU | Use is constant and light, on small models |

## Verdict

Not now. Run experiments on a spare desktop or laptop with a GPU, not on the always-on server. Revisit at Stage 6 with measured demand.
