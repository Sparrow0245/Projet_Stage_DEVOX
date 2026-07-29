package com.sentinelle.monitoring.controller;

import com.sentinelle.monitoring.entity.CpuMetric;
import com.sentinelle.monitoring.repository.CpuMetricRepository;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/dashboard")
@CrossOrigin(origins = "*")
public class DashboardController {

    private final CpuMetricRepository cpuMetricRepository;

    public DashboardController(CpuMetricRepository cpuMetricRepository) {
        this.cpuMetricRepository = cpuMetricRepository;
    }

    @GetMapping("/overview")
    public Map<String, Object> getOverview() {
        Map<String, Object> status = new HashMap<>();
        status.put("status", "UP");
        status.put("version", "4.0.0");
        status.put("timestamp", System.currentTimeMillis());
        return status;
    }

    @GetMapping("/cpu")
    public List<CpuMetric> getCpuMetrics() {
        return cpuMetricRepository.findRecentMetrics();
    }
}
