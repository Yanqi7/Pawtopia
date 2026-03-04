package cn.yanqi7.pawtopiabackend.pawtopiabackend.repository;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Post;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PostRepository extends JpaRepository<Post, Long> {
    Page<Post> findByUserId(Long userId, Pageable pageable);
    Page<Post> findByPetId(Long petId, Pageable pageable);
    Page<Post> findAllByOrderByCreatedAtDesc(Pageable pageable);
    List<Post> findByUserIdOrderByCreatedAtDesc(Long userId);
}