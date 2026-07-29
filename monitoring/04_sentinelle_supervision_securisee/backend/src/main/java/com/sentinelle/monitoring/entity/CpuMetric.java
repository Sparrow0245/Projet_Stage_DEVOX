package com.sentinelle.monitoring.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "metrics_cpu")
public class CpuMetric {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Double usagePercent;

    @Column(nullable = false)
    private Double loadAverage1m;

    @Column(nullable = false)
    private LocalDateTime recordedAt;

    public CpuMetric() {}

    public Long getId() { return id; }
    public Double getUsagePercent() { return usagePercent; }
    public void setUsagePercent(Double usagePercent) { this.usagePercent = usagePercent; }
    public Double getLoadAverage1m() { return loadAverage1m; }
    public void setLoadAverage1m(Double loadAverage1m) { this.loadAverage1m = loadAverage1m; }
    public LocalDateTime getRecordedAt() { return recordedAt; }
    public void setRecordedAt(LocalDateTime recordedAt) { this.recordedAt = recordedAt; }
}
