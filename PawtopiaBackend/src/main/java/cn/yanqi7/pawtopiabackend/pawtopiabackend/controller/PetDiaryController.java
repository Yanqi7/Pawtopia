package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.PetDiary;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PetRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.security.SecurityUtil;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.PetDiaryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/pet-diaries")
@CrossOrigin(origins = "*")
public class PetDiaryController {

    @Autowired
    private PetDiaryService petDiaryService;

    @Autowired
    private PetRepository petRepository;

    private void assertCanAccessUser(Long userId) {
        if (!SecurityUtil.isSelfOrAdmin(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        }
    }

    private void assertCanAccessPet(Long petId) {
        Pet pet = petRepository.findById(petId).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        Long currentUserId = SecurityUtil.userId();
        if (!SecurityUtil.isAdmin() && (currentUserId == null || !currentUserId.equals(pet.getOwnerId()))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        }
    }

    @GetMapping("/pet/{petId}")
    public ResponseEntity<List<PetDiary>> getDiariesByPetId(@PathVariable Long petId) {
        assertCanAccessPet(petId);
        return new ResponseEntity<>(petDiaryService.getDiariesByPetId(petId), HttpStatus.OK);
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<PetDiary>> getDiariesByUserId(@PathVariable Long userId) {
        assertCanAccessUser(userId);
        return new ResponseEntity<>(petDiaryService.getDiariesByUserId(userId), HttpStatus.OK);
    }

    @GetMapping("/pet/{petId}/date-range")
    public ResponseEntity<List<PetDiary>> getDiariesByPetIdAndDateRange(
            @PathVariable Long petId,
            @RequestParam String startDate,
            @RequestParam String endDate) {
        assertCanAccessPet(petId);
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        return new ResponseEntity<>(petDiaryService.getDiariesByPetIdAndDateRange(petId, start, end), HttpStatus.OK);
    }

    @GetMapping("/user/{userId}/date-range")
    public ResponseEntity<List<PetDiary>> getDiariesByUserIdAndDateRange(
            @PathVariable Long userId,
            @RequestParam String startDate,
            @RequestParam String endDate) {
        assertCanAccessUser(userId);
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        return new ResponseEntity<>(petDiaryService.getDiariesByUserIdAndDateRange(userId, start, end), HttpStatus.OK);
    }

    @GetMapping("/{id}")
    public ResponseEntity<PetDiary> getDiaryById(@PathVariable Long id) {
        Optional<PetDiary> diary = petDiaryService.getDiaryById(id);
        if (diary.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        assertCanAccessUser(diary.get().getUserId());
        return new ResponseEntity<>(diary.get(), HttpStatus.OK);
    }

    @PostMapping
    public ResponseEntity<PetDiary> createDiary(@RequestBody PetDiary diary) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        assertCanAccessPet(diary.getPetId());
        diary.setUserId(SecurityUtil.isAdmin() && diary.getUserId() != null ? diary.getUserId() : currentUserId);
        PetDiary createdDiary = petDiaryService.createDiary(diary);
        return new ResponseEntity<>(createdDiary, HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<PetDiary> updateDiary(@PathVariable Long id, @RequestBody PetDiary diaryDetails) {
        Optional<PetDiary> existing = petDiaryService.getDiaryById(id);
        if (existing.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        assertCanAccessUser(existing.get().getUserId());
        if (!SecurityUtil.isAdmin()) {
            diaryDetails.setUserId(existing.get().getUserId());
            diaryDetails.setPetId(existing.get().getPetId());
        }
        try {
            PetDiary updatedDiary = petDiaryService.updateDiary(id, diaryDetails);
            return new ResponseEntity<>(updatedDiary, HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deleteDiary(@PathVariable Long id) {
        Optional<PetDiary> existing = petDiaryService.getDiaryById(id);
        if (existing.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        assertCanAccessUser(existing.get().getUserId());
        petDiaryService.deleteDiary(id);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }
}
