/*
 * Project code, not part of pdfmake. Lightning Web Security evaluates
 * loadScript code without a usable globalThis (typeof globalThis is
 * "undefined" and Function("return this")() is undefined), so pdfmake's
 * bundled global lookup fails during initialization. Load this first to expose
 * the namespace's sandboxed window. Safe to evaluate more than once.
 */
(function () {
  if (typeof globalThis === "object" && globalThis) return;
  if (typeof self === "object" && self) self.globalThis = self;
})();
