import { loadScript } from "lightning/platformResourceLoader";
import pdfResource from "@salesforce/resourceUrl/PdfRenderer";

let rendererPromise;
let failedAttempts = 0;
const PDF_RESOURCE_LOAD_TIMEOUT_MS = 30000;
const PDF_RENDER_TIMEOUT_MS = 60000;
// Lightning Web Security evaluates these scripts without a usable globalThis,
// which pdfmake needs while initializing, so the shim must load first.
const PDF_SCRIPTS = [
  ["/lws-global-this.js", "PDF global shim"],
  ["/build/pdfmake.min.js", "PDF renderer script"],
  ["/build/vfs_fonts.js", "PDF font script"]
];

function runWithTimeout(task, message, timeoutMs) {
  return new Promise((resolve, reject) => {
    let settled = false;
    let timeoutId;
    const finish = (callback, value) => {
      if (settled) return;
      settled = true;
      clearTimeout(timeoutId);
      callback(value);
    };
    // Under LWS, loadScript never settles for a missing file or for a URL that
    // already failed. Bound that wait so a later click can retry.
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    timeoutId = setTimeout(() => finish(reject, new Error(message)), timeoutMs);
    try {
      Promise.resolve(task()).then(
        (value) => finish(resolve, value),
        (error) => finish(reject, error)
      );
    } catch (error) {
      finish(reject, error);
    }
  });
}

function loadPdfScript(component, path, stage) {
  // A failed URL stays pending forever under LWS, so retries use a fresh URL.
  const query = failedAttempts ? `?attempt=${failedAttempts}` : "";
  return runWithTimeout(
    () =>
      loadScript(component, `${pdfResource}${path}${query}`).catch((error) => {
        // LWS rejects without a reason when a script throws while loading.
        throw error instanceof Error
          ? error
          : new Error(`${stage} failed to load`);
      }),
    `${stage} load timed out`,
    PDF_RESOURCE_LOAD_TIMEOUT_MS
  );
}

async function loadPdfScripts(component) {
  for (const [path, stage] of PDF_SCRIPTS) {
    // Each script depends on the previous one, so load them in order.
    // eslint-disable-next-line no-await-in-loop
    await loadPdfScript(component, path, stage);
  }
}

function getPdfBlob(renderer, definition) {
  return new Promise((resolve, reject) => {
    let settled = false;
    let timeoutId;
    const finish = (callback, value) => {
      if (settled) return;
      settled = true;
      clearTimeout(timeoutId);
      callback(value);
    };
    // A renderer failure must return control to the component instead of
    // leaving the Download PDF button busy forever.
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    timeoutId = setTimeout(
      () => finish(reject, new Error("PDF renderer timed out")),
      PDF_RENDER_TIMEOUT_MS
    );
    try {
      // pdfmake 0.2 uses a callback here. Avoiding its 0.3 promise API also
      // avoids passing an internal renderer promise across the LWS membrane.
      renderer.createPdf(definition).getBlob((blob) => finish(resolve, blob));
    } catch (error) {
      finish(reject, error);
    }
  });
}

// One reusable load per Lightning sandbox, started by the first download; a
// failed load is retryable.
export function loadPdfRenderer(component) {
  if (!rendererPromise) {
    rendererPromise = loadPdfScripts(component)
      .then(() => {
        const renderer = window.pdfMake;
        if (typeof renderer?.createPdf !== "function")
          throw new Error("PDF renderer unavailable");
        return renderer;
      })
      .catch((error) => {
        failedAttempts += 1;
        rendererPromise = undefined;
        throw error;
      });
  }
  return rendererPromise;
}

export async function renderPdf(component, definition) {
  const renderer = await loadPdfRenderer(component);
  const blob = await getPdfBlob(renderer, definition);
  if (!blob?.size) throw new Error("Empty PDF");
  return new Blob([blob], { type: "application/pdf" });
}

export function downloadPdf(anchor, blob, filename) {
  const url = URL.createObjectURL(blob);
  try {
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
  } catch (error) {
    URL.revokeObjectURL(url);
    throw error;
  } finally {
    anchor.removeAttribute("href");
    anchor.removeAttribute("download");
  }
  // Give the browser time to consume the URL; revoke even if the LWC unmounts.
  // eslint-disable-next-line @lwc/lwc/no-async-operation
  setTimeout(() => URL.revokeObjectURL(url), 60000);
}
