package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Post;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PostRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class PostService {
    
    @Autowired
    private PostRepository postRepository;
    
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
        return postRepository.save(post);
    }
    
    public Post updatePost(Long id, Post postDetails) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found with id: " + id));
        
        post.setTitle(postDetails.getTitle());
        post.setContent(postDetails.getContent());
        post.setUserId(postDetails.getUserId());
        post.setPetId(postDetails.getPetId());
        post.setImageUrls(postDetails.getImageUrls());
        
        return postRepository.save(post);
    }
    
    public void deletePost(Long id) {
        postRepository.deleteById(id);
    }
    
    public void incrementViewCount(Long id) {
        Optional<Post> postOpt = postRepository.findById(id);
        if (postOpt.isPresent()) {
            Post post = postOpt.get();
            post.setViewCount(post.getViewCount() + 1);
            postRepository.save(post);
        }
    }
    
    public void incrementLikeCount(Long id) {
        Optional<Post> postOpt = postRepository.findById(id);
        if (postOpt.isPresent()) {
            Post post = postOpt.get();
            post.setLikeCount(post.getLikeCount() + 1);
            postRepository.save(post);
        }
    }
    
    public void decrementLikeCount(Long id) {
        Optional<Post> postOpt = postRepository.findById(id);
        if (postOpt.isPresent()) {
            Post post = postOpt.get();
            if (post.getLikeCount() > 0) {
                post.setLikeCount(post.getLikeCount() - 1);
                postRepository.save(post);
            }
        }
    }
    
    public void incrementCommentCount(Long id) {
        Optional<Post> postOpt = postRepository.findById(id);
        if (postOpt.isPresent()) {
            Post post = postOpt.get();
            post.setCommentCount(post.getCommentCount() + 1);
            postRepository.save(post);
        }
    }
    
    public void decrementCommentCount(Long id) {
        Optional<Post> postOpt = postRepository.findById(id);
        if (postOpt.isPresent()) {
            Post post = postOpt.get();
            if (post.getCommentCount() > 0) {
                post.setCommentCount(post.getCommentCount() - 1);
                postRepository.save(post);
            }
        }
    }
}