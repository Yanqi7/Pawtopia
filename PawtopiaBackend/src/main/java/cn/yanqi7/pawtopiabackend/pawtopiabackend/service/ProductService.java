package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Product;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ProductService {
    
    @Autowired
    private ProductRepository productRepository;
    
    public Page<Product> getAllProducts(Pageable pageable) {
        return productRepository.findAll(pageable);
    }
    
    public Optional<Product> getProductById(Long id) {
        return productRepository.findById(id);
    }
    
    public Page<Product> getProductsByCategory(Product.ProductCategory category, Pageable pageable) {
        return productRepository.findByCategory(category, pageable);
    }
    
    public Page<Product> searchProductsByName(String name, Pageable pageable) {
        return productRepository.findByNameContainingIgnoreCase(name, pageable);
    }
    
    public List<Product> getProductsByCategorySortedByPriceAsc(Product.ProductCategory category) {
        return productRepository.findByCategoryOrderByPriceAsc(category);
    }
    
    public List<Product> getProductsByCategorySortedByPriceDesc(Product.ProductCategory category) {
        return productRepository.findByCategoryOrderByPriceDesc(category);
    }
    
    public Product createProduct(Product product) {
        return productRepository.save(product);
    }
    
    public Product updateProduct(Long id, Product productDetails) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found with id: " + id));
        
        product.setName(productDetails.getName());
        product.setDescription(productDetails.getDescription());
        product.setPrice(productDetails.getPrice());
        product.setImage(productDetails.getImage());
        product.setStockQuantity(productDetails.getStockQuantity());
        product.setCategory(productDetails.getCategory());
        
        return productRepository.save(product);
    }
    
    public void deleteProduct(Long id) {
        productRepository.deleteById(id);
    }
}