const fs = require("fs");
const path = require("path");

// Use the deployable defaults so regressions in label metadata are visible to tests.
const xml = fs.readFileSync(
  path.resolve(
    __dirname,
    "../../force-app/main/default/labels/AccountSummary.labels-meta.xml"
  ),
  "utf8"
);
const document = new global.DOMParser().parseFromString(xml, "application/xml");
if (document.querySelector("parsererror")) {
  throw new Error("Invalid Account Summary label metadata");
}
const defaults = Object.fromEntries(
  [...document.getElementsByTagName("labels")].map((entry) => [
    entry.getElementsByTagName("fullName")[0].textContent,
    entry.getElementsByTagName("value")[0].textContent
  ])
);
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
  values[`AccountSummary${suffix}`] = value;
}

export function resetLabels() {
  Object.assign(values, defaults);
}
