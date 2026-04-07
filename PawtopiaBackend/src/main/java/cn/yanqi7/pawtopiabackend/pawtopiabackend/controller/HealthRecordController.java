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

    private void assertHospitalOrAdmin() {
        if (!SecurityUtil.isAdmin() && SecurityUtil.role() != User.Role.PET_HOSPITAL) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        }
    }

    @GetMapping("/pet/{petId}")
    public ResponseEntity<List<HealthRecord>> getHealthRecordsByPetId(@PathVariable Long petId) {
        assertCanAccessPet(petId);
        return new ResponseEntity<>(healthRecordService.getHealthRecordsByPetId(petId), HttpStatus.OK);
    }

    @GetMapping("/pet/{petId}/type/{recordType}")
    public ResponseEntity<List<HealthRecord>> getHealthRecordsByPetIdAndType(
            @PathVariable Long petId,
            @PathVariable HealthRecord.RecordType recordType) {
        assertCanAccessPet(petId);
        return new ResponseEntity<>(healthRecordService.getHealthRecordsByPetIdAndType(petId, recordType), HttpStatus.OK);
    }

    @GetMapping("/date-range")
    public ResponseEntity<List<HealthRecord>> getHealthRecordsByDateRange(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        assertHospitalOrAdmin();
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        return new ResponseEntity<>(healthRecordService.getHealthRecordsByDateRange(start, end), HttpStatus.OK);
    }

    @GetMapping("/pet/{petId}/date-range")
    public ResponseEntity<List<HealthRecord>> getHealthRecordsByPetIdAndDateRange(
            @PathVariable Long petId,
            @RequestParam String startDate,
            @RequestParam String endDate) {
        assertCanAccessPet(petId);
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        return new ResponseEntity<>(healthRecordService.getHealthRecordsByPetIdAndDateRange(petId, start, end), HttpStatus.OK);
    }

    @GetMapping("/upcoming-appointments")
    public ResponseEntity<List<HealthRecord>> getUpcomingAppointments(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        assertHospitalOrAdmin();
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        return new ResponseEntity<>(healthRecordService.getUpcomingAppointments(start, end), HttpStatus.OK);
    }

    @GetMapping("/{id}")
    public ResponseEntity<HealthRecord> getHealthRecordById(@PathVariable Long id) {
        Optional<HealthRecord> record = healthRecordService.getHealthRecordById(id);
        if (record.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        assertCanAccessPet(record.get().getPetId());
        return new ResponseEntity<>(record.get(), HttpStatus.OK);
    }

    @PostMapping
    public ResponseEntity<HealthRecord> createHealthRecord(@RequestBody HealthRecord healthRecord) {
        if (healthRecord.getPetId() == null) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        }
        assertCanAccessPet(healthRecord.getPetId());
        return new ResponseEntity<>(healthRecordService.createHealthRecord(healthRecord), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<HealthRecord> updateHealthRecord(@PathVariable Long id, @RequestBody HealthRecord healthRecordDetails) {
        Optional<HealthRecord> existingRecord = healthRecordService.getHealthRecordById(id);
        if (existingRecord.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        assertCanAccessPet(existingRecord.get().getPetId());
        if (!SecurityUtil.isAdmin() && SecurityUtil.role() != User.Role.PET_HOSPITAL) {
            healthRecordDetails.setPetId(existingRecord.get().getPetId());
        }
        try {
            return new ResponseEntity<>(healthRecordService.updateHealthRecord(id, healthRecordDetails), HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deleteHealthRecord(@PathVariable Long id) {
        Optional<HealthRecord> existingRecord = healthRecordService.getHealthRecordById(id);
        if (existingRecord.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        assertCanAccessPet(existingRecord.get().getPetId());
        healthRecordService.deleteHealthRecord(id);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }
}
