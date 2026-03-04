package cn.yanqi7.pawtopiabackend.pawtopiabackend.repository;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    Page<Product> findByCategory(Product.ProductCategory category, Pageable pageable);
    Page<Product> findByNameContainingIgnoreCase(String name, Pageable pageable);
    List<Product> findByCategoryOrderByPriceAsc(Product.ProductCategory category);
    List<Product> findByCategoryOrderByPriceDesc(Product.ProductCategory category);
}