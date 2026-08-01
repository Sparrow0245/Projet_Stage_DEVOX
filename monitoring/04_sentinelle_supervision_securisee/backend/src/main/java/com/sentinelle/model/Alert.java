package com.sentinelle.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "events")
public class Alert {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "host_id")
    private Long hostId;

    private String type;
    private String message;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public Alert() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getHostId() { return hostId; }
    public void setHostId(Long hostId) { this.hostId = hostId; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
