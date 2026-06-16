public with sharing abstract class CollectionOptional {

    public Boolean isNullable(Object obj) {
        return obj == null;
    }

    public abstract Object get(Integer index, Object defaultValue);
    public abstract Object getFirst();
    public abstract Object getLast();
}