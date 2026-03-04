package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.AdoptionRequest;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.AdoptionRequestRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PetRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class AdoptionService {
    private final AdoptionRequestRepository adoptionRequestRepository;
    private final PetRepository petRepository;

    public AdoptionService(AdoptionRequestRepository adoptionRequestRepository, PetRepository petRepository) {
        this.adoptionRequestRepository = adoptionRequestRepository;
        this.petRepository = petRepository;
    }

    public List<Pet> getAdoptionListings() {
        return petRepository.findByAdoptionStatus(Pet.AdoptionStatus.AVAILABLE);
    }

    public Optional<Pet> getPet(Long petId) {
        return petRepository.findById(petId);
    }

    public AdoptionRequest createRequest(AdoptionRequest request) {
        return adoptionRequestRepository.save(request);
    }

    public Optional<AdoptionRequest> getRequest(Long id) {
        return adoptionRequestRepository.findById(id);
    }

    public List<AdoptionRequest> getRequestsByPetId(Long petId) {
        return adoptionRequestRepository.findByPetIdOrderByCreatedAtDesc(petId);
    }

    public List<AdoptionRequest> getMyRequests(Long requesterId) {
        return adoptionRequestRepository.findByRequesterIdOrderByCreatedAtDesc(requesterId);
    }

    public AdoptionRequest updateStatus(Long id, AdoptionRequest.Status status) {
        AdoptionRequest req = adoptionRequestRepository.findById(id).orElseThrow(() -> new RuntimeException("not found"));
        req.setStatus(status);
        AdoptionRequest saved = adoptionRequestRepository.save(req);
        if (status == AdoptionRequest.Status.APPROVED) {
            petRepository.findById(req.getPetId()).ifPresent(pet -> {
                pet.setAdoptionStatus(Pet.AdoptionStatus.ADOPTED);
                petRepository.save(pet);
            });
        }
        return saved;
    }
}

