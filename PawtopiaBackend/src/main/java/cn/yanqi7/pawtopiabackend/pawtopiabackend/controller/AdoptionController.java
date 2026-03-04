package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.dto.AdoptionDtos;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.AdoptionRequest;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.AdoptionRequestRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.security.SecurityUtil;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.AdoptionService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/adoptions")
@CrossOrigin(origins = "*")
public class AdoptionController {
    private final AdoptionService adoptionService;
    private final AdoptionRequestRepository adoptionRequestRepository;

    public AdoptionController(AdoptionService adoptionService, AdoptionRequestRepository adoptionRequestRepository) {
        this.adoptionService = adoptionService;
        this.adoptionRequestRepository = adoptionRequestRepository;
    }

    // 领养列表（匿名可访问）
    @GetMapping("/listings")
    public ResponseEntity<List<Pet>> listings() {
        return new ResponseEntity<>(adoptionService.getAdoptionListings(), HttpStatus.OK);
    }

    // 发起领养申请（需要登录）
    @PostMapping("/pets/{petId}/requests")
    public ResponseEntity<AdoptionRequest> createRequest(@PathVariable Long petId, @RequestBody AdoptionDtos.CreateRequestBody body) {
        Long requesterId = SecurityUtil.userId();
        if (requesterId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        Pet pet = adoptionService.getPet(petId).orElse(null);
        if (pet == null) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        if (pet.getAdoptionStatus() != Pet.AdoptionStatus.AVAILABLE) {
            return new ResponseEntity<>(HttpStatus.CONFLICT);
        }
        if (pet.getOwnerId() != null && pet.getOwnerId().equals(requesterId)) {
            return new ResponseEntity<>(HttpStatus.CONFLICT);
        }
        if (adoptionRequestRepository.existsByPetIdAndRequesterIdAndStatus(petId, requesterId, AdoptionRequest.Status.PENDING)) {
            return new ResponseEntity<>(HttpStatus.CONFLICT);
        }

        AdoptionRequest req = new AdoptionRequest();
        req.setPetId(petId);
        req.setOwnerId(pet.getOwnerId());
        req.setRequesterId(requesterId);
        req.setStatus(AdoptionRequest.Status.PENDING);
        req.setMessage(body == null ? null : body.getMessage());
        req.setContactName(body == null ? null : body.getContactName());
        req.setContactPhone(body == null ? null : body.getContactPhone());
        AdoptionRequest created = adoptionService.createRequest(req);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    // 查看某宠物的领养申请（仅宠物 owner 或 ADMIN）
    @GetMapping("/pets/{petId}/requests")
    public ResponseEntity<List<AdoptionRequest>> getRequestsByPet(@PathVariable Long petId) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        Pet pet = adoptionService.getPet(petId).orElse(null);
        if (pet == null) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        if (!SecurityUtil.isAdmin() && (pet.getOwnerId() == null || !pet.getOwnerId().equals(currentUserId))) {
            return new ResponseEntity<>(HttpStatus.FORBIDDEN);
        }
        return new ResponseEntity<>(adoptionService.getRequestsByPetId(petId), HttpStatus.OK);
    }

    // 我发起的领养申请（需要登录）
    @GetMapping("/requests/mine")
    public ResponseEntity<List<AdoptionRequest>> myRequests() {
        Long requesterId = SecurityUtil.userId();
        if (requesterId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        return new ResponseEntity<>(adoptionService.getMyRequests(requesterId), HttpStatus.OK);
    }

    // 更新领养申请状态（仅宠物 owner 或 ADMIN）
    @PutMapping("/requests/{id}/status/{status}")
    public ResponseEntity<AdoptionRequest> updateStatus(@PathVariable Long id, @PathVariable AdoptionRequest.Status status) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        AdoptionRequest req = adoptionService.getRequest(id).orElse(null);
        if (req == null) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        if (!SecurityUtil.isAdmin() && (req.getOwnerId() == null || !req.getOwnerId().equals(currentUserId))) {
            return new ResponseEntity<>(HttpStatus.FORBIDDEN);
        }
        AdoptionRequest updated = adoptionService.updateStatus(id, status);
        return new ResponseEntity<>(updated, HttpStatus.OK);
    }

    // 申请者撤回领养申请（申请者本人或 ADMIN）
    @PutMapping("/requests/{id}/cancel")
    public ResponseEntity<AdoptionRequest> cancel(@PathVariable Long id) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        AdoptionRequest req = adoptionService.getRequest(id).orElse(null);
        if (req == null) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        if (!SecurityUtil.isAdmin() && (req.getRequesterId() == null || !req.getRequesterId().equals(currentUserId))) {
            return new ResponseEntity<>(HttpStatus.FORBIDDEN);
        }
        if (req.getStatus() != AdoptionRequest.Status.PENDING) {
            return new ResponseEntity<>(HttpStatus.CONFLICT);
        }
        AdoptionRequest updated = adoptionService.updateStatus(id, AdoptionRequest.Status.CANCELLED);
        return new ResponseEntity<>(updated, HttpStatus.OK);
    }
}
