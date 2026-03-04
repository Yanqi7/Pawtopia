package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Activity;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.ActivityRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class ActivityService {
    
    @Autowired
    private ActivityRepository activityRepository;
    
    public List<Activity> getActivitiesByPetId(Long petId) {
        return activityRepository.findByPetId(petId);
    }
    
    public List<Activity> getActivitiesByUserId(Long userId) {
        return activityRepository.findByUserId(userId);
    }
    
    public List<Activity> getActivitiesByPetIdAndDateRange(Long petId, LocalDateTime start, LocalDateTime end) {
        return activityRepository.findByPetIdAndActivityDateBetween(petId, start, end);
    }
    
    public List<Activity> getActivitiesByUserIdAndDateRange(Long userId, LocalDateTime start, LocalDateTime end) {
        return activityRepository.findByUserIdAndActivityDateBetween(userId, start, end);
    }
    
    public List<Activity> getActivitiesByDateRange(LocalDateTime start, LocalDateTime end) {
        return activityRepository.findByActivityDateBetween(start, end);
    }
    
    public Optional<Activity> getActivityById(Long id) {
        return activityRepository.findById(id);
    }
    
    public Activity createActivity(Activity activity) {
        return activityRepository.save(activity);
    }
    
    public Activity updateActivity(Long id, Activity activityDetails) {
        Activity activity = activityRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Activity not found with id: " + id));
        
        activity.setPetId(activityDetails.getPetId());
        activity.setUserId(activityDetails.getUserId());
        activity.setTitle(activityDetails.getTitle());
        activity.setDescription(activityDetails.getDescription());
        activity.setType(activityDetails.getType());
        activity.setActivityDate(activityDetails.getActivityDate());
        activity.setDuration(activityDetails.getDuration());
        activity.setCalories(activityDetails.getCalories());
        
        return activityRepository.save(activity);
    }
    
    public void deleteActivity(Long id) {
        activityRepository.deleteById(id);
    }
}