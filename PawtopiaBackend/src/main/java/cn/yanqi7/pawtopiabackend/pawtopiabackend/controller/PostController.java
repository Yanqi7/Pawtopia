package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Post;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.PostService;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.security.SecurityUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/posts")
@CrossOrigin(origins = "*")
public class PostController {
    
    @Autowired
    private PostService postService;
    
    // 获取所有帖子（分页）
    @GetMapping
    public ResponseEntity<Page<Post>> getAllPosts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy) {
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy).descending());
        Page<Post> posts = postService.getAllPosts(pageable);
        return new ResponseEntity<>(posts, HttpStatus.OK);
    }
    
    // 根据ID获取帖子
    @GetMapping("/{id}")
    public ResponseEntity<Post> getPostById(@PathVariable Long id) {
        Optional<Post> post = postService.getPostById(id);
        if (post.isPresent()) {
            // 增加浏览量
            postService.incrementViewCount(id);
            return new ResponseEntity<>(post.get(), HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 根据用户ID获取帖子（分页）
    @GetMapping("/user/{userId}")
    public ResponseEntity<Page<Post>> getPostsByUserId(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy) {
        
        if (!SecurityUtil.isAdmin()) {
            Long currentUserId = SecurityUtil.userId();
            if (currentUserId == null || !currentUserId.equals(userId)) {
                return new ResponseEntity<>(HttpStatus.FORBIDDEN);
            }
        }
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy).descending());
        Page<Post> posts = postService.getPostsByUserId(userId, pageable);
        return new ResponseEntity<>(posts, HttpStatus.OK);
    }
    
    // 根据宠物ID获取帖子（分页）
    @GetMapping("/pet/{petId}")
    public ResponseEntity<Page<Post>> getPostsByPetId(
            @PathVariable Long petId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy) {
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy).descending());
        Page<Post> posts = postService.getPostsByPetId(petId, pageable);
        return new ResponseEntity<>(posts, HttpStatus.OK);
    }
    
    // 根据用户ID获取帖子（按时间排序，不分页）
    @GetMapping("/user/{userId}/all")
    public ResponseEntity<List<Post>> getPostsByUserIdOrderByDate(@PathVariable Long userId) {
        if (!SecurityUtil.isAdmin()) {
            Long currentUserId = SecurityUtil.userId();
            if (currentUserId == null || !currentUserId.equals(userId)) {
                return new ResponseEntity<>(HttpStatus.FORBIDDEN);
            }
        }
        List<Post> posts = postService.getPostsByUserIdOrderByDate(userId);
        return new ResponseEntity<>(posts, HttpStatus.OK);
    }
    
    // 创建新帖子
    @PostMapping
    public ResponseEntity<Post> createPost(@RequestBody Post post) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        if (!SecurityUtil.isAdmin()) {
            post.setUserId(currentUserId);
        }
        Post createdPost = postService.createPost(post);
        return new ResponseEntity<>(createdPost, HttpStatus.CREATED);
    }
    
    // 更新帖子
    @PutMapping("/{id}")
    public ResponseEntity<Post> updatePost(@PathVariable Long id, @RequestBody Post postDetails) {
        try {
            Post updatedPost = postService.updatePost(id, postDetails);
            return new ResponseEntity<>(updatedPost, HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 删除帖子
    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deletePost(@PathVariable Long id) {
        try {
            postService.deletePost(id);
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 增加帖子点赞数
    @PostMapping("/{id}/like")
    public ResponseEntity<Post> likePost(@PathVariable Long id) {
        Optional<Post> postOpt = postService.getPostById(id);
        if (postOpt.isPresent()) {
            postService.incrementLikeCount(id);
            Post updatedPost = postOpt.get();
            updatedPost.setLikeCount(updatedPost.getLikeCount() + 1);
            return new ResponseEntity<>(updatedPost, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 减少帖子点赞数
    @DeleteMapping("/{id}/like")
    public ResponseEntity<Post> unlikePost(@PathVariable Long id) {
        Optional<Post> postOpt = postService.getPostById(id);
        if (postOpt.isPresent()) {
            postService.decrementLikeCount(id);
            Post updatedPost = postOpt.get();
            if (updatedPost.getLikeCount() > 0) {
                updatedPost.setLikeCount(updatedPost.getLikeCount() - 1);
            }
            return new ResponseEntity<>(updatedPost, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
}
