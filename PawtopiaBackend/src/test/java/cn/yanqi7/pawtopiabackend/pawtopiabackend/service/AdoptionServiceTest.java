package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.AdoptionRequest;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.AdoptionRequestRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PetRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdoptionServiceTest {

    @Mock
    private AdoptionRequestRepository adoptionRequestRepository;

    @Mock
    private PetRepository petRepository;

    @InjectMocks
    private AdoptionService adoptionService;

    @Test
    void approveRequestShouldTransferPetAndCloseOtherPendingRequests() {
        Pet pet = new Pet();
        pet.setId(10L);
        pet.setOwnerId(1L);
        pet.setAdoptionStatus(Pet.AdoptionStatus.AVAILABLE);

        AdoptionRequest approved = new AdoptionRequest();
        approved.setId(1L);
        approved.setPetId(10L);
        approved.setOwnerId(1L);
        approved.setRequesterId(2L);
        approved.setStatus(AdoptionRequest.Status.PENDING);

        AdoptionRequest pending = new AdoptionRequest();
        pending.setId(2L);
        pending.setPetId(10L);
        pending.setOwnerId(1L);
        pending.setRequesterId(3L);
        pending.setStatus(AdoptionRequest.Status.PENDING);

        when(adoptionRequestRepository.findById(1L)).thenReturn(Optional.of(approved));
        when(petRepository.findById(10L)).thenReturn(Optional.of(pet));
        when(petRepository.save(any(Pet.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(adoptionRequestRepository.findByPetIdOrderByCreatedAtDesc(10L)).thenReturn(List.of(approved, pending));
        when(adoptionRequestRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));

        AdoptionRequest result = adoptionService.updateStatus(1L, AdoptionRequest.Status.APPROVED);

        assertEquals(AdoptionRequest.Status.APPROVED, result.getStatus());
        assertEquals(Pet.AdoptionStatus.ADOPTED, pet.getAdoptionStatus());
        assertEquals(2L, pet.getOwnerId());
        assertEquals(AdoptionRequest.Status.REJECTED, pending.getStatus());
    }
}
