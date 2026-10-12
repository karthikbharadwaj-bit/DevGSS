const fs = require("fs");
const path = require("path");

// Use the deployable defaults so regressions in label metadata are visible to tests.
// Shared Summary* labels live in their own file and are read alongside the feature's.
function readLabels(fileName, description) {
  const xml = fs.readFileSync(
    path.resolve(__dirname, `../../force-app/main/default/labels/${fileName}`),
    "utf8"
  );
  const document = new global.DOMParser().parseFromString(
    xml,
    "application/xml"
  );
  if (document.querySelector("parsererror")) {
    throw new Error(`Invalid ${description} label metadata`);
  }
  return Object.fromEntries(
    [...document.getElementsByTagName("labels")].map((entry) => [
      entry.getElementsByTagName("fullName")[0].textContent,
      entry.getElementsByTagName("value")[0].textContent
    ])
  );
}
const defaults = {
  ...readLabels("AccountSummary.labels-meta.xml", "Account Summary"),
  ...readLabels("Summary.labels-meta.xml", "shared Summary")
};
const values = { ...defaults };

Object.keys(defaults).forEach((name) => {
  jest.doMock(
    `@salesforce/label/c.${name}`,
    () => ({
      __esModule: true,
      get default() {
        return values[name];
      }
    }),
    { virtual: true }
  );
});

export function setLabel(suffix, value) {
  const featureName = `AccountSummary${suffix}`;
  values[featureName in defaults ? featureName : `Summary${suffix}`] = value;
}

export function resetLabels() {
  Object.assign(values, defaults);
}
