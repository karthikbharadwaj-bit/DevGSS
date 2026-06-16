import errorMessage from "@salesforce/label/c.SC_Case_Create_error_message";
import myCases from '@salesforce/label/c.SC_Case_List_myCases';
import favoriteCases from '@salesforce/label/c.SC_Case_List_favoriteCases';
import accountCases from '@salesforce/label/c.SC_Case_List_accountCases';
import empty from '@salesforce/label/c.SC_Case_List_empty';
import subject from '@salesforce/label/c.SC_Case_List_subject';
import caseNumber from '@salesforce/label/c.SC_Case_List_caseNumber';
import contact from '@salesforce/label/c.SC_Case_List_contact';
import dateCreated from '@salesforce/label/c.SC_Case_List_dateCreated';
import mainContact from '@salesforce/label/c.SC_Case_List_mainContact';
import caseStatus from '@salesforce/label/c.SC_Case_List_caseStatus';
import selectView from '@salesforce/label/c.SC_Case_List_selectView';
import searchBy from '@salesforce/label/c.SC_Case_List_searchBy';
import searchCriteria from '@salesforce/label/c.SC_Case_List_searchCriteria';
import search from '@salesforce/label/c.SC_Case_List_search';
import view from '@salesforce/label/c.SC_Case_List_view';
import exportCSV from '@salesforce/label/c.SC_Case_List_exportCSV';
import show from '@salesforce/label/c.SC_Case_List_show';
import clearSearchResults from '@salesforce/label/c.SC_Case_List_clearSearchResults';
import to from '@salesforce/label/c.SC_Case_List_to';
import of from '@salesforce/label/c.SC_Case_List_of';

export const labels = {
    errorMessage: errorMessage || "Something goes wrong!",
    empty: empty || "There are no cases",
    myCases: myCases || "My Cases",
    favoriteCases: favoriteCases || "Favorite Cases",
    accountCases: accountCases || "Account Cases",
    subject: subject || "Subject",
    caseNumber: caseNumber || "Case Number",
    contact: contact || "Contact",
    dateCreated: dateCreated || "Date Created",
    mainContact: mainContact || "Main Contact",
    caseStatus: caseStatus || "Case Status",
    selectView: selectView || "Select View",
    searchBy: searchBy || "Search by",
    searchCriteria: searchCriteria || "Search criteria",
    search: search || "Search",
    view: view || "View",
    exportCSV: exportCSV || "Export CSV",
    show: show || "Show",
    clearSearchResults: clearSearchResults || "Clear search results",
    to: to || "to",
    of: of || "of",
};