package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Order;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Product;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.OrderRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.ProductRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private OrderService orderService;

    @Test
    void createOrderShouldValidateStockAndCalculateTotal() {
        Product product = new Product();
        product.setId(1L);
        product.setName("Dog Food");
        product.setPrice(new BigDecimal("19.90"));
        product.setStockQuantity(10);

        Order order = new Order();
        order.setUserId(1L);
        order.setProductIds("1");
        order.setQuantities("2");
        order.setShippingAddress("test");
        order.setContactName("user");
        order.setContactPhone("123");

        when(productRepository.findById(1L)).thenReturn(Optional.of(product));
        when(productRepository.save(any(Product.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Order created = orderService.createOrder(order);

        assertNotNull(created);
        assertEquals(new BigDecimal("39.80"), created.getTotalAmount());
        assertEquals(Order.OrderStatus.PENDING, created.getStatus());
        assertEquals(8, product.getStockQuantity());
    }

    @Test
    void cancelOrderShouldRestoreStock() {
        Product product = new Product();
        product.setId(1L);
        product.setName("Dog Food");
        product.setPrice(new BigDecimal("19.90"));
        product.setStockQuantity(8);

        Order order = new Order();
        order.setId(99L);
        order.setUserId(1L);
        order.setProductIds("1");
        order.setQuantities("2");
        order.setStatus(Order.OrderStatus.PENDING);
        order.setTotalAmount(new BigDecimal("39.80"));

        when(orderRepository.findById(99L)).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(productRepository.findById(1L)).thenReturn(Optional.of(product));
        when(productRepository.save(any(Product.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Order updated = orderService.updateOrderStatus(99L, Order.OrderStatus.CANCELLED);

        assertEquals(Order.OrderStatus.CANCELLED, updated.getStatus());
        assertEquals(10, product.getStockQuantity());
    }
}
