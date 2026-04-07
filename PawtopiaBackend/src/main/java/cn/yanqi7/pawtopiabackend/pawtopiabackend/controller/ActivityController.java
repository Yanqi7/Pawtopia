package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Activity;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PetRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.security.SecurityUtil;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.ActivityService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

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
    public ResponseEntity<List<Activity>> getActivitiesByPetId(@PathVariable Long petId) {
        assertCanAccessPet(petId);
        return new ResponseEntity<>(activityService.getActivitiesByPetId(petId), HttpStatus.OK);
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Activity>> getActivitiesByUserId(@PathVariable Long userId) {
        assertCanAccessUser(userId);
        return new ResponseEntity<>(activityService.getActivitiesByUserId(userId), HttpStatus.OK);
    }

    @GetMapping("/pet/{petId}/date-range")
    public ResponseEntity<List<Activity>> getActivitiesByPetIdAndDateRange(
            @PathVariable Long petId,
            @RequestParam String startDate,
            @RequestParam String endDate) {
        assertCanAccessPet(petId);
        LocalDateTime start = LocalDateTime.parse(startDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        LocalDateTime end = LocalDateTime.parse(endDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        return new ResponseEntity<>(activityService.getActivitiesByPetIdAndDateRange(petId, start, end), HttpStatus.OK);
    }

    @GetMapping("/user/{userId}/date-range")
    public ResponseEntity<List<Activity>> getActivitiesByUserIdAndDateRange(
            @PathVariable Long userId,
            @RequestParam String startDate,
            @RequestParam String endDate) {
        assertCanAccessUser(userId);
        LocalDateTime start = LocalDateTime.parse(startDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        LocalDateTime end = LocalDateTime.parse(endDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        return new ResponseEntity<>(activityService.getActivitiesByUserIdAndDateRange(userId, start, end), HttpStatus.OK);
    }

    @GetMapping("/date-range")
    public ResponseEntity<List<Activity>> getActivitiesByDateRange(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        if (!SecurityUtil.isAdmin()) {
            return new ResponseEntity<>(HttpStatus.FORBIDDEN);
        }
        LocalDateTime start = LocalDateTime.parse(startDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        LocalDateTime end = LocalDateTime.parse(endDate, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        return new ResponseEntity<>(activityService.getActivitiesByDateRange(start, end), HttpStatus.OK);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Activity> getActivityById(@PathVariable Long id) {
        Optional<Activity> activity = activityService.getActivityById(id);
        if (activity.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        assertCanAccessUser(activity.get().getUserId());
        return new ResponseEntity<>(activity.get(), HttpStatus.OK);
    }

    @PostMapping
    public ResponseEntity<Activity> createActivity(@RequestBody Activity activity) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        assertCanAccessPet(activity.getPetId());
        activity.setUserId(SecurityUtil.isAdmin() && activity.getUserId() != null ? activity.getUserId() : currentUserId);
        Activity createdActivity = activityService.createActivity(activity);
        return new ResponseEntity<>(createdActivity, HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Activity> updateActivity(@PathVariable Long id, @RequestBody Activity activityDetails) {
        Optional<Activity> existing = activityService.getActivityById(id);
        if (existing.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        assertCanAccessUser(existing.get().getUserId());
        if (!SecurityUtil.isAdmin()) {
            activityDetails.setUserId(existing.get().getUserId());
            activityDetails.setPetId(existing.get().getPetId());
        }
        try {
            Activity updatedActivity = activityService.updateActivity(id, activityDetails);
            return new ResponseEntity<>(updatedActivity, HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deleteActivity(@PathVariable Long id) {
        Optional<Activity> existing = activityService.getActivityById(id);
        if (existing.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        assertCanAccessUser(existing.get().getUserId());
        activityService.deleteActivity(id);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }
}
