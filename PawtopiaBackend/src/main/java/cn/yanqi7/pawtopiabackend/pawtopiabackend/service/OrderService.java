package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Order;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Product;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.OrderRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private ProductRepository productRepository;

    public List<Order> getOrdersByUserId(Long userId) {
        return orderRepository.findByUserId(userId);
    }

    public List<Order> getOrdersByStatus(Order.OrderStatus status) {
        return orderRepository.findByStatus(status);
    }

    public List<Order> getOrdersByUserIdAndStatus(Long userId, Order.OrderStatus status) {
        return orderRepository.findByUserIdAndStatus(userId, status);
    }

    public Optional<Order> getOrderById(Long id) {
        return orderRepository.findById(id);
    }

    @Transactional
    public Order createOrder(Order order) {
        if (order.getUserId() == null) {
            throw new IllegalArgumentException("User id is required");
        }
        Order normalized = normalizeOrder(order);
        List<Product> products = loadProducts(normalized.getProductIds());
        List<Integer> quantities = parseIntegerCsv(normalized.getQuantities());
        ensureOrderShape(products, quantities);
        ensureStockAvailable(products, quantities);
        normalized.setTotalAmount(calculateTotal(products, quantities));
        normalized.setStatus(Order.OrderStatus.PENDING);
        deductStock(products, quantities);
        return orderRepository.save(normalized);
    }

    @Transactional
    public Order updateOrder(Long id, Order orderDetails) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + id));

        if (orderDetails.getShippingAddress() != null) {
            order.setShippingAddress(orderDetails.getShippingAddress());
        }
        if (orderDetails.getContactPhone() != null) {
            order.setContactPhone(orderDetails.getContactPhone());
        }
        if (orderDetails.getContactName() != null) {
            order.setContactName(orderDetails.getContactName());
        }

        return orderRepository.save(order);
    }

    @Transactional
    public void deleteOrder(Long id) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + id));
        if (order.getStatus() == Order.OrderStatus.PENDING) {
            restoreStock(order);
        }
        orderRepository.delete(order);
    }

    @Transactional
    public Order updateOrderStatus(Long id, Order.OrderStatus newStatus) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + id));
        Order.OrderStatus currentStatus = order.getStatus();
        if (currentStatus == newStatus) {
            return order;
        }
        if (!canTransition(currentStatus, newStatus)) {
            throw new IllegalArgumentException("Illegal order status transition: " + currentStatus + " -> " + newStatus);
        }
        if (newStatus == Order.OrderStatus.CANCELLED) {
            restoreStock(order);
        }
        order.setStatus(newStatus);
        return orderRepository.save(order);
    }

    private Order normalizeOrder(Order order) {
        if (order.getProductIds() == null || order.getQuantities() == null) {
            throw new IllegalArgumentException("Product ids and quantities are required");
        }
        order.setProductIds(order.getProductIds().trim());
        order.setQuantities(order.getQuantities().trim());
        return order;
    }

    private List<Product> loadProducts(String productIdsCsv) {
        List<Long> productIds = parseLongCsv(productIdsCsv);
        if (productIds.isEmpty()) {
            throw new IllegalArgumentException("At least one product is required");
        }
        List<Product> products = new ArrayList<>();
        for (Long productId : productIds) {
            Product product = productRepository.findById(productId)
                    .orElseThrow(() -> new IllegalArgumentException("Product not found with id: " + productId));
            products.add(product);
        }
        return products;
    }

    private void ensureOrderShape(List<Product> products, List<Integer> quantities) {
        if (products.size() != quantities.size()) {
            throw new IllegalArgumentException("Product ids count must match quantities count");
        }
        for (Integer quantity : quantities) {
            if (quantity == null || quantity <= 0) {
                throw new IllegalArgumentException("Quantity must be positive");
            }
        }
    }

    private void ensureStockAvailable(List<Product> products, List<Integer> quantities) {
        for (int i = 0; i < products.size(); i++) {
            Product product = products.get(i);
            int stock = product.getStockQuantity() == null ? 0 : product.getStockQuantity();
            if (stock < quantities.get(i)) {
                throw new IllegalArgumentException("Insufficient stock for product: " + product.getName());
            }
        }
    }

    private BigDecimal calculateTotal(List<Product> products, List<Integer> quantities) {
        BigDecimal total = BigDecimal.ZERO;
        for (int i = 0; i < products.size(); i++) {
            total = total.add(products.get(i).getPrice().multiply(BigDecimal.valueOf(quantities.get(i))));
        }
        return total;
    }

    private void deductStock(List<Product> products, List<Integer> quantities) {
        for (int i = 0; i < products.size(); i++) {
            Product product = products.get(i);
            product.setStockQuantity(product.getStockQuantity() - quantities.get(i));
            productRepository.save(product);
        }
    }

    private void restoreStock(Order order) {
        List<Product> products = loadProducts(order.getProductIds());
        List<Integer> quantities = parseIntegerCsv(order.getQuantities());
        for (int i = 0; i < products.size(); i++) {
            Product product = products.get(i);
            int currentStock = product.getStockQuantity() == null ? 0 : product.getStockQuantity();
            product.setStockQuantity(currentStock + quantities.get(i));
            productRepository.save(product);
        }
    }

    private boolean canTransition(Order.OrderStatus currentStatus, Order.OrderStatus newStatus) {
        return switch (currentStatus) {
            case PENDING -> newStatus == Order.OrderStatus.PAID || newStatus == Order.OrderStatus.CANCELLED;
            case PAID -> newStatus == Order.OrderStatus.SHIPPED || newStatus == Order.OrderStatus.CANCELLED;
            case SHIPPED -> newStatus == Order.OrderStatus.DELIVERED;
            case DELIVERED, CANCELLED -> false;
        };
    }

    private List<Long> parseLongCsv(String csv) {
        List<Long> values = new ArrayList<>();
        if (csv == null || csv.isBlank()) {
            return values;
        }
        for (String token : csv.split(",")) {
            String value = token.trim();
            if (!value.isEmpty()) {
                values.add(Long.parseLong(value));
            }
        }
        return values;
    }

    private List<Integer> parseIntegerCsv(String csv) {
        List<Integer> values = new ArrayList<>();
        if (csv == null || csv.isBlank()) {
            return values;
        }
        for (String token : csv.split(",")) {
            String value = token.trim();
            if (!value.isEmpty()) {
                values.add(Integer.parseInt(value));
            }
        }
        return values;
    }
}
