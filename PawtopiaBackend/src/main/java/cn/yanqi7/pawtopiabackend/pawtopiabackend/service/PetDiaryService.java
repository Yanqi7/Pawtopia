package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.PetDiary;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PetDiaryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
public class PetDiaryService {
    
    @Autowired
    private PetDiaryRepository petDiaryRepository;
    
    public List<PetDiary> getDiariesByPetId(Long petId) {
        return petDiaryRepository.findByPetId(petId);
    }
    
    public List<PetDiary> getDiariesByUserId(Long userId) {
        return petDiaryRepository.findByUserId(userId);
    }
    
    public List<PetDiary> getDiariesByPetIdAndDateRange(Long petId, LocalDate start, LocalDate end) {
        return petDiaryRepository.findByPetIdAndDiaryDateBetween(petId, start, end);
    }
    
    public List<PetDiary> getDiariesByUserIdAndDateRange(Long userId, LocalDate start, LocalDate end) {
        return petDiaryRepository.findByUserIdAndDiaryDateBetween(userId, start, end);
    }
    
    public Optional<PetDiary> getDiaryById(Long id) {
        return petDiaryRepository.findById(id);
    }
    
    public PetDiary createDiary(PetDiary diary) {
        return petDiaryRepository.save(diary);
    }
    
    public PetDiary updateDiary(Long id, PetDiary diaryDetails) {
        PetDiary diary = petDiaryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("PetDiary not found with id: " + id));
        
        diary.setPetId(diaryDetails.getPetId());
        diary.setUserId(diaryDetails.getUserId());
        diary.setTitle(diaryDetails.getTitle());
        diary.setContent(diaryDetails.getContent());
        diary.setImage(diaryDetails.getImage());
        diary.setDiaryDate(diaryDetails.getDiaryDate());
        
        return petDiaryRepository.save(diary);
    }
    
    public void deleteDiary(Long id) {
        petDiaryRepository.deleteById(id);
    }
}