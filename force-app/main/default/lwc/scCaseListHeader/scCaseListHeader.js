import { track, api } from "lwc";
import BaseService from "c/lwcBaseService";
import createNewCase from "@salesforce/label/c.SC_CreateNewCase";

export default class ScCaseListHeader extends BaseService {
    @api title = "My Case Portal";
    @api newCaseLink = "new-case";
    labels = {
      createNewCase: createNewCase || "Create New Case",
    };
    handleNewCase() {
        location.href = this.newCaseLink;
    }
}