package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.PetDiary;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.PetDiaryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/pet-diaries")
@CrossOrigin(origins = "*")
public class PetDiaryController {
    
    @Autowired
    private PetDiaryService petDiaryService;
    
    // 根据宠物ID获取日记
    @GetMapping("/pet/{petId}")
    public ResponseEntity<List<PetDiary>> getDiariesByPetId(@PathVariable Long petId) {
        List<PetDiary> diaries = petDiaryService.getDiariesByPetId(petId);
        return new ResponseEntity<>(diaries, HttpStatus.OK);
    }
    
    // 根据用户ID获取日记
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<PetDiary>> getDiariesByUserId(@PathVariable Long userId) {
        List<PetDiary> diaries = petDiaryService.getDiariesByUserId(userId);
        return new ResponseEntity<>(diaries, HttpStatus.OK);
    }
    
    // 根据宠物ID和日期范围获取日记
    @GetMapping("/pet/{petId}/date-range")
    public ResponseEntity<List<PetDiary>> getDiariesByPetIdAndDateRange(
            @PathVariable Long petId,
            @RequestParam String startDate,
            @RequestParam String endDate) {
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        List<PetDiary> diaries = petDiaryService.getDiariesByPetIdAndDateRange(petId, start, end);
        return new ResponseEntity<>(diaries, HttpStatus.OK);
    }
    
    // 根据用户ID和日期范围获取日记
    @GetMapping("/user/{userId}/date-range")
    public ResponseEntity<List<PetDiary>> getDiariesByUserIdAndDateRange(
            @PathVariable Long userId,
            @RequestParam String startDate,
            @RequestParam String endDate) {
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        List<PetDiary> diaries = petDiaryService.getDiariesByUserIdAndDateRange(userId, start, end);
        return new ResponseEntity<>(diaries, HttpStatus.OK);
    }
    
    // 根据ID获取日记
    @GetMapping("/{id}")
    public ResponseEntity<PetDiary> getDiaryById(@PathVariable Long id) {
        Optional<PetDiary> diary = petDiaryService.getDiaryById(id);
        if (diary.isPresent()) {
            return new ResponseEntity<>(diary.get(), HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 创建新日记
    @PostMapping
    public ResponseEntity<PetDiary> createDiary(@RequestBody PetDiary diary) {
        PetDiary createdDiary = petDiaryService.createDiary(diary);
        return new ResponseEntity<>(createdDiary, HttpStatus.CREATED);
    }
    
    // 更新日记
    @PutMapping("/{id}")
    public ResponseEntity<PetDiary> updateDiary(@PathVariable Long id, @RequestBody PetDiary diaryDetails) {
        try {
            PetDiary updatedDiary = petDiaryService.updateDiary(id, diaryDetails);
            return new ResponseEntity<>(updatedDiary, HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 删除日记
    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deleteDiary(@PathVariable Long id) {
        try {
            petDiaryService.deleteDiary(id);
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
}