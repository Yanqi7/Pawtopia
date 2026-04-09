package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.HealthRecord;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.HealthRecordRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
public class HealthRecordService {

    @Autowired
    private HealthRecordRepository healthRecordRepository;

    public List<HealthRecord> getHealthRecordsByPetId(Long petId) {
        return healthRecordRepository.findByPetIdOrderByRecordDateDesc(petId);
    }

    public List<HealthRecord> getHealthRecordsByPetIdAndType(Long petId, HealthRecord.RecordType recordType) {
        return healthRecordRepository.findByPetIdAndRecordTypeOrderByRecordDateDesc(petId, recordType);
    }

    public List<HealthRecord> getHealthRecordsByDateRange(LocalDate startDate, LocalDate endDate) {
        return healthRecordRepository.findByRecordDateBetween(startDate, endDate);
    }

    public List<HealthRecord> getHealthRecordsByPetIdAndDateRange(Long petId, LocalDate startDate, LocalDate endDate) {
        return healthRecordRepository.findByPetIdAndRecordDateBetweenOrderByRecordDateDesc(petId, startDate, endDate);
    }

    public List<HealthRecord> getUpcomingAppointments(LocalDate startDate, LocalDate endDate) {
        return healthRecordRepository.findByNextDueDateBetween(startDate, endDate);
    }

    public Optional<HealthRecord> getHealthRecordById(Long id) {
        return healthRecordRepository.findById(id);
    }

    public HealthRecord createHealthRecord(HealthRecord healthRecord) {
        normalizeNextDueDate(healthRecord);
        return healthRecordRepository.save(healthRecord);
    }

    public HealthRecord updateHealthRecord(Long id, HealthRecord healthRecordDetails) {
        HealthRecord healthRecord = healthRecordRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("HealthRecord not found with id: " + id));

        healthRecord.setPetId(healthRecordDetails.getPetId());
        healthRecord.setRecordType(healthRecordDetails.getRecordType());
        healthRecord.setTitle(healthRecordDetails.getTitle());
        healthRecord.setDescription(healthRecordDetails.getDescription());
        healthRecord.setRecordDate(healthRecordDetails.getRecordDate());
        healthRecord.setNextDueDate(healthRecordDetails.getNextDueDate());
        healthRecord.setVeterinarian(healthRecordDetails.getVeterinarian());
        normalizeNextDueDate(healthRecord);

        return healthRecordRepository.save(healthRecord);
    }

    public void deleteHealthRecord(Long id) {
        healthRecordRepository.deleteById(id);
    }

    private void normalizeNextDueDate(HealthRecord record) {
        if (record.getRecordType() == null) {
            return;
        }
        if (record.getRecordType() != HealthRecord.RecordType.VACCINATION) {
            record.setNextDueDate(null);
            return;
        }
        if (record.getNextDueDate() == null && record.getRecordDate() != null) {
            record.setNextDueDate(record.getRecordDate().plusYears(1));
        }
    }
}
