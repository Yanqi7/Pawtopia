package cn.yanqi7.pawtopiabackend.pawtopiabackend.repository;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.AdoptionRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AdoptionRequestRepository extends JpaRepository<AdoptionRequest, Long> {
    List<AdoptionRequest> findByPetIdOrderByCreatedAtDesc(Long petId);
    List<AdoptionRequest> findByRequesterIdOrderByCreatedAtDesc(Long requesterId);
    List<AdoptionRequest> findByOwnerIdOrderByCreatedAtDesc(Long ownerId);
    boolean existsByPetIdAndOwnerId(Long petId, Long ownerId);
    boolean existsByPetIdAndRequesterIdAndStatus(Long petId, Long requesterId, AdoptionRequest.Status status);
}

