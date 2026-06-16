public interface IPODataTransformer {
    IPODataTransformer prepareData();
    List<Response> transformPreparedData();
}