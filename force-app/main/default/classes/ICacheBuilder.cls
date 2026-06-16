/**
 * Interface for cache builder pattern
 * Follows Interface Segregation Principle - focused on cache miss handling
 */
public interface ICacheBuilder {
    Object buildValue(String key);
}