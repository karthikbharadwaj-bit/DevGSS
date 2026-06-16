public with sharing class ListOptional extends CollectionOptional {

    private List<Object> listInstance;

    public ListOptional(List<Object> listInstance) {
        this.listInstance = listInstance;
    }

    public override Object get(Integer index, Object defaultValue) {
        if (
            isNullable(listInstance)
                || listInstance.isEmpty()
                || index < 0
                || index >= listInstance.size()
            ) {
            return defaultValue;
        }
        return this.listInstance.get(index);
    }

    public override Object getFirst() {
        return get(0, null);
    }

    public override Object getLast() {
        return get(listInstance.size() - 1, null);
    }
}