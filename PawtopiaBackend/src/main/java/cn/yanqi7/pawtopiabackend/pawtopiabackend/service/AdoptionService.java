package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.AdoptionRequest;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.AdoptionRequestRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PetRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
        request.setStatus(AdoptionRequest.Status.PENDING);
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

    @Transactional
    public AdoptionRequest updateStatus(Long id, AdoptionRequest.Status status) {
        AdoptionRequest req = adoptionRequestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Adoption request not found with id: " + id));
        if (req.getStatus() == status) {
            return req;
        }
        if (req.getStatus() != AdoptionRequest.Status.PENDING) {
            throw new IllegalArgumentException("Only pending adoption requests can be updated");
        }

        if (status == AdoptionRequest.Status.APPROVED) {
            Pet pet = petRepository.findById(req.getPetId())
                    .orElseThrow(() -> new RuntimeException("Pet not found with id: " + req.getPetId()));
            if (pet.getAdoptionStatus() != Pet.AdoptionStatus.AVAILABLE) {
                throw new IllegalArgumentException("Pet is not available for adoption");
            }
            pet.setAdoptionStatus(Pet.AdoptionStatus.ADOPTED);
            pet.setOwnerId(req.getRequesterId());
            petRepository.save(pet);

            List<AdoptionRequest> requests = adoptionRequestRepository.findByPetIdOrderByCreatedAtDesc(req.getPetId());
            for (AdoptionRequest item : requests) {
                if (item.getId().equals(req.getId())) {
                    item.setStatus(AdoptionRequest.Status.APPROVED);
                } else if (item.getStatus() == AdoptionRequest.Status.PENDING) {
                    item.setStatus(AdoptionRequest.Status.REJECTED);
                }
            }
            adoptionRequestRepository.saveAll(requests);
            return requests.stream()
                    .filter(item -> item.getId().equals(req.getId()))
                    .findFirst()
                    .orElse(req);
        }

        req.setStatus(status);
        return adoptionRequestRepository.save(req);
    }
}
