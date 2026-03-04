package cn.yanqi7.pawtopiabackend.pawtopiabackend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "comments")
@Data
public class Comment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "post_id", nullable = false)
    private Long postId; // 关联的帖子ID
    
    @Column(name = "user_id", nullable = false)
    private Long userId; // 评论者ID
    
    @Column(name = "parent_id")
    private Long parentId; // 父评论ID（用于回复评论）
    
    @Lob
    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;
    
    @Column(name = "like_count")
    private Integer likeCount = 0;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}