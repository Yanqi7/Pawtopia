package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Activity;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.ActivityService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/activities")
@CrossOrigin(origins = "*")
public class ActivityController {
    
    @Autowired
    private ActivityService activityService;
    
    // 根据宠物ID获取活动记录
    @GetMapping("/pet/{petId}")
    public ResponseEntity<List<Activity>> getActivitiesByPetId(@PathVariable Long petId) {
        List<Activity> activities = activityService.getActivitiesByPetId(petId);
        return new ResponseEntity<>(activities, HttpStatus.OK);
    }
    
    // 根据用户ID获取活动记录
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Activity>> getActivitiesByUserId(@PathVariable Long userId) {
        List<Activity> activities = activityService.getActivitiesByUserId(userId);
        return new ResponseEntity<>(activities, HttpStatus.OK);
    }
    
    // 根据宠物ID和日期范围获取活动记录
    @GetMapping("/pet/{petId}/date-range")
    public ResponseEntity<List<Activity>> getActivitiesByPetIdAndDateRange(
            @PathVariable Long petId,
            @RequestParam String startDate,
            @RequestParam String endDate) {
        LocalDateTime start = LocalDateTime.parse(startDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        LocalDateTime end = LocalDateTime.parse(endDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        List<Activity> activities = activityService.getActivitiesByPetIdAndDateRange(petId, start, end);
        return new ResponseEntity<>(activities, HttpStatus.OK);
    }
    
    // 根据用户ID和日期范围获取活动记录
    @GetMapping("/user/{userId}/date-range")
    public ResponseEntity<List<Activity>> getActivitiesByUserIdAndDateRange(
            @PathVariable Long userId,
            @RequestParam String startDate,
            @RequestParam String endDate) {
        LocalDateTime start = LocalDateTime.parse(startDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        LocalDateTime end = LocalDateTime.parse(endDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        List<Activity> activities = activityService.getActivitiesByUserIdAndDateRange(userId, start, end);
        return new ResponseEntity<>(activities, HttpStatus.OK);
    }
    
    // 根据日期范围获取活动记录
    @GetMapping("/date-range")
    public ResponseEntity<List<Activity>> getActivitiesByDateRange(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        LocalDateTime start = LocalDateTime.parse(startDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        LocalDateTime end = LocalDateTime.parse(endDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        List<Activity> activities = activityService.getActivitiesByDateRange(start, end);
        return new ResponseEntity<>(activities, HttpStatus.OK);
    }
    
    // 根据ID获取活动记录
    @GetMapping("/{id}")
    public ResponseEntity<Activity> getActivityById(@PathVariable Long id) {
        Optional<Activity> activity = activityService.getActivityById(id);
        if (activity.isPresent()) {
            return new ResponseEntity<>(activity.get(), HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 创建新活动记录
    @PostMapping
    public ResponseEntity<Activity> createActivity(@RequestBody Activity activity) {
        Activity createdActivity = activityService.createActivity(activity);
        return new ResponseEntity<>(createdActivity, HttpStatus.CREATED);
    }
    
    // 更新活动记录
    @PutMapping("/{id}")
    public ResponseEntity<Activity> updateActivity(@PathVariable Long id, @RequestBody Activity activityDetails) {
        try {
            Activity updatedActivity = activityService.updateActivity(id, activityDetails);
            return new ResponseEntity<>(updatedActivity, HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 删除活动记录
    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deleteActivity(@PathVariable Long id) {
        try {
            activityService.deleteActivity(id);
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
}