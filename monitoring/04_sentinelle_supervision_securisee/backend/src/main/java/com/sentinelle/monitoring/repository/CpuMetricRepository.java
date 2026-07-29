package com.sentinelle.monitoring.repository;

import com.sentinelle.monitoring.entity.CpuMetric;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CpuMetricRepository extends JpaRepository<CpuMetric, Long> {

    @Query(value = "SELECT * FROM metrics_cpu ORDER BY recorded_at DESC LIMIT 50", nativeQuery = true)
    List<CpuMetric> findRecentMetrics();
}
