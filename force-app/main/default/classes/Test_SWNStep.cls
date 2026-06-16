@isTest
class Test_SWNStep {
    @isTest
    private static void testStepConstructor() {
        final String name ='testName';
        final String label = 'testLabel';
        final String description = 'testDescription';
        SWNStep step = new SWNStep.SWNStepBuilder()
            .withName(name)
            .withLabel(label)
            .withDescription(description)
            .build();

        Assert.areEqual(
            name,
            step.name,
            'Property name populated incorrectly'
        );
        Assert.areEqual(
            label,
            step.label,
            'Property label populated incorrectly'
        );
        Assert.areEqual(
            description,
            step.description,
            'Property description populated incorrectly'
        );
    }
}