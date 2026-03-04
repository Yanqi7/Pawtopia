package cn.yanqi7.pawtopiabackend.pawtopiabackend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "pets")
@Data
public class Pet {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String name;
    
    @Column(nullable = false)
    private String species; // 物种，如狗、猫等
    
    private String breed; // 品种
    
    private String color;
    
    private Integer age;
    
    @Enumerated(EnumType.STRING)
    private Gender gender;
    
    private String size; // 大小
    
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "adoption_status", nullable = false)
    private AdoptionStatus adoptionStatus = AdoptionStatus.AVAILABLE;

    @Column(name = "adoption_city")
    private String adoptionCity;

    @Column(name = "adoption_note")
    private String adoptionNote;
    
    @Column(name = "birth_date")
    private LocalDate birthDate;
    
    @Column(name = "owner_id", nullable = false)
    private Long ownerId; // 所有者ID
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    public enum Gender {
        MALE, FEMALE
    }

    public enum AdoptionStatus {
        AVAILABLE, PAUSED, ADOPTED
    }
}
