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

    @GetMapping("/listings")
    public ResponseEntity<List<Pet>> listings() {
        return new ResponseEntity<>(adoptionService.getAdoptionListings(), HttpStatus.OK);
    }

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

    @GetMapping("/requests/mine")
    public ResponseEntity<List<AdoptionRequest>> myRequests() {
        Long requesterId = SecurityUtil.userId();
        if (requesterId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        return new ResponseEntity<>(adoptionService.getMyRequests(requesterId), HttpStatus.OK);
    }

    @PutMapping("/requests/{id}/status/{status}")
    public ResponseEntity<AdoptionRequest> updateStatus(@PathVariable Long id, @PathVariable AdoptionRequest.Status status) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        if (status == AdoptionRequest.Status.CANCELLED) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        }
        AdoptionRequest req = adoptionService.getRequest(id).orElse(null);
        if (req == null) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        if (!SecurityUtil.isAdmin() && (req.getOwnerId() == null || !req.getOwnerId().equals(currentUserId))) {
            return new ResponseEntity<>(HttpStatus.FORBIDDEN);
        }
        try {
            AdoptionRequest updated = adoptionService.updateStatus(id, status);
            return new ResponseEntity<>(updated, HttpStatus.OK);
        } catch (IllegalArgumentException e) {
            return new ResponseEntity<>(HttpStatus.CONFLICT);
        }
    }

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
        try {
            AdoptionRequest updated = adoptionService.updateStatus(id, AdoptionRequest.Status.CANCELLED);
            return new ResponseEntity<>(updated, HttpStatus.OK);
        } catch (IllegalArgumentException e) {
            return new ResponseEntity<>(HttpStatus.CONFLICT);
        }
    }
}
