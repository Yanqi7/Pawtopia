package cn.yanqi7.pawtopiabackend.pawtopiabackend.repository;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Activity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ActivityRepository extends JpaRepository<Activity, Long> {
    List<Activity> findByPetId(Long petId);
    List<Activity> findByUserId(Long userId);
    List<Activity> findByPetIdAndActivityDateBetween(Long petId, LocalDateTime start, LocalDateTime end);
    List<Activity> findByUserIdAndActivityDateBetween(Long userId, LocalDateTime start, LocalDateTime end);
    List<Activity> findByActivityDateBetween(LocalDateTime start, LocalDateTime end);
}