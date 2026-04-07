package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Post;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.PostLike;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PostLikeRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PostRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class PostService {

    @Autowired
    private PostRepository postRepository;

    @Autowired
    private PostLikeRepository postLikeRepository;

    public Page<Post> getAllPosts(Pageable pageable) {
        return postRepository.findAllByOrderByCreatedAtDesc(pageable);
    }

    public Optional<Post> getPostById(Long id) {
        return postRepository.findById(id);
    }

    public Page<Post> getPostsByUserId(Long userId, Pageable pageable) {
        return postRepository.findByUserId(userId, pageable);
    }

    public Page<Post> getPostsByPetId(Long petId, Pageable pageable) {
        return postRepository.findByPetId(petId, pageable);
    }

    public List<Post> getPostsByUserIdOrderByDate(Long userId) {
        return postRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public Post createPost(Post post) {
        if (post.getViewCount() == null) {
            post.setViewCount(0);
        }
        if (post.getLikeCount() == null) {
            post.setLikeCount(0);
        }
        if (post.getCommentCount() == null) {
            post.setCommentCount(0);
        }
        return postRepository.save(post);
    }

    public Post updatePost(Long id, Post postDetails) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found with id: " + id));

        if (postDetails.getTitle() != null) {
            post.setTitle(postDetails.getTitle());
        }
        if (postDetails.getContent() != null) {
            post.setContent(postDetails.getContent());
        }
        post.setPetId(postDetails.getPetId());
        post.setImageUrls(postDetails.getImageUrls());

        return postRepository.save(post);
    }

    public void deletePost(Long id) {
        postRepository.deleteById(id);
    }

    @Transactional
    public Post incrementViewCount(Long id) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found with id: " + id));
        post.setViewCount(safeCount(post.getViewCount()) + 1);
        return postRepository.save(post);
    }

    @Transactional
    public Post likePost(Long id, Long userId) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found with id: " + id));
        if (postLikeRepository.existsByPostIdAndUserId(id, userId)) {
            return post;
        }
        PostLike postLike = new PostLike();
        postLike.setPostId(id);
        postLike.setUserId(userId);
        postLikeRepository.save(postLike);
        post.setLikeCount(safeCount(post.getLikeCount()) + 1);
        return postRepository.save(post);
    }

    @Transactional
    public Post unlikePost(Long id, Long userId) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found with id: " + id));
        long removed = postLikeRepository.deleteByPostIdAndUserId(id, userId);
        if (removed > 0) {
            post.setLikeCount(Math.max(0, safeCount(post.getLikeCount()) - 1));
            return postRepository.save(post);
        }
        return post;
    }

    public void incrementCommentCount(Long id) {
        postRepository.findById(id).ifPresent(post -> {
            post.setCommentCount(safeCount(post.getCommentCount()) + 1);
            postRepository.save(post);
        });
    }

    public void decrementCommentCount(Long id) {
        postRepository.findById(id).ifPresent(post -> {
            post.setCommentCount(Math.max(0, safeCount(post.getCommentCount()) - 1));
            postRepository.save(post);
        });
    }

    private int safeCount(Integer value) {
        return value == null ? 0 : value;
    }
}
