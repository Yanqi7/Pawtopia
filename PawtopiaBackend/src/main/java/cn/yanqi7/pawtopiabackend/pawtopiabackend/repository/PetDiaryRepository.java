package cn.yanqi7.pawtopiabackend.pawtopiabackend.repository;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.PetDiary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface PetDiaryRepository extends JpaRepository<PetDiary, Long> {
    List<PetDiary> findByPetId(Long petId);
    List<PetDiary> findByUserId(Long userId);
    List<PetDiary> findByPetIdAndDiaryDateBetween(Long petId, LocalDate start, LocalDate end);
    List<PetDiary> findByUserIdAndDiaryDateBetween(Long userId, LocalDate start, LocalDate end);
}