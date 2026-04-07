package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Comment;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.CommentLike;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.CommentLikeRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.CommentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class CommentService {

    @Autowired
    private CommentRepository commentRepository;

    @Autowired
    private CommentLikeRepository commentLikeRepository;

    public Page<Comment> getCommentsByPostId(Long postId, Pageable pageable) {
        return commentRepository.findByPostId(postId, pageable);
    }

    public Page<Comment> getCommentsByUserId(Long userId, Pageable pageable) {
        return commentRepository.findByUserId(userId, pageable);
    }

    public List<Comment> getTopLevelCommentsByPostId(Long postId) {
        return commentRepository.findByPostIdAndParentIdIsNullOrderByCreatedAtAsc(postId);
    }

    public List<Comment> getRepliesByParentId(Long parentId) {
        return commentRepository.findByParentId(parentId);
    }

    public Optional<Comment> getCommentById(Long id) {
        return commentRepository.findById(id);
    }

    public Comment createComment(Comment comment) {
        if (comment.getLikeCount() == null) {
            comment.setLikeCount(0);
        }
        return commentRepository.save(comment);
    }

    public Comment updateComment(Long id, Comment commentDetails) {
        Comment comment = commentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Comment not found with id: " + id));

        if (commentDetails.getContent() != null) {
            comment.setContent(commentDetails.getContent());
        }

        return commentRepository.save(comment);
    }

    public void deleteComment(Long id) {
        commentRepository.deleteById(id);
    }

    @Transactional
    public Comment likeComment(Long id, Long userId) {
        Comment comment = commentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Comment not found with id: " + id));
        if (commentLikeRepository.existsByCommentIdAndUserId(id, userId)) {
            return comment;
        }
        CommentLike commentLike = new CommentLike();
        commentLike.setCommentId(id);
        commentLike.setUserId(userId);
        commentLikeRepository.save(commentLike);
        comment.setLikeCount(safeCount(comment.getLikeCount()) + 1);
        return commentRepository.save(comment);
    }

    @Transactional
    public Comment unlikeComment(Long id, Long userId) {
        Comment comment = commentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Comment not found with id: " + id));
        long removed = commentLikeRepository.deleteByCommentIdAndUserId(id, userId);
        if (removed > 0) {
            comment.setLikeCount(Math.max(0, safeCount(comment.getLikeCount()) - 1));
            return commentRepository.save(comment);
        }
        return comment;
    }

    private int safeCount(Integer value) {
        return value == null ? 0 : value;
    }
}
