package com.sentinelle.controller;

import com.sentinelle.model.Metric;
import com.sentinelle.repository.MetricsRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/metrics")
@CrossOrigin(origins = "*")
public class MetricsController {

    @Autowired
    private MetricsRepository metricsRepository;

    @GetMapping
    public List<Metric> getAllMetrics() {
        return metricsRepository.findAll();
    }

    @GetMapping("/latest")
    public Metric getLatestMetric() {
        return metricsRepository.findTopByOrderByIdDesc();
    }
}
