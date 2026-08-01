package com.sentinelle.repository;

import com.sentinelle.model.Metric;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MetricsRepository extends JpaRepository<Metric, Long> {
    Metric findTopByOrderByIdDesc();
}
