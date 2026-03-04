package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Comment;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.CommentService;
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
@RequestMapping("/api/comments")
@CrossOrigin(origins = "*")
public class CommentController {
    
    @Autowired
    private CommentService commentService;
    
    @Autowired
    private PostService postService; // 用于更新帖子的评论数
    
    // 根据帖子ID获取评论（分页）
    @GetMapping("/post/{postId}")
    public ResponseEntity<Page<Comment>> getCommentsByPostId(
            @PathVariable Long postId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy) {
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy).ascending());
        Page<Comment> comments = commentService.getCommentsByPostId(postId, pageable);
        return new ResponseEntity<>(comments, HttpStatus.OK);
    }
    
    // 根据用户ID获取评论（分页）
    @GetMapping("/user/{userId}")
    public ResponseEntity<Page<Comment>> getCommentsByUserId(
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
        Page<Comment> comments = commentService.getCommentsByUserId(userId, pageable);
        return new ResponseEntity<>(comments, HttpStatus.OK);
    }
    
    // 根据帖子ID获取顶级评论（不包括回复）
    @GetMapping("/post/{postId}/top")
    public ResponseEntity<List<Comment>> getTopLevelCommentsByPostId(@PathVariable Long postId) {
        List<Comment> comments = commentService.getTopLevelCommentsByPostId(postId);
        return new ResponseEntity<>(comments, HttpStatus.OK);
    }
    
    // 根据父评论ID获取回复
    @GetMapping("/parent/{parentId}")
    public ResponseEntity<List<Comment>> getRepliesByParentId(@PathVariable Long parentId) {
        List<Comment> replies = commentService.getRepliesByParentId(parentId);
        return new ResponseEntity<>(replies, HttpStatus.OK);
    }
    
    // 根据ID获取评论
    @GetMapping("/{id}")
    public ResponseEntity<Comment> getCommentById(@PathVariable Long id) {
        Optional<Comment> comment = commentService.getCommentById(id);
        if (comment.isPresent()) {
            return new ResponseEntity<>(comment.get(), HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 创建新评论
    @PostMapping
    public ResponseEntity<Comment> createComment(@RequestBody Comment comment) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        if (!SecurityUtil.isAdmin()) {
            comment.setUserId(currentUserId);
        }
        Comment createdComment = commentService.createComment(comment);
        
        // 更新帖子的评论数
        if (createdComment.getPostId() != null) {
            postService.incrementCommentCount(createdComment.getPostId());
        }
        
        return new ResponseEntity<>(createdComment, HttpStatus.CREATED);
    }
    
    // 更新评论
    @PutMapping("/{id}")
    public ResponseEntity<Comment> updateComment(@PathVariable Long id, @RequestBody Comment commentDetails) {
        try {
            Comment updatedComment = commentService.updateComment(id, commentDetails);
            return new ResponseEntity<>(updatedComment, HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 删除评论
    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deleteComment(@PathVariable Long id) {
        Optional<Comment> commentOpt = commentService.getCommentById(id);
        if (commentOpt.isPresent()) {
            Comment comment = commentOpt.get();
            Long postId = comment.getPostId();
            
            commentService.deleteComment(id);
            
            // 更新帖子的评论数
            if (postId != null) {
                postService.decrementCommentCount(postId);
            }
            
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 增加评论点赞数
    @PostMapping("/{id}/like")
    public ResponseEntity<Comment> likeComment(@PathVariable Long id) {
        Optional<Comment> commentOpt = commentService.getCommentById(id);
        if (commentOpt.isPresent()) {
            commentService.incrementLikeCount(id);
            Comment updatedComment = commentOpt.get();
            updatedComment.setLikeCount(updatedComment.getLikeCount() + 1);
            return new ResponseEntity<>(updatedComment, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 减少评论点赞数
    @DeleteMapping("/{id}/like")
    public ResponseEntity<Comment> unlikeComment(@PathVariable Long id) {
        Optional<Comment> commentOpt = commentService.getCommentById(id);
        if (commentOpt.isPresent()) {
            commentService.decrementLikeCount(id);
            Comment updatedComment = commentOpt.get();
            if (updatedComment.getLikeCount() > 0) {
                updatedComment.setLikeCount(updatedComment.getLikeCount() - 1);
            }
            return new ResponseEntity<>(updatedComment, HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
}
