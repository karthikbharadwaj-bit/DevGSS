describe("PDF renderer loading and download", () => {
  let loadScript;
  let renderer;
  let downloadPdf;
  let loadPdfRenderer;
  let renderPdf;
  let failingPaths;

  const paths = () =>
    loadScript.mock.calls.map(([, url]) => url.slice(url.indexOf("/")));

  // Mirrors platformResourceLoader under Lightning Web Security as probed in
  // DevGss: a script that throws while initializing rejects with `undefined`,
  // and any later load of that same URL never settles. Loaded URLs resolve
  // again without re-evaluating.
  const lwsLoadScript = () => {
    const loaded = new Set();
    const failed = new Set();
    return (component, url) => {
      if (loaded.has(url)) return Promise.resolve();
      if (failed.has(url)) return new Promise(() => {});
      if (failingPaths.some((path) => url.endsWith(path))) {
        failed.add(url);
        return Promise.reject(undefined);
      }
      loaded.add(url);
      if (url.includes("/build/pdfmake.min.js")) window.pdfMake = renderer;
      return Promise.resolve();
    };
  };

  beforeEach(() => {
    jest.useFakeTimers();
    jest.clearAllMocks();
    failingPaths = [];
    renderer = {
      createPdf: jest.fn(() => ({
        getBlob: jest.fn((callback) =>
          callback(new Blob(["%PDF-1.3"], { type: "application/pdf" }))
        )
      }))
    };
    URL.createObjectURL = jest.fn(() => "blob:summary-export");
    URL.revokeObjectURL = jest.fn();
    jest.isolateModules(() => {
      loadScript = require("lightning/platformResourceLoader").loadScript;
      loadScript.mockImplementation(lwsLoadScript());
      const module = require("c/lwcPdfRenderer");
      loadPdfRenderer = module.loadPdfRenderer;
      renderPdf = module.renderPdf;
      downloadPdf = module.downloadPdf;
    });
  });

  afterEach(() => {
    jest.runOnlyPendingTimers();
    jest.useRealTimers();
    delete window.pdfMake;
    delete URL.createObjectURL;
    delete URL.revokeObjectURL;
  });

  it("loads the LWS global shim before the engine and fonts once and returns an explicitly typed PDF Blob", async () => {
    const component = {};
    const blob = await renderPdf(component, { content: ["Summary"] });
    await renderPdf(component, { content: ["Second summary"] });
    expect(paths()).toEqual([
      "/lws-global-this.js",
      "/build/pdfmake.min.js",
      "/build/vfs_fonts.js"
    ]);
    expect(loadScript.mock.calls[0][0]).toBe(component);
    expect(blob.type).toBe("application/pdf");
    expect(blob.size).toBeGreaterThan(0);
    expect(renderer.createPdf).toHaveBeenCalledTimes(2);
  });

  it("names the failed stage when LWS rejects without an error and retries from fresh URLs", async () => {
    failingPaths = ["/build/pdfmake.min.js"];
    await expect(renderPdf({}, {})).rejects.toThrow(
      "PDF renderer script failed to load"
    );
    // Reusing the failed URL would never settle under LWS.
    await expect(renderPdf({}, {})).resolves.toBeInstanceOf(Blob);
    expect(paths()).toEqual([
      "/lws-global-this.js",
      "/build/pdfmake.min.js",
      "/lws-global-this.js?attempt=1",
      "/build/pdfmake.min.js?attempt=1",
      "/build/vfs_fonts.js?attempt=1"
    ]);
  });

  it("keeps a real loader error", async () => {
    loadScript.mockRejectedValueOnce(new Error("Network failure"));
    await expect(renderPdf({}, {})).rejects.toThrow("Network failure");
    await expect(renderPdf({}, {})).resolves.toBeInstanceOf(Blob);
  });

  it("times out a load that never settles and retries from fresh URLs", async () => {
    loadScript.mockReturnValueOnce(new Promise(() => {}));
    const firstLoad = loadPdfRenderer({});
    jest.advanceTimersByTime(30000);
    await expect(firstLoad).rejects.toThrow("PDF global shim load timed out");

    await expect(loadPdfRenderer({})).resolves.toBe(renderer);
    expect(paths()[1]).toBe("/lws-global-this.js?attempt=1");
  });

  it("rejects scripts that load without exposing the renderer", async () => {
    loadScript.mockResolvedValue();
    await expect(loadPdfRenderer({})).rejects.toThrow(
      "PDF renderer unavailable"
    );
  });

  it("rejects empty PDFs", async () => {
    renderer.createPdf.mockReturnValue({
      getBlob: (callback) => callback(new Blob([]))
    });
    await expect(renderPdf({}, {})).rejects.toThrow("Empty PDF");
  });

  it("resolves a callback-based renderer without depending on a cross-sandbox promise", async () => {
    renderer.createPdf.mockReturnValue({
      getBlob: (callback) =>
        callback(new Blob(["%PDF-1.3"], { type: "application/pdf" }))
    });
    await expect(renderPdf({}, {})).resolves.toMatchObject({
      type: "application/pdf"
    });
  });

  it("times out when the renderer never calls back", async () => {
    await renderPdf({}, {});
    renderer.createPdf.mockReturnValue({ getBlob: jest.fn() });
    const result = renderPdf({}, {});
    await Promise.resolve();
    jest.advanceTimersByTime(60000);
    await expect(result).rejects.toThrow("PDF renderer timed out");
  });

  it("downloads from a Blob URL and revokes it after the browser consumes it", () => {
    const anchor = document.createElement("a");
    let downloadAttributes;
    jest.spyOn(anchor, "click").mockImplementation(() => {
      downloadAttributes = [anchor.href, anchor.download];
    });
    downloadPdf(anchor, new Blob(["pdf"]), "Summary.pdf");
    expect(downloadAttributes).toEqual(["blob:summary-export", "Summary.pdf"]);
    expect(anchor.hasAttribute("href")).toBe(false);
    expect(URL.revokeObjectURL).not.toHaveBeenCalled();
    jest.advanceTimersByTime(60000);
    expect(URL.revokeObjectURL).toHaveBeenCalledWith("blob:summary-export");
  });

  it("cleans up immediately when starting the download fails", () => {
    const anchor = document.createElement("a");
    jest.spyOn(anchor, "click").mockImplementation(() => {
      throw new Error("Blocked");
    });
    expect(() => downloadPdf(anchor, new Blob(["pdf"]), "Summary.pdf")).toThrow(
      "Blocked"
    );
    expect(URL.revokeObjectURL).toHaveBeenCalledWith("blob:summary-export");
    expect(anchor.hasAttribute("href")).toBe(false);
  });
});
