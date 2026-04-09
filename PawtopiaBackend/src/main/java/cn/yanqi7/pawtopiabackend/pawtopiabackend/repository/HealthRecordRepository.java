package cn.yanqi7.pawtopiabackend.pawtopiabackend.repository;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.HealthRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface HealthRecordRepository extends JpaRepository<HealthRecord, Long> {
    List<HealthRecord> findByPetIdOrderByRecordDateDesc(Long petId);
    List<HealthRecord> findByPetIdAndRecordTypeOrderByRecordDateDesc(Long petId, HealthRecord.RecordType recordType);
    List<HealthRecord> findByRecordDateBetween(LocalDate startDate, LocalDate endDate);
    List<HealthRecord> findByPetIdAndRecordDateBetweenOrderByRecordDateDesc(Long petId, LocalDate startDate, LocalDate endDate);
    List<HealthRecord> findByNextDueDateBetween(LocalDate startDate, LocalDate endDate);
}
