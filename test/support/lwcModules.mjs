import { registerHooks } from "node:module";

// Resolves LWC "c/name" imports to force-app/main/default/lwc/name/name.js, as Lightning does.
const LWC_ROOT = new URL("../../force-app/main/default/lwc/", import.meta.url);

registerHooks({
  resolve(specifier, context, nextResolve) {
    const match = /^c\/([A-Za-z][\w]*)$/.exec(specifier);
    if (!match) return nextResolve(specifier, context);
    return {
      url: new URL(`${match[1]}/${match[1]}.js`, LWC_ROOT).href,
      format: "module",
      shortCircuit: true
    };
  }
});
