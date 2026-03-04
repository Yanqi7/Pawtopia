package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.HealthRecord;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.User;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PetRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.security.SecurityUtil;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.HealthRecordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/health-records")
@CrossOrigin(origins = "*")
public class HealthRecordController {
    
    @Autowired
    private HealthRecordService healthRecordService;

    @Autowired
    private PetRepository petRepository;

    private void assertCanAccessPet(Long petId) {
        Pet pet = petRepository.findById(petId).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        Long currentUserId = SecurityUtil.userId();
        User.Role role = SecurityUtil.role();
        boolean allowed = SecurityUtil.isAdmin()
                || role == User.Role.PET_HOSPITAL
                || (currentUserId != null && currentUserId.equals(pet.getOwnerId()));
        if (!allowed) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        }
    }
    
    // 根据宠物ID获取健康记录
    @GetMapping("/pet/{petId}")
    public ResponseEntity<List<HealthRecord>> getHealthRecordsByPetId(@PathVariable Long petId) {
        assertCanAccessPet(petId);
        List<HealthRecord> records = healthRecordService.getHealthRecordsByPetId(petId);
        return new ResponseEntity<>(records, HttpStatus.OK);
    }
    
    // 根据宠物ID和记录类型获取健康记录
    @GetMapping("/pet/{petId}/type/{recordType}")
    public ResponseEntity<List<HealthRecord>> getHealthRecordsByPetIdAndType(
            @PathVariable Long petId, 
            @PathVariable HealthRecord.RecordType recordType) {
        assertCanAccessPet(petId);
        List<HealthRecord> records = healthRecordService.getHealthRecordsByPetIdAndType(petId, recordType);
        return new ResponseEntity<>(records, HttpStatus.OK);
    }
    
    // 根据日期范围获取健康记录
    @GetMapping("/date-range")
    public ResponseEntity<List<HealthRecord>> getHealthRecordsByDateRange(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        List<HealthRecord> records = healthRecordService.getHealthRecordsByDateRange(start, end);
        return new ResponseEntity<>(records, HttpStatus.OK);
    }
    
    // 根据宠物ID和日期范围获取健康记录
    @GetMapping("/pet/{petId}/date-range")
    public ResponseEntity<List<HealthRecord>> getHealthRecordsByPetIdAndDateRange(
            @PathVariable Long petId,
            @RequestParam String startDate,
            @RequestParam String endDate) {
        assertCanAccessPet(petId);
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        List<HealthRecord> records = healthRecordService.getHealthRecordsByPetIdAndDateRange(petId, start, end);
        return new ResponseEntity<>(records, HttpStatus.OK);
    }
    
    // 获取即将到期的预约
    @GetMapping("/upcoming-appointments")
    public ResponseEntity<List<HealthRecord>> getUpcomingAppointments(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        List<HealthRecord> records = healthRecordService.getUpcomingAppointments(start, end);
        return new ResponseEntity<>(records, HttpStatus.OK);
    }
    
    // 根据ID获取健康记录
    @GetMapping("/{id}")
    public ResponseEntity<HealthRecord> getHealthRecordById(@PathVariable Long id) {
        Optional<HealthRecord> record = healthRecordService.getHealthRecordById(id);
        if (record.isPresent()) {
            return new ResponseEntity<>(record.get(), HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 创建新健康记录
    @PostMapping
    public ResponseEntity<HealthRecord> createHealthRecord(@RequestBody HealthRecord healthRecord) {
        if (healthRecord.getPetId() == null) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        }
        assertCanAccessPet(healthRecord.getPetId());
        HealthRecord createdRecord = healthRecordService.createHealthRecord(healthRecord);
        return new ResponseEntity<>(createdRecord, HttpStatus.CREATED);
    }
    
    // 更新健康记录
    @PutMapping("/{id}")
    public ResponseEntity<HealthRecord> updateHealthRecord(@PathVariable Long id, @RequestBody HealthRecord healthRecordDetails) {
        try {
            HealthRecord updatedRecord = healthRecordService.updateHealthRecord(id, healthRecordDetails);
            return new ResponseEntity<>(updatedRecord, HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 删除健康记录
    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deleteHealthRecord(@PathVariable Long id) {
        try {
            healthRecordService.deleteHealthRecord(id);
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
}
