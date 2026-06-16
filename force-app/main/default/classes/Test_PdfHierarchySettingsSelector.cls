@IsTest
private class Test_PdfHierarchySettingsSelector {
    @isTest
    static void testSelectPdfHierarchySettings() {
        List<PdfHierarchySettings__mdt> settings = (List<PdfHierarchySettings__mdt>) new PdfHierarchySettingsSelector()
            .selectPdfHierarchySettings()
            .executeQuery();

        System.assert(!settings.isEmpty(), 'There is no pdf hierarchy settings metadata on org');
    }
}