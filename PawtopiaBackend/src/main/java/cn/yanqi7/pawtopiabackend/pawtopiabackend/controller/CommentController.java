package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Comment;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.security.SecurityUtil;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.CommentService;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.PostService;
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
    private PostService postService;

    @GetMapping("/post/{postId}")
    public ResponseEntity<Page<Comment>> getCommentsByPostId(
            @PathVariable Long postId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy) {

        Pageable pageable = PageRequest.of(page, size, Sort.by(sortBy).ascending());
        return new ResponseEntity<>(commentService.getCommentsByPostId(postId, pageable), HttpStatus.OK);
    }

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
        return new ResponseEntity<>(commentService.getCommentsByUserId(userId, pageable), HttpStatus.OK);
    }

    @GetMapping("/post/{postId}/top")
    public ResponseEntity<List<Comment>> getTopLevelCommentsByPostId(@PathVariable Long postId) {
        return new ResponseEntity<>(commentService.getTopLevelCommentsByPostId(postId), HttpStatus.OK);
    }

    @GetMapping("/parent/{parentId}")
    public ResponseEntity<List<Comment>> getRepliesByParentId(@PathVariable Long parentId) {
        return new ResponseEntity<>(commentService.getRepliesByParentId(parentId), HttpStatus.OK);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Comment> getCommentById(@PathVariable Long id) {
        Optional<Comment> comment = commentService.getCommentById(id);
        return comment.map(value -> new ResponseEntity<>(value, HttpStatus.OK))
                .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
    }

    @PostMapping
    public ResponseEntity<Comment> createComment(@RequestBody Comment comment) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        if (comment.getPostId() == null || postService.getPostById(comment.getPostId()).isEmpty()) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        }
        comment.setUserId(currentUserId);
        Comment createdComment = commentService.createComment(comment);
        postService.incrementCommentCount(createdComment.getPostId());
        return new ResponseEntity<>(createdComment, HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Comment> updateComment(@PathVariable Long id, @RequestBody Comment commentDetails) {
        Optional<Comment> existingComment = commentService.getCommentById(id);
        if (existingComment.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        if (!SecurityUtil.isAdmin() && !SecurityUtil.isSelf(existingComment.get().getUserId())) {
            return new ResponseEntity<>(HttpStatus.FORBIDDEN);
        }
        try {
            return new ResponseEntity<>(commentService.updateComment(id, commentDetails), HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deleteComment(@PathVariable Long id) {
        Optional<Comment> commentOpt = commentService.getCommentById(id);
        if (commentOpt.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        Comment comment = commentOpt.get();
        if (!SecurityUtil.isAdmin() && !SecurityUtil.isSelf(comment.getUserId())) {
            return new ResponseEntity<>(HttpStatus.FORBIDDEN);
        }
        commentService.deleteComment(id);
        if (comment.getPostId() != null) {
            postService.decrementCommentCount(comment.getPostId());
        }
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    @PostMapping("/{id}/like")
    public ResponseEntity<Comment> likeComment(@PathVariable Long id) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        try {
            return new ResponseEntity<>(commentService.likeComment(id, currentUserId), HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @DeleteMapping("/{id}/like")
    public ResponseEntity<Comment> unlikeComment(@PathVariable Long id) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        try {
            return new ResponseEntity<>(commentService.unlikeComment(id, currentUserId), HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
}
